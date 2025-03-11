import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _universityController;
  late TextEditingController _departmentController;
  late TextEditingController _yearController;
  late List<String> _interests;
  final _interestController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _universityController = TextEditingController(text: widget.user.university);
    _departmentController = TextEditingController(text: widget.user.department);
    _yearController = TextEditingController(text: widget.user.year.toString());
    _interests = List.from(widget.user.interests);
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      final updatedUser = UserModel(
        uid: widget.user.uid,
        email: widget.user.email,
        name: _nameController.text,
        university: _universityController.text,
        department: _departmentController.text,
        year: int.parse(_yearController.text),
        interests: _interests,
        profileImage: widget.user.profileImage,
        points: widget.user.points,
      );

      // TODO: Implement update profile in AuthService
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProfile,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.user.profileImage),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {
                      // TODO: Implement image upload
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _universityController,
            decoration: const InputDecoration(labelText: 'University'),
          ),
          TextField(
            controller: _departmentController,
            decoration: const InputDecoration(labelText: 'Department'),
          ),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(labelText: 'Year'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _interestController,
                  decoration: const InputDecoration(labelText: 'Add Interest'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_interestController.text.isNotEmpty) {
                    setState(() {
                      _interests.add(_interestController.text);
                      _interestController.clear();
                    });
                  }
                },
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: _interests
                .map((interest) => Chip(
                      label: Text(interest),
                      onDeleted: () {
                        setState(() => _interests.remove(interest));
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    _interestController.dispose();
    super.dispose();
  }
}
