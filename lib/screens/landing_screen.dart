import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/legal_content.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth/login_screen.dart';
import 'auth/oauth_webview_screen.dart';
import 'auth/signup_screen.dart';
import 'static/blog_screen.dart';
import 'static/contact_screen.dart';
import 'static/legal_screen.dart';

/// Pixel-faithful copy of the website's LandingPage.tsx:
/// navbar → hero (badge, heading, Google button, stats, image) →
/// categories grid → how-it-works → features → FAQ (Bengali) → CTA → footer.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<String> _categories = [];
  bool _googleLoading = false;
  String? _googleError;

  static const _features = [
    (Icons.account_balance_wallet, 'Easy Deposits & Withdrawals',
        'bKash, Nagad, Rocket — deposit and withdraw your earnings easily with low fees.'),
    (Icons.shield, 'Secure & Trusted',
        'Every transaction is protected. Admin-verified deposits and withdrawals keep your money safe.'),
    (Icons.trending_up, 'Unlimited Earning Potential',
        'Complete tasks, post jobs, refer friends, and run ads — multiple income streams in one platform.'),
    (Icons.bolt, 'Fast Task Completion',
        'Quick, simple micro-tasks that take minutes. Like, follow, subscribe, watch, and earn.'),
    (Icons.people, 'Growing Community',
        'Join Bangladeshi freelancers earning online from home.'),
    (Icons.bar_chart, 'Detailed Analytics',
        'Track your earnings, task completion rate, and growth with a powerful dashboard.'),
  ];

  static const _steps = [
    ('01', 'Create Your Account',
        'Sign up for free with just your email and username. No verification hassle.'),
    ('02', 'Choose & Complete Tasks',
        'Browse 45+ task categories, pick what you like, complete it, and submit proof.'),
    ('03', 'Get Your Earnings',
        'Withdraw your earnings to bKash, Nagad, or Rocket once you reach the minimum amount.'),
  ];

  static const _faqs = [
    ('WORKER GIG BD কী?',
        'WORKER GIG BD বাংলাদেশের একটি মাইক্রো-টাস্ক ও ফ্রিল্যান্স প্ল্যাটফর্ম, যেখানে আপনি সহজ অনলাইন টাস্ক (ফেসবুক লাইক, সাইন আপ, সার্ভে ইত্যাদি) সম্পন্ন করে ঘরে বসে আয় করতে পারেন।'),
    ('আয় করা টাকা কীভাবে তুলব?',
        'ড্যাশবোর্ড থেকে উইথড্র অপশনে গিয়ে বিকাশ, নগদ বা রকেট অ্যাকাউন্ট দিয়ে ন্যূনতম পরিমাণ পূরণ করে টাকা তুলতে পারেন। \$1 = 100 BDT.'),
    ('সাইন আপ করতে কি টাকা লাগে?',
        'না, সাইন আপ সম্পূর্ণ ফ্রি। শুধু ইমেইল ও ইউজারনেম দিয়ে অ্যাকাউন্ট খুলে কাজ শুরু করতে পারেন।'),
    ('কী কী ধরনের কাজ পাওয়া যায়?',
        'ফেসবুক, টুইটার, ইনস্টাগ্রাম, ইউটিউব/টফি, টিকটক, সাইন আপ, অ্যাডস ক্লিক, সার্ভে, জিমেইল অ্যাকাউন্ট, মোবাইল অ্যাপ, আর্টিকেল, কমেন্ট, লিংকডইন ও রেডিট — ৪৫+ ক্যাটাগরিতে কাজ পাওয়া যায়।'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final client = context.read<AuthService>().client;
      final rows = await client
          .from('categories')
          .select('name')
          .eq('is_active', true)
          .order('display_order');
      if (mounted) {
        setState(() {
          _categories = rows.map((r) => r['name'] as String).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _googleError = null;
      _googleLoading = true;
    });
    // Google sign-in happens INSIDE the app — never the external browser.
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const OAuthWebViewScreen()),
    );
    if (mounted && ok != true) {
      setState(() {
        _googleError = 'Sign-in was not completed.';
        _googleLoading = false;
      });
    } else if (mounted) {
      setState(() => _googleLoading = false);
    }
  }

  void _goLogin() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  void _goSignup() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const SignupScreen()));

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ---- Navbar (pinned, white, logo + Login + Get Started) ----
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            surfaceTintColor: Colors.white,
            elevation: 0.5,
            title: const WGLogo(size: 40),
            actions: [
              TextButton(
                onPressed: _goLogin,
                child: const Text('Login',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900)),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: _goSignup,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Get Started'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(child: _hero()),
          SliverToBoxAdapter(child: _categoriesSection()),
          SliverToBoxAdapter(child: _howItWorks()),
          SliverToBoxAdapter(child: _featuresSection()),
          SliverToBoxAdapter(child: _faqSection()),
          SliverToBoxAdapter(child: _cta()),
          SliverToBoxAdapter(child: _footer()),
        ],
      ),
    );
  }

  // ---- Hero ----
  Widget _hero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x80EEF2FF), Colors.white, Colors.white],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              border: Border.all(color: AppColors.primary100),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary500, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text('Trusted Micro-Task Platform in Bangladesh',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text.rich(
            TextSpan(
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                  color: AppColors.gray900),
              children: [
                TextSpan(text: 'Earn Money Doing '),
                TextSpan(
                    text: 'Simple Tasks',
                    style: TextStyle(color: AppColors.primary600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Like, follow, subscribe, watch videos, complete surveys, and more. '
            'Join Bangladeshis earning online from the comfort of home.',
            style:
                TextStyle(fontSize: 15, height: 1.6, color: AppColors.gray600),
          ),
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _googleLoading ? null : _signUpWithGoogle,
                  icon: _googleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const _GoogleG(size: 20),
                  label: const Text('Sign up with Google',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _goLogin,
                  child: const Text('Already have an account? Log in',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                          decoration: TextDecoration.underline)),
                ),
                if (_googleError != null) ...[
                  const SizedBox(height: 8),
                  Text(_googleError!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.danger600)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat('45+', 'Task Categories'),
              _VDivider(),
              _Stat('bKash', 'Nagad & Rocket'),
              _VDivider(),
              _Stat('Free', 'To Join'),
            ],
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.pexels.com/photos/3183130/pexels-photo-3183130.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(height: 220, color: AppColors.gray100),
              errorWidget: (_, __, ___) =>
                  Container(height: 220, color: AppColors.gray100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.gray600)),
        ],
      );

  Widget _categoriesSection() {
    return Container(
      color: AppColors.gray50,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          _sectionTitle(
              '${_categories.isNotEmpty ? _categories.length : 45}+ Task Categories',
              'Pick from a wide range of micro-tasks across every major platform'),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: _categories
                .map((cat) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.gray200),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 2)
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.primary50,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.check_circle,
                                color: AppColors.primary600, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(cat,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray900)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: _sectionTitle(
                  'How It Works', 'Start earning in three simple steps')),
          const SizedBox(height: 32),
          ..._steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$1,
                        style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary100)),
                    Text(s.$2,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900)),
                    const SizedBox(height: 6),
                    Text(s.$3,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: AppColors.gray600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _featuresSection() {
    return Container(
      color: AppColors.gray50,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          _sectionTitle('Why Choose WORKER GIG BD?',
              'Everything you need to earn money online — in one platform'),
          const SizedBox(height: 32),
          ..._features.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 3)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [
                              AppColors.primary500,
                              AppColors.primary700
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(f.$1, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(f.$2,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900)),
                    const SizedBox(height: 6),
                    Text(f.$3,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: AppColors.gray600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _faqSection() {
    return Container(
      color: AppColors.gray50,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          _sectionTitle('সাধারণ জিজ্ঞাসা',
              'WORKER GIG BD সম্পর্কে যে প্রশ্নগুলো সবচেয়ে বেশি করা হয়'),
          const SizedBox(height: 32),
          ..._faqs.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 2)
                  ],
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(f.$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.gray900)),
                    trailing:
                        const Icon(Icons.add, color: AppColors.primary600),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(f.$2,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: AppColors.gray600)),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _cta() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          const Text('Ready to Start Earning?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900)),
          const SizedBox(height: 12),
          const Text(
            'Join WORKER GIG BD today and turn your free time into income. '
            "It's free to sign up and start working immediately.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.gray600),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _googleLoading ? null : _signUpWithGoogle,
            icon: const _GoogleG(size: 20),
            label: const Text('Sign up with Google',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.gray300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _goLogin,
            child: const Text('Already have an account? Log in',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                    decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 20,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _TrustChip(
                  Icons.check_circle, 'Free to join', Color(0xFF16A34A)),
              _TrustChip(Icons.lock, 'Secure payments', AppColors.primary500),
              _TrustChip(
                  Icons.public, 'Available nationwide', AppColors.primary500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      color: AppColors.gray50,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WGLogo(size: 36),
          const SizedBox(height: 12),
          const Text(
            "Bangladesh's premier micro-task platform. Earn money completing simple online tasks.",
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 24),
          _footerSection('Platform', [
            ('Login', _goLogin),
            ('Get Started', _goSignup),
          ]),
          _footerSection('Support', [
            ('About Us',
                () => _open(const LegalScreen(
                    title: 'About WORKER GIG BD', content: aboutBlocks))),
            ('Contact Us', () => _open(const ContactScreen())),
            ('Blog & Guides', () => _open(const BlogScreen())),
            ('Terms of Service',
                () => _open(const LegalScreen(
                    title: 'Terms of Service', content: termsBlocks))),
            ('Privacy Policy',
                () => _open(const LegalScreen(
                    title: 'প্রাইভেসি পলিসি',
                    content: privacyPolicyBlocks))),
          ]),
          const Text('Contact',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.gray900)),
          const SizedBox(height: 8),
          _footerLink(
              'wasimmostakim2965@gmail.com',
              () => launchUrl(
                  Uri.parse('mailto:wasimmostakim2965@gmail.com'))),
          _footerLink('WhatsApp: +880 1338-882758',
              () => launchUrl(Uri.parse('https://wa.me/8801338882758'))),
          const SizedBox(height: 4),
          const Text('workergigbd.site',
              style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Center(
            child: Text('© 2026 WORKER GIG BD. All rights reserved.',
                style: TextStyle(fontSize: 12, color: AppColors.gray500)),
          ),
        ],
      ),
    );
  }

  Widget _footerSection(String title, List<(String, VoidCallback)> links) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.gray900)),
            const SizedBox(height: 8),
            ...links.map((l) => _footerLink(l.$1, l.$2)),
          ],
        ),
      );

  Widget _footerLink(String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
        ),
      );
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
        ],
      );
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppColors.gray200);
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _TrustChip(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
        ],
      );
}

/// Simple Google "G" mark approximation (4 colored arcs).
class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, -1.57, 1.9, true, paint);
    paint.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, 0.33, 1.05, true, paint);
    paint.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, 1.38, 1.05, true, paint);
    paint.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, 2.43, 1.2, true, paint);
    paint.color = Colors.white;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
