import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Added
import 'package:otakunexa/widgets/method/clear_app.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final ScrollController _scrollController = ScrollController();

  // FAQ Data (Same as original)
  final faqs = <Map<String, String>>[
    {
      'q': 'Videos not loading?',
      'a':
          '1) Check internet connection.\n2) Try switching servers (if available).\n3) Clear app cache from Settings > Storage.\n4) Restart the app.',
    },
    // ... (rest of your FAQs logic remains same)
    {
      'q': 'Some animes aren’t showing up for me',
      'a': '''It’s not you, it’s geography.
Some titles are available only in certain regions.
Trying a VPN can help you peek into other regions where the content is visible.''',
    },
  ];

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  // ✅ Helper function to encode spaces as %20 instead of +
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  Future<void> sendSupportMail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@otakunexa.com',
      // ⚡ FIX: Use 'query' instead of 'queryParameters' with our helper function
      query: encodeQueryParameters({
        'subject': 'OtakuNexa Support',
        'body': '''
Hello OtakuNexa Team,

I need help with the app.

Device:
Android Version:
App Version:

Thanks,
''',
      }),
    );

    if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open mail app';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgBlack = Color(0xFF050505);
    const Color primaryPurple = Color(0xFF7B2CBF);
    const Color deepPurple = Color(0xFF240046);

    return Scaffold(
      backgroundColor: bgBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: bgBlack.withOpacity(0.5)),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20.sp, // Responsive
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help Center',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 20.sp, // Responsive
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.4),
              blurRadius: 20.r,
              spreadRadius: 2.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showContactSheet(context),
          label: Text(
            'Contact Support',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15.sp, // Responsive
            ),
          ),
          icon: Icon(
            Icons.headset_mic_rounded,
            color: Colors.white,
            size: 24.sp,
          ),
          backgroundColor: primaryPurple,
          elevation: 0,
        ),
      ),
      body: Stack(
        children: [
          // 1. Background Ambient Glows
          Positioned(
            top: -100.h,
            right: -100.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: deepPurple.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: deepPurple,
                    blurRadius: 100.r,
                    spreadRadius: 50.r,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100.h,
            left: -50.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryPurple.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.2),
                    blurRadius: 120.r,
                    spreadRadius: 20.r,
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
              children: [
                _HeaderSection(),
                SizedBox(height: 24.h),

                _SectionHeader(
                  title: 'Quick Actions',
                  icon: Icons.bolt_rounded,
                ),
                SizedBox(height: 16.h),
                _QuickActionsRow(
                  onContactTap: () => _showContactSheet(context),
                ),

                SizedBox(height: 32.h),
                _SectionHeader(title: 'FAQs', icon: Icons.quiz_rounded),
                SizedBox(height: 16.h),
                ...faqs.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _FaqTile(q: item['q']!, a: item['a']!),
                  ),
                ),

                SizedBox(height: 32.h),
                _SectionHeader(
                  title: 'Troubleshooting',
                  icon: Icons.build_rounded,
                ),
                SizedBox(height: 16.h),
                const _TroubleshootingCard(),

                SizedBox(height: 32.h),
                _SectionHeader(
                  title: 'Report Issue',
                  icon: Icons.bug_report_rounded,
                ),
                SizedBox(height: 16.h),
                const _InfoCard(
                  icon: Icons.bug_report_outlined,
                  title: 'Bug Reporting Guide',
                  body:
                      '• App version & Device model\n• Steps to reproduce\n• Screenshots/Recording\n• Time & Region',
                  color: Color(0xFFC77DFF),
                ),

                SizedBox(height: 32.h),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.code_rounded,
                          color: Colors.white38,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'OtaKuNexa v1.0.0',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: const Color(0xFF100B1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              border: Border(
                top: BorderSide(color: const Color(0xFF7B2CBF), width: 1.w),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 24.h),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Text(
                  'Get in Touch',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We typically reply within 24 years',
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                ),
                SizedBox(height: 32.h),
                _ContactOption(
                  icon: Icons.email_rounded,
                  title: 'Email Support',
                  subtitle: 'otakunexa.anime@gmail.com',
                  color: const Color(0xFFE0AAFF),
                  onTap: () {
                    sendSupportMail();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email copied to clipboard'),
                        backgroundColor: Color(0xFF7B2CBF),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.h),
                _ContactOption(
                  icon: Icons.telegram,
                  title: 'Telegram Community',
                  subtitle: '@OtaKuNexaSupport',
                  color: const Color(0xFF0088CC),
                  onTap: () {
                    _launchURL("https://t.me/OtakuNexa");
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening Telegram...'),
                        backgroundColor: Color(0xFF0088CC),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.h),
                _ContactOption(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Terms & Conditions',
                  color: Colors.grey,
                  onTap: () => Navigator.pop(ctx),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------
//               WIDGETS (RESPONSIVE)
// ------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9D4EDD), size: 20.sp),
        SizedBox(width: 10.w),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3C096C), Color(0xFF10002B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C096C).withOpacity(0.3),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 32.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Find answers or contact us below.',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onContactTap;
  const _QuickActionsRow({required this.onContactTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GlassActionButton(
            icon: Icons.mail_outline_rounded,
            label: 'Contact',
            color: const Color(0xFFE0AAFF),
            onTap: onContactTap,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _GlassActionButton(
            icon: Icons.system_update_alt_rounded,
            label: 'Updates',
            color: const Color(0xFFC77DFF),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App is up to date')),
              );
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _GlassActionButton(
            icon: Icons.delete_sweep_outlined,
            label: 'Cache',
            color: const Color(0xFF9D4EDD),
            onTap: () async {
              await AppSettingsHelper.openAppInfo();
            },
          ),
        ),
      ],
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Colors.white54,
          iconColor: const Color(0xFF9D4EDD),
          title: Text(
            q,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
            ),
          ),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          children: [
            Text(
              a,
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TroubleshootingCard extends StatelessWidget {
  const _TroubleshootingCard();

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Make sure your internet is alive (≥2 Mbps).',
      'Turn off Battery Saver/Data Saver.',
      'Clear the app cache from Settings.',
      'If content is hiding, try using a VPN.',
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF240046).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.3)),
      ),
      child: Column(
        children: steps
            .map(
              (step) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: const Color(0xFF9D4EDD),
                      size: 18.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white60,
                    height: 1.5,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
