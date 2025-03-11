import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/post_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/comment_model.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _scaleAnimation;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;
    setState(() => _isLiking = true);

    try {
      await _likeController.forward();
      HapticFeedback.mediumImpact();
      await _likeController.reverse();
      await context.read<PostService>().likePost(widget.post.id);
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.post.authorId), // TODO: Get author image
                ),
                const SizedBox(width: 8),
                Text(widget.post.authorId), // TODO: Get author name
                const Spacer(),
                Text(timeago.format(widget.post.createdAt)),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.post.content),
            if (widget.post.attachments.isNotEmpty)
              _buildMediaContent(widget.post.attachments),
            if (widget.post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: widget.post.tags
                    .map((tag) => Chip(label: Text('#$tag')))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            _buildInteractionBar(),
            if (widget.post.comments.isNotEmpty)
              _buildComments(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(List<String> attachments) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          if (attachment.endsWith('.mp4')) {
            return VideoPlayerWidget(url: attachment);
          }
          return Hero(
            tag: 'post_image_${widget.post.id}_$index',
            child: GestureDetector(
              onTap: () => _showFullScreenImage(context, attachment),
              child: CachedNetworkImage(
                imageUrl: attachment,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerLoadingEffect(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageView(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Row(
      children: [
        LikeButton(
          post: widget.post,
          onTap: _handleLike,
        ),
        IconButton(
          icon: const Icon(Icons.comment),
          onPressed: () {
            _showCommentDialog(context);
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share post
          },
        ),
      ],
    );
  }

  Widget _buildComments() {
    return StreamBuilder<List<CommentModel>>(
      stream: context.read<PostService>().getPostComments(widget.post.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final comments = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) => _CommentTile(
                comment: comments[index],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCommentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CommentDialog(postId: widget.post.id),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }
}

class ShimmerLoadingEffect extends StatelessWidget {
  const ShimmerLoadingEffect({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(''), // TODO: Get user avatar
      ),
      title: Row(
        children: [
          Text(comment.userId), // TODO: Get user name,
          const SizedBox(width: 8),
          Text(
            timeago.format(comment.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      subtitle: Text(comment.content),
      trailing: IconButton(
        icon: Icon(
          comment.likes.isEmpty ? Icons.favorite_border : Icons.favorite,
          color: comment.likes.isEmpty ? null : Colors.red,
        ),
        onPressed: () {
          // TODO: Implement like comment
        },
      ),
    );
  }
}

class _CommentDialog extends StatefulWidget {
  final String postId;

  const _CommentDialog({required this.postId});

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _addComment() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final comment = CommentModel(
        id: '',
        postId: widget.postId,
        userId: context.read<AppState>().currentUser!.uid,
        content: _controller.text,
        createdAt: DateTime.now(),
      );

      await context.read<PostService>().addComment(comment);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _addComment,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Post Comment'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
