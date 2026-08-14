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
        : Uri.encodeComponent('Hello GrameOne Support, I need assistance.');

    // Primary: Direct WhatsApp deep-link scheme (works for both WhatsApp & WhatsApp Business)
    final whatsappUri = Uri.parse('whatsapp://send?phone=$supportNumber&text=$encodedMessage');

    // Fallback: Web wa.me link
    final webUri = Uri.parse('https://wa.me/$supportNumber?text=$encodedMessage');

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

/// Reusable crisp WhatsApp branded icon widget
class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const WhatsAppIcon({
    super.key,
    this.size = 24,
    this.backgroundColor = const Color(0xFF25D366),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(70),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.chat,
          color: iconColor,
          size: size * 0.58,
        ),
      ),
    );
  }
}
