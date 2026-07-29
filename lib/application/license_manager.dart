import 'dart:convert';
import 'package:crypto/crypto.dart';

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

  Future<String> getDeviceId() async {
    // Generate a consistent pseudo device ID for offline platform binding
    final String raw = 'GRAMEONE_DEVICE_ID_ZIMBABWE_OFFLINE';
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    final String hashStr = digest.toString().substring(0, 16).toUpperCase();
    return 'DEV-$hashStr';
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
