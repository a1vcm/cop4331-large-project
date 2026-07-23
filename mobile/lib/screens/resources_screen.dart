import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course.dart';
import '../models/resource.dart';
import '../services/api_client.dart';
import '../services/auth_state.dart';
import '../services/course_service.dart';
import '../services/resource_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

/// Mirrors frontend/src/pages/ResourcesPage.jsx: a course-scoped list of
/// student-submitted links (syllabi, video series, practice sites), an
/// add-resource form for logged-in users, delete on your own submissions.
class ResourcesScreen extends StatefulWidget {
  final String courseId;

  const ResourcesScreen({super.key, required this.courseId});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  Course? _course;
  List<Resource> _resources = [];
  bool _loading = true;
  String? _error;

  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CourseService.getCourseById(widget.courseId),
        ResourceService.getForCourse(widget.courseId),
      ]);
      if (!mounted) return;
      setState(() {
        _course = results[0] as Course;
        _resources = results[1] as List<Resource>;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    setState(() => _formError = null);
    if (title.isEmpty || url.isEmpty) {
      setState(() => _formError = 'Title and link are required');
      return;
    }
    setState(() => _saving = true);
    try {
      await ResourceService.create(courseId: widget.courseId, title: title, url: url);
      _titleController.clear();
      _urlController.clear();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Resource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this resource?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ResourceService.delete(resource.id);
      if (!mounted) return;
      setState(() => _resources = _resources.where((r) => r.id != resource.id).toList());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isLoggedIn = AuthState.instance.isLoggedIn;
    final currentUserId = AuthState.instance.userId;

    return AppScaffold(
      showBack: true,
      onBack: () => context.pop(),
      showInfoIcon: false,
      showHelpIcon: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.body))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                    children: [
                      Text(
                        'Resources${_course != null ? ' — ${_course!.courseCode}' : ''}',
                        style: AppTextStyles.heading.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Links other students have found useful for this course — syllabi, video '
                        'series, practice sites.',
                        style: AppTextStyles.muted,
                      ),
                      const SizedBox(height: 16),
                      if (isLoggedIn)
                        _ResourceForm(
                          titleController: _titleController,
                          urlController: _urlController,
                          error: _formError,
                          saving: _saving,
                          onSubmit: _submit,
                        )
                      else
                        Text('Log in to add a resource.', style: AppTextStyles.muted),
                      const SizedBox(height: 20),
                      if (_resources.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No resources yet — be the first to add one!',
                            style: AppTextStyles.muted,
                          ),
                        ),
                      for (final resource in _resources)
                        _ResourceCard(
                          resource: resource,
                          isMine: currentUserId != null && resource.userId == currentUserId,
                          onOpen: () => _openLink(resource.url),
                          onDelete: () => _delete(resource),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _ResourceForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController urlController;
  final String? error;
  final bool saving;
  final VoidCallback onSubmit;

  const _ResourceForm({
    required this.titleController,
    required this.urlController,
    required this.error,
    required this.saving,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            maxLength: 120,
            decoration: const InputDecoration(hintText: 'Title, e.g. Course YouTube playlist'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://…'),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error!, style: AppTextStyles.muted.copyWith(color: ThemeColors.error(context))),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: saving ? null : onSubmit,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Add Resource'),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final bool isMine;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ResourceCard({
    required this.resource,
    required this.isMine,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.centerLeft,
              child: Text(
                resource.title,
                style: AppTextStyles.subheading.copyWith(
                  color: ThemeColors.primary(context),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('added by ${resource.authorUsername ?? 'a student'}', style: AppTextStyles.muted),
              if (isMine)
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                  child: Text('Delete', style: TextStyle(color: ThemeColors.error(context))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
