import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/footer.dart';

typedef _Faq = ({String id, String question, String answer});

const _generalFaqs = <_Faq>[
  (
    id: 'q1',
    question: 'What is KnightRate?',
    answer:
        "KnightRate is a course review platform built for UCF Computer Science and IT students. Search "
        "the course catalog, see difficulty and quality ratings from students who've taken a class, and "
        "share your own experience once you have.",
  ),
  (
    id: 'q2',
    question: 'Is KnightRate free to use?',
    answer: 'Yes — browsing courses, reading reviews, and creating an account are all completely free.',
  ),
  (
    id: 'q3',
    question: 'Who can leave a course review?',
    answer:
        "Any registered, verified student can leave a review. You can submit one review per course, and "
        "you can edit or delete it any time from that course's page.",
  ),
  (
    id: 'q4',
    question: 'What are some upcoming features?',
    answer:
        "We're continuing to build out course resources (student-submitted links and study materials) "
        "and bookmarking, along with more ways to sort and filter the course catalog.",
  ),
];

const _accountFaqs = <_Faq>[
  (
    id: 'q5',
    question: 'How do I create an account?',
    answer:
        "Click the account icon and choose Register. After signing up, we'll email you a verification "
        "code — enter it on the next screen to activate your account and log in automatically.",
  ),
  (
    id: 'q6',
    question: 'Are my reviews anonymous?',
    answer:
        'Your reviews are tied to your account for moderation purposes, but your name is never shown '
        'next to a review — other students only see the rating, tags, and comment.',
  ),
  (
    id: 'q7',
    question: 'How do I delete my account?',
    answer:
        'Open your profile page and choose Delete Account. This permanently removes your account along '
        'with your reviews, bookmarks, and submitted resources.',
  ),
  (
    id: 'q8',
    question: 'How do I delete my reviews?',
    answer:
        'Open the course page for the review you want to remove and click Delete on your review. This '
        'can be undone only by writing a new review for that course.',
  ),
];

/// Mirrors frontend/src/pages/FaqPage.jsx: two sections, each a list of
/// accordion items — a single `openId` shared across BOTH sections, so
/// opening one closes whatever else was open, even in the other section.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String? _openId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
      showHelpIcon: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Text(
                'Frequently Asked Questions',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(fontSize: 26),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                children: [
                  _FaqSection(title: 'General', items: _generalFaqs, openId: _openId, onToggle: _toggle),
                  const SizedBox(height: 40),
                  _FaqSection(
                    title: 'Account & Privacy',
                    items: _accountFaqs,
                    openId: _openId,
                    onToggle: _toggle,
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

  void _toggle(String id) => setState(() => _openId = _openId == id ? null : id);
}

class _FaqSection extends StatelessWidget {
  final String title;
  final List<_Faq> items;
  final String? openId;
  final ValueChanged<String> onToggle;

  const _FaqSection({required this.title, required this.items, required this.openId, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: AppPalette.gold, width: 4))),
          child: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 18)),
        ),
        const SizedBox(height: 12),
        for (final item in items) ...[
          _FaqItem(item: item, open: openId == item.id, onToggle: () => onToggle(item.id)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final _Faq item;
  final bool open;
  final VoidCallback onToggle;

  const _FaqItem({required this.item, required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        border: Border(left: BorderSide(color: AppPalette.gold, width: 4)),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Q: ',
                            style: AppTextStyles.body.copyWith(color: AppPalette.gold, fontWeight: AppFontWeights.bold),
                          ),
                          TextSpan(
                            text: item.question,
                            style: AppTextStyles.body.copyWith(fontWeight: AppFontWeights.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 250),
                    turns: open ? 0.125 : 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: open ? AppPalette.goldDark : AppPalette.gold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add, color: AppColors.black, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text(
                item.answer,
                style: AppTextStyles.body.copyWith(color: ThemeColors.textMuted(context), height: 1.6, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
