import 'package:flutter/material.dart';

import '../../theme.dart';

/// Mirrors ContactUsPage.tsx — WhatsApp + email cards and a message form
/// that opens WhatsApp with the text pre-filled.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const _whatsapp = '8801338882758';
  static const _email = 'wasimmostakim2965@gmail.com';

  @override
  Widget build(BuildContext context) {
    final name = TextEditingController();
    final message = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Get in Touch', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            'Questions about your account, deposits, withdrawals or tasks? '
            'Reach us anytime — we usually reply within a few hours.',
            style: TextStyle(color: AppColors.gray600, height: 1.5),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE7F9EE),
                child: Icon(Icons.chat, color: Color(0xFF25D366)),
              ),
              title: const Text('WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('+880 1338-882758'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () =>
                  safeLaunch('https://wa.me/$_whatsapp'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary50,
                child: Icon(Icons.mail, color: AppColors.primary600),
              ),
              title: const Text('Email',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(_email),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => safeLaunch('mailto:$_email'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send a Message',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: 'Your name')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: message,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Message', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send via WhatsApp'),
                      onPressed: () {
                        final text = Uri.encodeComponent(
                            'Hi, I am ${name.text.trim()}. ${message.text.trim()}');
                        safeLaunch('https://wa.me/$_whatsapp?text=$text');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
