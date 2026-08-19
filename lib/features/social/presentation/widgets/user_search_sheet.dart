import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/social/data/datasources/social_remote_datasource.dart';

class UserSearchSheet extends StatefulWidget {
  const UserSearchSheet({super.key});

  @override
  State<UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<UserSearchSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<SearchedUserEntity> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLoading = true);
      try {
        final users = await GetIt.I<SocialRemoteDataSource>().searchUsers(query.trim());
        if (mounted) {
          setState(() {
            _results = users;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _toggleFollow(SearchedUserEntity user, int index) async {
    try {
      final newStatus = await GetIt.I<SocialRemoteDataSource>().toggleFollow(user.username);
      if (mounted) {
        setState(() {
          _results[index] = SearchedUserEntity(
            id: user.id,
            username: user.username,
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
            isPrivate: user.isPrivate,
            followStatus: newStatus,
          );
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Kullanıcı Ara & Takip Et',
            style: AppTypography.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.md),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Kullanıcı adı veya isim yazın...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.length < 2
                              ? 'Aramak için en az 2 harf yazın'
                              : 'Kullanıcı bulunamadı',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (context, index) {
                          final u = _results[index];
                          final isFollowing = u.followStatus == 'following' || u.followStatus == 'friends';
                          final isPending = u.followStatus == 'pending';

                          return ListTile(
                            onTap: () {
                              Navigator.of(context).pop();
                              context.push('/profile/${u.username}');
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.surfaceElevated,
                              child: ClipOval(
                                child: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                                    ? AppCachedImage(imageUrl: u.avatarUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.person, color: AppColors.textSecondary),
                              ),
                            ),
                            title: Text(
                              u.displayName ?? u.username,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('@${u.username}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? AppColors.surfaceElevated
                                    : (isPending ? Colors.amber.withAlpha(50) : AppColors.primary),
                                foregroundColor: isFollowing ? AppColors.textSecondary : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: isFollowing ? const BorderSide(color: AppColors.border) : BorderSide.none,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                              onPressed: () => _toggleFollow(u, index),
                              child: Text(
                                isFollowing
                                    ? 'Takip Ediliyor'
                                    : (isPending ? 'İstek Gönderildi' : 'Takip Et'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
