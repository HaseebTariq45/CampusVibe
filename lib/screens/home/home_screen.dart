import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAcademic = true;
  bool _showSocial = true;
  String? _universityFilter;
  List<String>? _tagFilters;
  String? _departmentFilter;
  final PostService _postService = PostService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<PostModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0: // All
            _showAcademic = true;
            _showSocial = true;
            break;
          case 1: // Academic
            _showAcademic = true;
            _showSocial = false;
            break;
          case 2: // Social
            _showAcademic = false;
            _showSocial = true;
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _postService.searchPosts(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching posts: $e')),
      );
    }
  }

  void _toggleUniversityFilter(UserModel user) {
    setState(() {
      if (_universityFilter == null) {
        _universityFilter = user.university;
      } else {
        _universityFilter = null;
      }
    });
  }

  void _toggleDepartmentFilter(UserModel user) {
    setState(() {
      if (_departmentFilter == null) {
        _departmentFilter = user.department;
      } else {
        _departmentFilter = null;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _universityFilter = null;
      _tagFilters = null;
      _departmentFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search posts...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: _performSearch,
              )
            : const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter_university':
                  _toggleUniversityFilter(user);
                  break;
                case 'filter_department':
                  _toggleDepartmentFilter(user);
                  break;
                case 'clear_filters':
                  _clearFilters();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter_university',
                child: Text('Filter by My University'),
              ),
              const PopupMenuItem(
                value: 'filter_department',
                child: Text('Filter by My Department'),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Text('Clear All Filters'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Academic'),
            Tab(text: 'Social'),
          ],
        ),
      ),
      body: _isSearching && _searchResults.isNotEmpty
          ? ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final post = _searchResults[index];
                return PostCard(
                  post: post,
                  isLiked: post.likedBy.contains(user.uid),
                  onTap: () {
                    // Navigate to post detail
                  },
                  onLike: () async {
                    try {
                      if (post.likedBy.contains(user.uid)) {
                        await _postService.unlikePost(post.id, user.uid);
                      } else {
                        await _postService.likePost(post.id, user.uid);
                      }
                    } catch (e) {
                      // Handle error
                    }
                  },
                  onComment: () {
                    // Navigate to comments
                  },
                  onShare: () {
                    // Share post
                  },
                );
              },
            )
          : _isSearching && _searchResults.isEmpty
              ? const Center(
                  child: Text('No results found'),
                )
              : StreamBuilder<List<PostModel>>(
                  stream: _postService.getPostsForFeed(
                    showAcademic: _showAcademic,
                    showSocial: _showSocial,
                    universityFilter: _universityFilter,
                    tagFilters: _tagFilters,
                    departmentFilter: _departmentFilter,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final posts = snapshot.data ?? [];

                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.post_add,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No posts yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to share something!',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to create post
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Post'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        // Refresh posts
                        setState(() {});
                      },
                      child: ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return PostCard(
                            post: post,
                            isLiked: post.likedBy.contains(user.uid),
                            onTap: () {
                              // Navigate to post detail
                            },
                            onLike: () async {
                              try {
                                if (post.likedBy.contains(user.uid)) {
                                  await _postService.unlikePost(post.id, user.uid);
                                } else {
                                  await _postService.likePost(post.id, user.uid);
                                }
                              } catch (e) {
                                // Handle error
                              }
                            },
                            onComment: () {
                              // Navigate to comments
                            },
                            onShare: () {
                              // Share post
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create post screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
