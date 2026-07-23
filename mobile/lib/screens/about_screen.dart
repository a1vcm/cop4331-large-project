import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/footer.dart';

const _teamMembers = [
  (
    name: 'Alvaro Canseco-Martinez',
    role: 'Project Manager, Backend, Mobile',
    description: 'Focused on the backend code alongside making sure the mobile app worked.',
  ),
  (
    name: 'Mariem Touati',
    role: 'Frontend Developer',
    description: 'Focused on the UI/UX, some theming, and ensuring a flawless user flow.',
  ),
  (name: 'Jesus Gonzalez', role: 'Frontend, Backend, Mobile', description: ''),
  (
    name: 'Jaden Harris',
    role: 'Frontend, Database',
    description: 'Designed the database and granted the team access, and floated in on frontend.',
  ),
  (
    name: 'Egor Schevchenko',
    role: 'API, Backend',
    description: 'Developed the necessary API endpoints and middleware for KnightRate to function.',
  ),
  (name: 'Justin Ciar', role: 'Frontend, Mobile', description: ''),
];

String _initials(String name) {
  final parts = name.split(' ').where((p) => p.isNotEmpty).take(2);
  return parts.map((p) => p[0]).join().toUpperCase();
}

/// Mirrors frontend/src/pages/AboutPage.jsx: a full-bleed hero, a black
/// "Why KnightRate" story band, then a 2-column team grid (the mobile
/// breakpoint's fixed column count, since phones always match it).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
      transparent: true,
      floating: true,
      showInfoIcon: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 400,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/about_hero_bg.jpg', fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/ucf_logo.png', width: 64, height: 64),
                        const SizedBox(height: 10),
                        Text(
                          'ABOUT US',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.display.copyWith(
                            color: AppColors.white,
                            fontSize: 34,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Meet the people behind it, and their thought process.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.muted.copyWith(
                              color: AppPalette.goldLight,
                              fontSize: 13,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'WHY KNIGHTRATE',
                    style: AppTextStyles.muted.copyWith(
                      color: AppPalette.gold,
                      fontWeight: AppFontWeights.bold,
                      fontSize: 12,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'FOR STUDENTS, BY STUDENTS',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading.copyWith(color: AppColors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "We got tired of guessing whether a course would wreck our GPA. Scrolling through "
                    "Reddit threads was a chore, and finding real syllabi or study resources was worse "
                    "— so we built the thing we wished we'd had freshman year.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.72), height: 1.7),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Every rating comes from a verified fellow Knight, so you can trust what you're "
                    "reading before you register. No more winging a class off a five-word review from "
                    "three years ago.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.72), height: 1.7),
                  ),
                ],
              ),
            ),
            Container(
              color: ThemeColors.surface(context),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 48),
              child: Column(
                children: [
                  Text(
                    'THE CREW',
                    style: AppTextStyles.muted.copyWith(
                      color: ThemeColors.primaryHover(context),
                      fontWeight: AppFontWeights.bold,
                      fontSize: 12,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('MEET THE TEAM', style: AppTextStyles.heading.copyWith(fontSize: 24)),
                  const SizedBox(height: 28),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [for (final m in _teamMembers) _TeamCard(member: m)],
                  ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final ({String name, String role, String description}) member;

  const _TeamCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.goldLight, AppPalette.gold, AppPalette.goldDark],
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(member.name),
            style: AppTextStyles.heading.copyWith(color: AppPalette.black, fontSize: 21),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          member.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.subheading.copyWith(fontSize: 14),
        ),
        Text(
          member.role,
          textAlign: TextAlign.center,
          style: AppTextStyles.muted.copyWith(color: ThemeColors.primaryHover(context), fontSize: 11),
        ),
        if (member.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            member.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.muted.copyWith(fontSize: 11, height: 1.4),
          ),
        ],
      ],
    );
  }
}
