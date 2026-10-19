// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void launchTelUrl(String phoneNumber) {
  try {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final anchor = html.AnchorElement(href: 'tel:$cleanPhone')
      ..target = '_self';
    anchor.click();
  } catch (e) {
    // Graceful fallback
  }
}
