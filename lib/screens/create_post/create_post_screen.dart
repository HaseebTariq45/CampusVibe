import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  String _postType = 'social';
  bool _isLoading = false;
  final _postService = PostService();

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final post = PostModel(
        id: '', // Will be set by Firestore
        authorId: 'TODO', // Get from auth service
        content: _contentController.text,
        type: _postType,
        tags: _tags,
        createdAt: DateTime.now(),
      );

      await _postService.createPost(post);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _createPost,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'social', label: Text('Social')),
                ButtonSegment(value: 'academic', label: Text('Academic')),
              ],
              selected: {_postType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _postType = newSelection.first);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add tags',
                      prefixText: '#',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_tagController.text.isNotEmpty) {
                      setState(() {
                        _tags.add(_tagController.text);
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text('#$tag'),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
