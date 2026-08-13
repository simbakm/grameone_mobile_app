import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://grame-one-back-end.onrender.com';

  // ── License Validation ──────────────────────────────────────────────────
  /// Returns a map with keys: valid (bool), message (String), expiryDate (String?),
  /// gradeIds (List of int) on success.
  static Future<Map<String, dynamic>> validateLicense(String code, String deviceId) async {
    final cleanCode = code.trim().toUpperCase();
    final cleanDevice = deviceId.trim();

    final uri = Uri.parse('$_baseUrl/api/licenses/validate')
        .replace(queryParameters: {'activationCode': cleanCode, 'deviceId': cleanDevice});

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'activationCode': cleanCode, 'deviceId': cleanDevice}),
      ).timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final bool isSuccess = body['valid'] == true;
        return {
          'valid': isSuccess,
          'message': body['message'] ?? (isSuccess ? 'Activated' : 'Invalid activation code.'),
          'expiryDate': body['expiryDate']?.toString(),
          'gradeIds': (body['gradeIds'] as List?)?.map((e) => e as int).toList(),
          'licenseType': body['licenseType']?.toString() ?? 'STANDARD',
        };
      } else {
        return {
          'valid': false,
          'message': body['message'] ?? body['error'] ?? 'Invalid activation code.',
        };
      }
    } catch (e) {
      return {
        'valid': false,
        'message': 'Could not reach server. Check your internet connection.',
      };
    }
  }

  /// Validates multiple activation codes simultaneously via POST /api/licenses/validate-multi
  static Future<Map<String, dynamic>> validateMultiLicenses(List<String> codes, String deviceId) async {
    final cleanCodes = codes.map((c) => c.trim().toUpperCase()).where((c) => c.isNotEmpty).toList();
    final cleanDevice = deviceId.trim();

    final uri = Uri.parse('$_baseUrl/api/licenses/validate-multi');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'activationCodes': cleanCodes,
          'deviceId': cleanDevice,
        }),
      ).timeout(const Duration(seconds: 25));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final bool isSuccess = body['valid'] == true || (body['activatedCount'] != null && (body['activatedCount'] as int) > 0);
        return {
          'valid': isSuccess,
          'message': body['message'] ?? 'Multi-license activation completed.',
          'expiryDate': body['expiryDate']?.toString(),
          'gradeIds': (body['gradeIds'] as List?)?.map((e) => (e as num).toInt()).toList(),
          'licenseType': body['licenseType']?.toString() ?? 'MULTI_GRADE',
        };
      } else {
        return {
          'valid': false,
          'message': body['message'] ?? body['error'] ?? 'Multi-license activation failed.',
        };
      }
    } catch (e) {
      return {
        'valid': false,
        'message': 'Could not reach server. Check internet connection.',
      };
    }
  }

  // ── Grade Package Version Check ─────────────────────────────────────────
  /// Returns a map with: version (String), downloadUrl (String), sizeBytes (int)
  static Future<Map<String, dynamic>?> getLatestGradePackage(int gradeId) async {
    final uri = Uri.parse('$_baseUrl/api/distribution/grades/$gradeId/latest');
    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Backend returns 'packageUrl' or 'downloadUrl' — map to our internal 'downloadUrl'
        final String rawUrl = (body['packageUrl'] ?? body['downloadUrl'] ?? '').toString();
        // If it's a relative path, prepend the base URL
        final String fullUrl = rawUrl.startsWith('http') ? rawUrl : '$_baseUrl$rawUrl';
        return {
          'version': body['version']?.toString() ?? '1.0.0',
          'downloadUrl': fullUrl,
          'sizeBytes': body['packageSizeBytes'] as int? ?? 0,
          'gradeId': gradeId,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Download ZIP with progress ──────────────────────────────────────────
  /// Downloads the zip from [url] and reports progress via [onProgress] (0.0 – 1.0).
  /// Returns raw bytes on success, null on failure.
  static Future<List<int>?> downloadPackage({
    required String url,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send().timeout(const Duration(minutes: 10));

      if (response.statusCode != 200) return null;

      final total = response.contentLength ?? 0;
      int received = 0;
      final bytes = <int>[];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress(received / total);
        } else {
          // Unknown size — pulse
          onProgress((received % 1000000) / 1000000.0);
        }
      }

      onProgress(1.0);
      return bytes;
    } catch (e) {
      return null;
    }
  }
}
