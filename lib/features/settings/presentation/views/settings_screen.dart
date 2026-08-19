import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:calium_stream/features/settings/presentation/bloc/settings_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarController = TextEditingController();

  final _curPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _isPrivate = false;

  String _defaultQuality = '1080p';
  String _defaultAudio = 'Orijinal (Japonca)';
  double _subtitleSize = 18.0;
  bool _gestureBrightness = true;
  bool _gestureVolume = true;
  bool _autoNext = true;
  bool _autoSkipIntro = false;

  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _avatarController.dispose();
    _curPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  void _initUserData(AuthState authState) {
    if (_initialized) return;
    if (authState is Authenticated) {
      _nameController.text = authState.user.displayName ?? '';
      _bioController.text = authState.user.bio ?? '';
      _avatarController.text = authState.user.avatarUrl ?? '';
      _previewAvatarUrl = authState.user.avatarUrl ?? '';
      _isPrivate = authState.user.isPrivate;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    _initUserData(authState);

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.successGreen,
            ),
          );
          context.read<AuthBloc>().add(CheckAuthRequested());
        }
        if (state is SettingsFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.accentCrimson,
            ),
          );
        }
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Ayarlar & Profil',
              style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            bottom: const TabBar(
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: 'Profil'),
                Tab(text: 'Gizlilik'),
                Tab(text: 'Oynatıcı'),
                Tab(text: 'Güvenlik'),
              ],
            ),
          ),
          body: authState is! Authenticated
              ? const Center(
                  child: Text(
                    'Lütfen giriş yapın.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : TabBarView(
                  children: [
                    // ─── 1. Profil Sekmesi ─────────────────────────────
                    _buildProfileTab(),

                    // ─── 2. Gizlilik Sekmesi ───────────────────────────
                    _buildPrivacyTab(),

                    // ─── 3. Oynatıcı Tercihleri Sekmesi ────────────────
                    _buildPlayerPreferencesTab(),

                    // ─── 4. Güvenlik & Hesap Sekmesi ───────────────────
                    _buildSecurityTab(),
                  ],
                ),
        ),
      ),
    );
  }

  bool _isUploadingAvatar = false;
  String _previewAvatarUrl = '';



  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _isUploadingAvatar = true);
      try {
        final bytes = await image.readAsBytes();
        final ext = image.name.split('.').last.toLowerCase();
        final mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:$mimeType;base64,$base64String';
        setState(() {
          _previewAvatarUrl = dataUrl;
          _avatarController.text = dataUrl;
        });
      } finally {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar preview
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.surfaceElevated,
                  child: ClipOval(
                    child: _isUploadingAvatar 
                        ? const CircularProgressIndicator(color: AppColors.primary) 
                        : (_previewAvatarUrl.isNotEmpty
                            ? (_previewAvatarUrl.startsWith('data:') 
                                ? Image.memory(base64Decode(_previewAvatarUrl.split(',')[1]), fit: BoxFit.cover, width: 92, height: 92)
                                : AppCachedImage(imageUrl: _previewAvatarUrl, fit: BoxFit.cover, width: 92, height: 92))
                            : const Icon(Icons.person, size: 48, color: AppColors.textSecondary)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Görünen İsim (Display Name)',
              labelStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _bioController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Biyografi',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'Kendinizi tanıtın...',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                context.read<SettingsBloc>().add(
                      UpdateProfileRequested(
                        displayName: _nameController.text.trim(),
                        bio: _bioController.text.trim(),
                        avatarUrl: _avatarController.text.trim(),
                      ),
                    );
              },
              child: const Text('Değişiklikleri Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gizli Hesap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text(
              'Hesabınızı sadece onayladığınız takipçiler görebilir.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: _isPrivate,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _isPrivate = val);
              context.read<SettingsBloc>().add(UpdateProfileRequested(isPrivate: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Varsayılan Video Kalitesi', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['2160p (4K)', '1440p (2K)', '1080p', '720p', '480p', '360p'].map((q) {
              final isSel = _defaultQuality == q;
              return ChoiceChip(
                label: Text(q),
                selected: isSel,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(color: isSel ? Colors.black : AppColors.textSecondary, fontWeight: FontWeight.bold),
                onSelected: (_) => setState(() => _defaultQuality = q),
              );
            }).toList(),
          ),
          const Divider(color: AppColors.border, height: 32),

          Text('Varsayılan Ses Dili', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Orijinal (Japonca)', 'Türkçe Dublaj', 'İngilizce Dublaj'].map((a) {
              final isSel = _defaultAudio == a;
              return ChoiceChip(
                label: Text(a),
                selected: isSel,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(color: isSel ? Colors.black : AppColors.textSecondary, fontWeight: FontWeight.bold),
                onSelected: (_) => setState(() => _defaultAudio = a),
              );
            }).toList(),
          ),
          const Divider(color: AppColors.border, height: 32),

          // Subtitle Size Setting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Altyazı Boyutu', style: AppTypography.titleSmall),
              Text('${_subtitleSize.toInt()} pt', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _subtitleSize,
            min: 12.0,
            max: 32.0,
            divisions: 10,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceElevated,
            label: '${_subtitleSize.toInt()} pt',
            onChanged: (val) => setState(() => _subtitleSize = val),
          ),
          const Divider(color: AppColors.border, height: 32),

          // Gesture Controls
          Text('Dokunmatik Kontroller', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kaydırılabilir Parlaklık', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Ekranın sol tarafını yukarı/aşağı kaydırarak parlaklığı ayarla.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            value: _gestureBrightness,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _gestureBrightness = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kaydırılabilir Ses', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Ekranın sağ tarafını yukarı/aşağı kaydırarak sesi ayarla.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            value: _gestureVolume,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _gestureVolume = val),
          ),
          const Divider(color: AppColors.border, height: 32),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Otomatik Sonraki Bölüm', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Bölüm bittiğinde otomatik sonraki bölüme geçer.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            value: _autoNext,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _autoNext = val),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Otomatik İntro Atlama', style: TextStyle(color: Colors.white)),
            subtitle: const Text('İntro tespit edildiğinde dokunmaya gerek kalmadan atlar.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            value: _autoSkipIntro,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _autoSkipIntro = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Şifre Değiştir', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _curPassController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _newPassController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Yeni Şifre'),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              onPressed: () {
                if (_curPassController.text.isNotEmpty && _newPassController.text.isNotEmpty) {
                  context.read<SettingsBloc>().add(
                        ChangePasswordRequested(
                          currentPassword: _curPassController.text,
                          newPassword: _newPassController.text,
                        ),
                      );
                  _curPassController.clear();
                  _newPassController.clear();
                }
              },
              child: const Text('Şifreyi Güncelle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(color: AppColors.border, height: 48),

          Text('Oturum', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.accentCrimson),
              label: const Text('Çıkış Yap', style: TextStyle(color: AppColors.accentCrimson, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accentCrimson),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}
