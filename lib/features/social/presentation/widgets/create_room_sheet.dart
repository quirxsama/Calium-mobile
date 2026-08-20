import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/widgets/glass_container.dart';
import 'package:calium_stream/features/social/presentation/bloc/social_bloc.dart';

class CreateRoomSheet extends StatefulWidget {
  const CreateRoomSheet({
    this.initialAnimeId,
    this.initialAnimeName,
    this.initialEpisodeId,
    this.initialEpisodeName,
    this.initialPoster,
    super.key,
  });

  final String? initialAnimeId;
  final String? initialAnimeName;
  final String? initialEpisodeId;
  final String? initialEpisodeName;
  final String? initialPoster;

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  late final TextEditingController _animeNameController;
  late final TextEditingController _episodeNameController;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animeNameController = TextEditingController(text: widget.initialAnimeName ?? '');
    _episodeNameController = TextEditingController(text: widget.initialEpisodeName ?? 'Bölüm 1');
  }

  @override
  void dispose() {
    _animeNameController.dispose();
    _episodeNameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final animeName = _animeNameController.text.trim();
    final episodeName = _episodeNameController.text.trim();

    if (animeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen anime adı girin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final animeId = widget.initialAnimeId ?? animeName.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final episodeId = widget.initialEpisodeId ?? 'ep-1';

    context.read<SocialBloc>().add(
      CreateRoomRequested(
        animeId: animeId,
        animeName: animeName,
        episodeId: episodeId,
        episodeName: episodeName.isNotEmpty ? episodeName : 'Bölüm 1',
        poster: widget.initialPoster,
        isPublic: _isPublic,
      ),
    );

    // Don't pop here — wait for BlocListener to handle the result
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SocialBloc, SocialState>(
      listener: (context, state) {
        if (state is SocialRoomJoinedState) {
          final room = state.room;

          // Copy room code to clipboard
          Clipboard.setData(ClipboardData(text: room.code));

          // Close the sheet
          Navigator.of(context).pop();

          // Show room code in SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Oda oluşturuldu! Kod: ${room.code} (panoya kopyalandı)'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to the player (like web version)
          context.push(
            '/watch/${room.animeId}?title=${Uri.encodeComponent(room.animeName)}&episode=${Uri.encodeComponent(room.episodeName ?? 'Bölüm 1')}&ep=${room.episodeId ?? '1'}',
          );
        }
        if (state is SocialFailureState) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: AppColors.accentCrimson,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.meeting_room_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Birlikte İzleme Odası Aç',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _animeNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Anime Adı',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'Örn. Solo Leveling',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.movie_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _episodeNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Bölüm Adı / No',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'Örn. Bölüm 1',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Herkese Açık Oda', style: TextStyle(color: Colors.white, fontSize: 15)),
                subtitle: const Text(
                  'Açıksa diğer kullanıcılar odanızı sosyal sekmesinde görebilir',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                activeThumbColor: AppColors.primary,
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text(
                        'Odayı Başlat',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
