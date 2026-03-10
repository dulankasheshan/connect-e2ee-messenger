import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';

class UserListTile extends StatelessWidget {
  final SearchUserEntity user;
  final VoidCallback onTap;

  const UserListTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    backgroundImage: user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(user.profilePicUrl!)
                        : null,
                    child: user.profilePicUrl == null || user.profilePicUrl!.isEmpty
                        ? Icon(
                      Icons.person_outline,
                      color: colorScheme.onSurfaceVariant,
                      size: 28,
                    )
                        : null,
                  ),
                ),
                if (user.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: colorScheme.primary.withOpacity(0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}