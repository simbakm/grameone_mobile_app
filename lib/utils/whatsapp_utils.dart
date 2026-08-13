import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppUtils {
  WhatsAppUtils._();

  // Support WhatsApp number for GrameOne
  static const String supportNumber = '263784144050';

  static Future<void> openSupportWhatsApp({
    BuildContext? context,
    String? message,
  }) async {
    final encodedMessage = message != null && message.isNotEmpty
        ? Uri.encodeComponent(message)
        : '';

    // Primary: Direct WhatsApp deep-link scheme (works for both WhatsApp & WhatsApp Business)
    final whatsappUri = Uri.parse('whatsapp://send?phone=$supportNumber${encodedMessage.isNotEmpty ? "&text=$encodedMessage" : ""}');
    
    // Fallback: Web wa.me link
    final webUri = Uri.parse('https://wa.me/$supportNumber${encodedMessage.isNotEmpty ? "?text=$encodedMessage" : ""}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalNonBrowserApplication);
        return;
      }

      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Final attempt: launch directly without pre-checking canLaunchUrl
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (!launched && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Please ensure WhatsApp or WhatsApp Business is installed.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      // Fallback try webUri
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp. Please check if WhatsApp is installed.'),
            ),
          );
        }
      }
    }
  }
}
