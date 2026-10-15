import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  String _selectedRole = 'All';

  final List<String> _roleOptions = ['All', 'user', 'staff', 'admin'];

  void _showRoleChangeDialog(BuildContext context, UserModel user) {
    String currentRole = user.role == 'student' ? 'user' : user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Change User Role'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${user.name} (${user.email})',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                const Text('Select New Role:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...['user', 'staff', 'admin'].map((role) {
                  final label = role == 'staff' ? 'KITCHEN / STAFF' : role.toUpperCase();
                  // ignore: deprecated_member_use
                  return RadioListTile<String>(
                    title: Text(label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: role,
                    // ignore: deprecated_member_use
                    groupValue: currentRole,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => currentRole = val);
                      }
                    },
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _firestoreService.updateUserRole(user.userId, currentRole);
                    if (context.mounted) {
                      SnackbarUtils.showSuccess(
                        context,
                        'Role for ${user.name} updated to $currentRole',
                      );
                      setState(() {});
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarUtils.showError(context, 'Failed to update role: $e');
                    }
                  }
                },
                child: const Text('Save Role', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or phone...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _roleOptions.map((role) {
                    final isSelected = _selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(role.toUpperCase()),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedRole = role);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // User Stream
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firestoreService.getAllUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                var users = snapshot.data ?? [];

                if (_selectedRole != 'All') {
                  if (_selectedRole == 'user') {
                    users = users.where((u) => u.isUser).toList();
                  } else {
                    users = users.where((u) => u.role == _selectedRole).toList();
                  }
                }

                if (_searchQuery.trim().isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  users = users.where((u) {
                    return u.name.toLowerCase().contains(q) ||
                        u.email.toLowerCase().contains(q) ||
                        u.phone.toLowerCase().contains(q) ||
                        u.studentId.toLowerCase().contains(q);
                  }).toList();
                }

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No users match your criteria.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildUserTile(users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    final joinDate = DateFormat('dd MMM yyyy').format(user.createdAt);

    Color roleColor;
    Color roleBg;
    String roleDisplay;
    if (user.isAdmin) {
      roleColor = const Color(0xFF4338CA);
      roleBg = const Color(0xFFEEF2FF);
      roleDisplay = 'ADMIN';
    } else if (user.isKitchen || user.isStaff) {
      roleColor = AppColors.accent;
      roleBg = AppColors.accentSoft;
      roleDisplay = 'KITCHEN';
    } else {
      roleColor = AppColors.primary;
      roleBg = AppColors.primarySoft;
      roleDisplay = 'USER';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleBg,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        roleDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${user.studentId.isNotEmpty ? user.studentId : "N/A"} • Joined: $joinDate',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Change Role',
            icon: const Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
            onPressed: () => _showRoleChangeDialog(context, user),
          ),
        ],
      ),
    );
  }
}
