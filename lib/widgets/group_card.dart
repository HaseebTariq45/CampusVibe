import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../constants/app_constants.dart';

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final Function()? onTap;
  final Function()? onJoin;
  final bool isMember;

  const GroupCard({
    Key? key,
    required this.group,
    this.onTap,
    this.onJoin,
    this.isMember = false,
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
              // Group image and info
              Row(
                children: [
                  // Group image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      image: group.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(group.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: group.imageUrl.isEmpty
                        ? Center(
                            child: Text(
                              group.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppConstants.paddingRegular),
                  // Group details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppConstants.fontSizeMedium,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (group.isPrivate)
                              const Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.grey,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.university,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Group type badge
                            _buildTypeBadge(group.groupType),
                            const SizedBox(width: 8),
                            // Member count
                            Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${group.memberCount}',
                                  style: const TextStyle(
                                    fontSize: AppConstants.fontSizeSmall,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Group description
              if (group.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppConstants.paddingRegular,
                    bottom: AppConstants.paddingSmall,
                  ),
                  child: Text(
                    group.description,
                    style: const TextStyle(fontSize: AppConstants.fontSizeRegular),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // Tags
              if (group.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: group.tags.map((tag) {
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
                ),
              
              // Join button
              if (onJoin != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppConstants.paddingSmall),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isMember ? null : onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMember ? Colors.grey : AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(isMember ? 'Joined' : 'Join Group'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String groupType) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (groupType) {
      case 'course':
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        label = 'Course';
        break;
      case 'faculty':
        backgroundColor = Colors.purple.withOpacity(0.2);
        textColor = Colors.purple;
        label = 'Faculty';
        break;
      case 'interest':
      default:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        label = 'Interest';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
