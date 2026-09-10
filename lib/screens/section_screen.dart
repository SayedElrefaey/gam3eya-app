import 'package:flutter/material.dart';
import '../models/models.dart';
import 'gam3eyas_tab.dart';
import 'individuals_tab.dart';

class SectionScreen extends StatelessWidget {
  final Section section;
  const SectionScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cover,
        foregroundColor: Colors.white,
        title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: section.type == 'gam3eya'
          ? Gam3eyasTab(section: section)
          : IndividualsTab(section: section),
    );
  }
}
