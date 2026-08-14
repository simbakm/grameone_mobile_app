import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConnectivityUtils {
  ConnectivityUtils._();

  /// Checks whether device has active internet access.
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Displays standard offline requirement dialog requested by user:
  /// "this action require you to be online so connect to a wifi or turn on mobile data and try again"
  static void showOfflineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.wifi_off_rounded, color: AppColors.incorrectRed, size: 28),
            SizedBox(width: 10),
            Text(
              'Connection Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'This action requires you to be online so connect to a wifi or turn on mobile data and try again.',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimaryLight, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
