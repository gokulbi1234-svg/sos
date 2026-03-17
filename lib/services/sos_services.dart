import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SosService {

  static Future<void> triggerSOS(
      BuildContext context,
      List<String> emergencyContacts
      ) async {

    if (emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No emergency contacts added")),
      );
      return;
    }

    LocationPermission permission =
        await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition();

    String mapLink =
        "https://www.google.com/maps?q=${pos.latitude},${pos.longitude}";

    String msg =
        "🚨 SOS! I need help!\nLocation: $mapLink";

    for (String number in emergencyContacts) {

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: number,
        queryParameters: {'body': msg},
      );

      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );
    }

    await makePhoneCall(emergencyContacts.first);
  }

  static Future<void> makePhoneCall(String phone) async {
    final Uri callUri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }
}