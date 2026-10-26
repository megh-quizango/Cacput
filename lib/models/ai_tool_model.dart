import 'package:flutter/material.dart';

class AiToolModel {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String route;

  const AiToolModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.route,
  });
}
