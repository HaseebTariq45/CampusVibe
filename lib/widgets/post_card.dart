import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../constants/app_constants.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final Function()? onTap;
  final Function()? onLike;
  final Function()? onComment;
  final Function()? onShare;
  final bool isLiked;

  const PostCard({
    Key? key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.isLiked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingRegular,
        vertical: AppConstants.paddingSmall,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingRegular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.authorProfileImage.isNotEmpty
                        ? NetworkImage(post.authorProfileImage)
                        : null,
                    child: post.authorProfileImage.isEmpty
                        ? Text(post.authorName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppConstants.fontSizeRegular,
                          ),
                        ),
                        Text(
                          post.authorUniversity,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: post.contentType == AppConstants.contentTypeAcademic
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.contentType == AppConstants.contentTypeAcademic
                          ? 'Academic'
                          : 'Social',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: post.contentType == AppConstants.contentTypeAcademic
                            ? Colors.blue
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Post content
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingRegular),
                child: Text(
                  post.content,
                  style: const TextStyle(fontSize: AppConstants.fontSizeRegular),
                ),
              ),
              
              // Media (if any)
              if (post.mediaUrls.isNotEmpty)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingRegular),
                  child: post.mediaUrls.length == 1
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.mediaUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.mediaUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: AppConstants.paddingSmall),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  post.mediaUrls[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              
              // Tags
              if (post.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.tags.map((tag) {
                    return Chip(
                      label: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      backgroundColor: Theme.of(context).brightness == Brightness.light
                          ? AppConstants.primaryColor.withOpacity(0.1)
                          : AppConstants.primaryColor.withOpacity(0.3),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: AppConstants.paddingSmall),
              
              // Timestamp and course info (for academic posts)
              Row(
                children: [
                  Text(
                    timeago.format(post.createdAt),
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeSmall,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  if (post.contentType == AppConstants.contentTypeAcademic &&
                      post.courseCode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: AppConstants.paddingSmall),
                      child: Text(
                        '• ${post.courseCode}',
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeSmall,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likes}',
                    color: isLiked ? Colors.red : null,
                    onTap: onLike,
                  ),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: '${post.comments}',
                    onTap: onComment,
                  ),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: '${post.shares}',
                    onTap: onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingSmall,
          vertical: 4,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
