import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة اتصل بنا — كل شي محلي بهاي الشاشة
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const Color navy = Color(0xFF14213D);
  static const Color gold = Color(0xFFE3B23C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DFD5);
  static const Color textSecondary = Color(0xFF6B6B67);

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12.5, color: textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text('اتصل بنا', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('إلنا أي استفسار أو ملاحظة، فريقنا جاهز يساعدك',
              style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 22),
          _contactCard(
            icon: Icons.call_outlined,
            title: 'اتصل فينا',
            subtitle: '+972 59 9071301',
            color: navy,
            onTap: () => _launch('tel:+972599071301'),
          ),
          _contactCard(
            icon: Icons.chat_outlined,
            title: 'واتساب',
            subtitle: 'راسلنا مباشرة على واتساب',
            color: const Color(0xFF2FA557),
            onTap: () => _launch('https://wa.me/972599071301'),
          ),
          _contactCard(
            icon: Icons.mail_outline_rounded,
            title: 'البريد الإلكتروني',
            subtitle: 'Eshtreeli@gmail.com',
            color: const Color(0xFF2D6CDF),
            onTap: () => _launch('mailto:Eshtreeli@gmail.com'),
          ),
          _contactCard(
            icon: Icons.location_on_outlined,
            title: 'موقعنا',
            subtitle: 'نابلس، فلسطين',
            color: gold,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text('تابعنا',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: () => _launch('https://instagram.com'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: navy, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _launch(
                    'https://www.facebook.com/profile.php?id=61591741247711'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: const Icon(Icons.facebook_outlined,
                      color: navy, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _launch('https://tiktok.com'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: const Icon(Icons.play_circle_outline_rounded,
                      color: navy, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
