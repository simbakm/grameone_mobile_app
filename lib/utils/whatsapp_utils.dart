import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppUtils {
  WhatsAppUtils._();

  static const String supportNumber = '263784144050';

  static Future<void> openSupportWhatsApp({
    BuildContext? context,
    String? message,
  }) async {
    final encodedMessage = message != null && message.isNotEmpty
        ? Uri.encodeComponent(message)
        : Uri.encodeComponent('Hello GrameOne Support, I need assistance.');

    final whatsappUri = Uri.parse('whatsapp://send?phone=$supportNumber&text=$encodedMessage');
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

/// Custom painted authentic WhatsApp brand icon widget (speech bubble + phone handset)
class WhatsAppIcon extends StatelessWidget {
  final double size;

  const WhatsAppIcon({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _WhatsAppPainter(),
      ),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Green WhatsApp background circle with speech bubble tail at bottom-left
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path bubblePath = Path();
    final double radius = w * 0.44;
    final Offset center = Offset(w * 0.5, h * 0.46);

    // Draw main circle
    bubblePath.addOval(Rect.fromCircle(center: center, radius: radius));

    // Tail pointing down-left
    final Path tailPath = Path();
    tailPath.moveTo(w * 0.22, h * 0.70);
    tailPath.lineTo(w * 0.12, h * 0.88);
    tailPath.lineTo(w * 0.36, h * 0.82);
    tailPath.close();

    final Path combinedPath = Path.combine(PathOperation.union, bubblePath, tailPath);
    canvas.drawPath(combinedPath, bgPaint);

    // White phone handset inside, rotated
    canvas.save();
    canvas.translate(w * 0.5, h * 0.47);
    canvas.rotate(-math.pi / 12); // subtle tilt

    final Paint phonePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double s = w / 24.0; // scale factor based on 24px base

    final Path phonePath = Path();
    // Curved telephone handset path relative to origin
    phonePath.moveTo(-4 * s, -6 * s);
    phonePath.cubicTo(-5 * s, -6 * s, -6 * s, -5 * s, -6 * s, -3.5 * s);
    phonePath.cubicTo(-6 * s, 2 * s, -2 * s, 6 * s, 3.5 * s, 6 * s);
    phonePath.cubicTo(5 * s, 6 * s, 6 * s, 5 * s, 6 * s, 4 * s);
    phonePath.lineTo(4.5 * s, 2 * s);
    phonePath.cubicTo(4 * s, 1.5 * s, 3 * s, 1.5 * s, 2.5 * s, 2 * s);
    phonePath.lineTo(1 * s, 3.5 * s);
    phonePath.cubicTo(-1.5 * s, 2 * s, -2 * s, -0.5 * s, -3.5 * s, -1 * s);
    phonePath.lineTo(-2 * s, -2.5 * s);
    phonePath.cubicTo(-1.5 * s, -3 * s, -1.5 * s, -4 * s, -2 * s, -4.5 * s);
    phonePath.close();

    canvas.drawPath(phonePath, phonePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
