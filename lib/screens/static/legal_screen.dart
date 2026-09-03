import 'package:flutter/material.dart';

import '../../data/legal_content.dart';
import '../../theme.dart';

/// Renders the same Privacy Policy / Terms / About content as the website.
class LegalScreen extends StatelessWidget {
  final String title;
  final List<LegalBlock> content;
  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 16))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900)),
          const SizedBox(height: 16),
          ...content.map((b) {
            switch (b.type) {
              case 'h2':
                return Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: Text(b.text,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900)),
                );
              case 'ul':
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: b.items
                        .map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('•  ',
                                      style: TextStyle(
                                          color: AppColors.primary600,
                                          fontWeight: FontWeight.w700)),
                                  Expanded(
                                    child: Text(i,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            color: AppColors.gray600)),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                );
              default:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(b.text,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: AppColors.gray600)),
                );
            }
          }),
        ],
      ),
    );
  }
}
