import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/forum_post_entity.dart';

class ForumPostFormView extends StatefulWidget {
  final ForumPostEntity? initialPost;
  final void Function(String title, String content, String category, String? tags) onSubmit;

  const ForumPostFormView({
    super.key,
    this.initialPost,
    required this.onSubmit,
  });

  @override
  State<ForumPostFormView> createState() => _ForumPostFormViewState();
}

class _ForumPostFormViewState extends State<ForumPostFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late String _selectedCategory;

  final List<Map<String, String>> _categories = [
    {'value': 'video_editing', 'label': '🎬 Video Editing'},
    {'value': 'content_ideas', 'label': '💡 Content Ideas'},
    {'value': 'growth_analytics', 'label': '📈 Growth & Analytics'},
    {'value': 'collaboration', 'label': '🤝 Collaboration'},
    {'value': 'music_audio', 'label': '🎵 Music & Audio'},
    {'value': 'design', 'label': '🎨 Design'},
    {'value': 'technology', 'label': '💻 Technology'},
    {'value': 'monetization', 'label': '💰 Monetization'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialPost?.title ?? '');
    _contentController = TextEditingController(text: widget.initialPost?.content ?? '');
    _tagsController = TextEditingController(text: widget.initialPost?.tags ?? '');
    _selectedCategory = widget.initialPost?.category ?? 'video_editing';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPost != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Community Post' : 'Create Community Post',
                    style: AppTypography.headingSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selector Dropdown
              const Text('Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categories.any((c) => c['value'] == _selectedCategory) ? _selectedCategory : 'video_editing',
                dropdownColor: AppColors.surfaceVariant,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(isDense: true),
                items: _categories
                    .map((c) => DropdownMenuItem<String>(
                          value: c['value'],
                          child: Text(c['label']!),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // Title Input
              const Text('Title / Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'e.g. Best 4K Color Grading presets?'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a post title';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content Body Input
              const Text('Discussion Body', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Describe your idea, project, or question in detail...'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter discussion details';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tags Input
              const Text('Tags (comma separated)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'e.g. premiere, lut, colorgrading'),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: Icon(isEditing ? Icons.save_rounded : Icons.send_rounded),
                label: Text(isEditing ? 'Save Changes' : 'Publish to Creator Community'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit(
                      _titleController.text.trim(),
                      _contentController.text.trim(),
                      _selectedCategory,
                      _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
