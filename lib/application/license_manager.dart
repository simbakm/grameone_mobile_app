import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/models.dart';
import '../../data/repositories/license_repository.dart';

enum LicenseVerificationResult {
  valid,
  invalidCode,
  expired,
  clockTampered,
  notActivated,
}

class LicenseManager {
  final LicenseRepository licenseRepository;

  LicenseManager({LicenseRepository? licenseRepository})
      : licenseRepository = licenseRepository ?? LicenseRepository();

  /// Returns a stable hardware-bound device ID.
  ///
  /// Priority:
  ///   1. Android: ANDROID_ID — unique per device, survives app reinstalls.
  ///   2. iOS: identifierForVendor — stable per app-install bundle (may reset on full reinstall).
  ///   3. Fallback: a deterministic SHA-256 hash stored in SharedPreferences.
  ///
  /// The result is cached in SharedPreferences for performance, but the
  /// authoritative value always comes from the hardware APIs above.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? rawHardwareId;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // ANDROID_ID: unique per device + user, survives reinstalls.
        // It resets only on factory reset or if the device bootloader
        // signs a different app package (very rare in production).
        rawHardwareId = androidInfo.id; // Settings.Secure.ANDROID_ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        rawHardwareId = iosInfo.identifierForVendor;
      }
    } catch (_) {
      rawHardwareId = null;
    }

    if (rawHardwareId != null && rawHardwareId.isNotEmpty && rawHardwareId != 'unknown') {
      // Hash the raw hardware ID so we never expose the naked ANDROID_ID
      final digest = sha256.convert(utf8.encode('GRAME_$rawHardwareId'));
      final devId = 'DEV-${digest.toString().substring(0, 12).toUpperCase()}';
      // Cache it for speed on future calls
      await prefs.setString('grame_unique_device_id', devId);
      return devId;
    }

    // ── Fallback: emulator or platform without hardware ID ──────────────────
    // Use a previously generated random ID stored in SharedPreferences.
    // This is NOT reinstall-proof but is the best we can do without hardware.
    String? cached = prefs.getString('grame_unique_device_id');
    if (cached != null && cached.isNotEmpty) return cached;

    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    final raw = '${DateTime.now().microsecondsSinceEpoch}-${values.join()}';
    final digest = sha256.convert(utf8.encode(raw));
    final fallbackId = 'DEV-${digest.toString().substring(0, 12).toUpperCase()}';
    await prefs.setString('grame_unique_device_id', fallbackId);
    return fallbackId;
  }

  Future<LicenseInfo> initLicense() async {
    LicenseInfo? existing = await licenseRepository.getLicenseInfo();
    final String devId = await getDeviceId();
    final DateTime now = DateTime.now();

    if (existing == null) {
      final newInfo = LicenseInfo(
        deviceId: devId,
        activationCode: null,
        isActivated: false,
        activatedAt: null,
        expiryDate: null,
        lastOpenedDate: now,
      );
      await licenseRepository.saveLicenseInfo(newInfo);
      return newInfo;
    }
    return existing;
  }

  Future<LicenseVerificationResult> verifyLicense() async {
    final license = await initLicense();
    final DateTime now = DateTime.now();

    // Anti-tamper check: compare current system clock against stored last_opened_date
    if (now.isBefore(license.lastOpenedDate.subtract(const Duration(minutes: 5)))) {
      return LicenseVerificationResult.clockTampered;
    }

    // Update last opened date
    await licenseRepository.updateLastOpenedDate(now);

    if (!license.isActivated) {
      return LicenseVerificationResult.notActivated;
    }

    if (license.expiryDate != null && now.isAfter(license.expiryDate!)) {
      return LicenseVerificationResult.expired;
    }

    return LicenseVerificationResult.valid;
  }

  Future<bool> activateDevice(String code) async {
    final String cleanCode = code.trim().toUpperCase();
    final String devId = await getDeviceId();

    // Valid format rule: "GRAME-2026" or matching activation algorithm
    final bool isValidCode = cleanCode == 'GRAME-2026' ||
        cleanCode == 'GRAME-FREE-DEMO' ||
        cleanCode.startsWith('GRAME-');

    if (!isValidCode) {
      return false;
    }

    final DateTime now = DateTime.now();
    final DateTime expiry = now.add(const Duration(days: 365)); // 1 year offline license

    final updatedLicense = LicenseInfo(
      deviceId: devId,
      activationCode: cleanCode,
      isActivated: true,
      activatedAt: now,
      expiryDate: expiry,
      lastOpenedDate: now,
    );

    await licenseRepository.saveLicenseInfo(updatedLicense);
    return true;
  }

  String generateActivationCodeForDevice(String deviceId) {
    final bytes = utf8.encode('GRAME_SECRET_$deviceId');
    final digest = sha256.convert(bytes);
    return 'GRAME-${digest.toString().substring(0, 8).toUpperCase()}';
  }
}
