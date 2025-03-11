import 'package:flutter/material.dart';
import '../../services/search_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/group_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchService = SearchService();
  late TabController _tabController;
  String _currentQuery = '';
  Map<String, dynamic>? _searchResults;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentQuery = _searchController.text;
    });

    try {
      final results = await _searchService.searchAll(
        _currentQuery,
        'TODO', // Get university from AppState
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _performSearch,
            ),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Posts'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList(),
                _buildPostsList(),
                _buildGroupsList(),
              ],
            ),
    );
  }

  Widget _buildUsersList() {
    final users = (_searchResults?['users'] as List<UserModel>?) ?? [];
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(user.profileImage),
          ),
          title: Text(user.name),
          subtitle: Text('${user.university} - ${user.department}'),
          trailing: Text('Year ${user.year}'),
          onTap: () {
            // TODO: Navigate to user profile
          },
        );
      },
    );
  }

  Widget _buildPostsList() {
    final posts = (_searchResults?['posts'] as List<PostModel>?) ?? [];
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(post: post);
      },
    );
  }

  Widget _buildGroupsList() {
    final groups = (_searchResults?['groups'] as List<GroupModel>?) ?? [];
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Card(
          child: ListTile(
            title: Text(group.name),
            subtitle: Text(group.description),
            trailing: Chip(
              label: Text(group.type.toUpperCase()),
            ),
            onTap: () {
              // TODO: Navigate to group details
            },
          ),
        );
      },
    );
  }
}
