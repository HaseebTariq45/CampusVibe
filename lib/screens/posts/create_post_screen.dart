import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final PostService _postService = PostService();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _contentType = AppConstants.contentTypeAcademic;
  List<String> _tags = [];
  List<File> _mediaFiles = [];
  String _courseCode = '';
  String _department = '';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _mediaFiles.add(File(image.path));
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter some content for your post';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        setState(() {
          _errorMessage = 'You must be logged in to create a post';
          _isLoading = false;
        });
        return;
      }

      await _postService.createPost(
        authorId: user.uid,
        content: content,
        contentType: _contentType,
        tags: _tags,
        mediaFiles: _mediaFiles.isNotEmpty ? _mediaFiles : null,
        courseCode: _courseCode,
        department: _department,
        author: user,
      );

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully')),
      );
      
      // Go back to previous screen
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating post: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                margin: const EdgeInsets.only(bottom: AppConstants.paddingRegular),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: AppConstants.fontSizeRegular,
                  ),
                ),
              ),

            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user.profileImageUrl.isNotEmpty
                      ? NetworkImage(user.profileImageUrl)
                      : null,
                  child: user.profileImageUrl.isEmpty
                      ? Text(user.fullName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppConstants.fontSizeRegular,
                        ),
                      ),
                      Text(
                        user.university,
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingRegular),

            // Content type toggle
            Row(
              children: [
                const Text(
                  'Post Type:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppConstants.fontSizeRegular,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingRegular),
                ChoiceChip(
                  label: const Text('Academic'),
                  selected: _contentType == AppConstants.contentTypeAcademic,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _contentType = AppConstants.contentTypeAcademic;
                      });
                    }
                  },
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                ChoiceChip(
                  label: const Text('Social'),
                  selected: _contentType == AppConstants.contentTypeSocial,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _contentType = AppConstants.contentTypeSocial;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingRegular),

            // Course code and department (for academic posts)
            if (_contentType == AppConstants.contentTypeAcademic)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Course Code (optional)',
                      hintText: 'e.g., CS101',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _courseCode = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingRegular),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Department (optional)',
                      hintText: 'e.g., Computer Science',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _department = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingRegular),
                ],
              ),

            // Content field
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: InputBorder.none,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: AppConstants.paddingRegular),

            // Media preview
            if (_mediaFiles.isNotEmpty)
              Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: AppConstants.paddingRegular),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(right: AppConstants.paddingSmall),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_mediaFiles[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeMedia(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Tags
            if (_tags.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: AppConstants.paddingRegular),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag),
                    );
                  }).toList(),
                ),
              ),

            // Add tag field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add a tag',
                      prefixIcon: Icon(Icons.tag),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingSmall,
                        vertical: 0,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: _pickImage,
              tooltip: 'Add Image',
            ),
            IconButton(
              icon: const Icon(Icons.tag),
              onPressed: () {
                FocusScope.of(context).requestFocus(
                  FocusNode(),
                );
                Future.delayed(const Duration(milliseconds: 100), () {
                  FocusScope.of(context).requestFocus(
                    _tagController.text.isEmpty
                        ? FocusNode()
                        : _tagController.buildTextSpan(
                            context: context,
                            withComposing: true,
                            style: const TextStyle(),
                          ).toPlainText().isNotEmpty
                            ? FocusNode()
                            : FocusNode(),
                  );
                });
              },
              tooltip: 'Add Tag',
            ),
          ],
        ),
      ),
    );
  }
}
