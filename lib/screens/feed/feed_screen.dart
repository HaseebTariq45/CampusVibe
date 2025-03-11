import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_state.dart';
import '../../services/post_service.dart';
import 'widgets/feed_filter.dart';
import 'widgets/post_card.dart';
import '../../models/post_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  String _selectedFilter = 'all';
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    // Implement pagination logic
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().currentUser;
    final postService = PostService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusVibe'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Posts'),
            Tab(text: 'My University'),
          ],
        ),
        actions: [
          FeedFilter(
            currentFilter: _selectedFilter,
            onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPostList(postService.getFeedPosts()),
            _buildPostList(postService.getUniversityPosts(currentUser?.university ?? '')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-post'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostList(Stream<List<PostModel>> postsStream) {
    return StreamBuilder<List<PostModel>>(
      stream: postsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];
        
        return ListView.builder(
          controller: _scrollController,
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}
