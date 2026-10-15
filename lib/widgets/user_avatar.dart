import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 42,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final photo = user?.profilePhoto.trim() ?? '';
    final name = user?.name.trim() ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    Widget avatarContent;

    if (photo.isNotEmpty) {
      if (photo.startsWith('data:image')) {
        // Base64 Data URL
        try {
          final base64String = photo.split(',').last;
          final bytes = base64Decode(base64String);
          avatarContent = Image.memory(
            bytes,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(initial),
          );
        } catch (_) {
          avatarContent = _buildDefaultAvatar(initial);
        }
      } else {
        // HTTP / Cloud URL
        avatarContent = Image.network(
          photo,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(initial),
        );
      }
    } else {
      avatarContent = _buildDefaultAvatar(initial);
    }

    Widget avatarWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2.5,
        ),
      ),
      child: ClipOval(
        child: avatarContent,
      ),
    );

    if (showEditBadge) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildDefaultAvatar(String initial) {
    return Container(
      color: AppColors.primarySoft,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
