import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _groupType = 'course';
  bool _isLoading = false;
  final _groupService = GroupService();
  final _authService = AuthService();

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return;

      final group = GroupModel(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        type: _groupType,
        creatorId: currentUser.uid,
        members: [currentUser.uid],
        moderators: [currentUser.uid],
        createdAt: DateTime.now(),
        university: currentUser.university,
      );

      await _groupService.createGroup(group);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
              validator: (value) => 
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) => 
                  value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _groupType,
              decoration: const InputDecoration(labelText: 'Group Type'),
              items: const [
                DropdownMenuItem(value: 'course', child: Text('Course')),
                DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                DropdownMenuItem(value: 'interest', child: Text('Interest')),
              ],
              onChanged: (value) => setState(() => _groupType = value!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createGroup,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
