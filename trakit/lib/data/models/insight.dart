import 'package:flutter/material.dart';

enum InsightTone { warning, celebrate, info, action }

class Insight {
  final String id;
  final String title;
  final String body;
  final InsightTone tone;
  final IconData icon;
  final String? deltaText; // e.g. "+42%"
  final bool deltaUp;

  const Insight({
    required this.id,
    required this.title,
    required this.body,
    required this.tone,
    required this.icon,
    this.deltaText,
    this.deltaUp = false,
  });
}
