import 'package:ffpmupt/screens/offering_screen.dart';
import 'package:flutter/material.dart';

class PublicOfferingScreen extends StatelessWidget {
  const PublicOfferingScreen({super.key, required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return OfferingScreen(countryCode: countryCode);
  }
}
