import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/app_content_frame.dart';
import 'package:calium_stream/core/services/tracking_service.dart';
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

    return AppContentFrame(
      maxWidth: 960,
      child: BlocListener<SettingsBloc, SettingsState>(
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
          length: 6,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              title: Text(
                'Ayarlar & Profil',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
                  Tab(text: 'Bağlantılar (AniList & MAL)'),
                  Tab(text: 'Güvenlik'),
                  Tab(text: 'Hakkında & Geliştirici'),
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

                      // ─── 4. AniList & MAL Bağlantıları ─────────────────
                      _buildIntegrationsTab(),

                      // ─── 5. Güvenlik & Hesap Sekmesi ───────────────────
                      _buildSecurityTab(),

                      // ─── 6. Hakkında & Geliştirici Sekmesi ─────────────
                      _buildAboutAndDeveloperTab(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  bool _isUploadingAvatar = false;
  String _previewAvatarUrl = '';

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
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
                        ? const CircularProgressIndicator(
                            color: AppColors.primary,
                          )
                        : (_previewAvatarUrl.isNotEmpty
                              ? (_previewAvatarUrl.startsWith('data:')
                                    ? Image.memory(
                                        base64Decode(
                                          _previewAvatarUrl.split(',')[1],
                                        ),
                                        fit: BoxFit.cover,
                                        width: 92,
                                        height: 92,
                                      )
                                    : AppCachedImage(
                                        imageUrl: _previewAvatarUrl,
                                        fit: BoxFit.cover,
                                        width: 92,
                                        height: 92,
                                      ))
                              : const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                )),
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
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
              child: const Text(
                'Değişiklikleri Kaydet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            title: const Text(
              'Gizli Hesap',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Hesabınızı sadece onayladığınız takipçiler görebilir.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: _isPrivate,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _isPrivate = val);
              context.read<SettingsBloc>().add(
                UpdateProfileRequested(isPrivate: val),
              );
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
            children:
                [
                  '2160p (4K)',
                  '1440p (2K)',
                  '1080p',
                  '720p',
                  '480p',
                  '360p',
                ].map((q) {
                  final isSel = _defaultQuality == q;
                  return ChoiceChip(
                    label: Text(q),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
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
            children:
                ['Orijinal (Japonca)', 'Türkçe Dublaj', 'İngilizce Dublaj'].map(
                  (a) {
                    final isSel = _defaultAudio == a;
                    return ChoiceChip(
                      label: Text(a),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _defaultAudio = a),
                    );
                  },
                ).toList(),
          ),
          const Divider(color: AppColors.border, height: 32),

          // Subtitle Size Setting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Altyazı Boyutu', style: AppTypography.titleSmall),
              Text(
                '${_subtitleSize.toInt()} pt',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            title: const Text(
              'Kaydırılabilir Parlaklık',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Ekranın sol tarafını yukarı/aşağı kaydırarak parlaklığı ayarla.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: _gestureBrightness,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _gestureBrightness = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Kaydırılabilir Ses',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Ekranın sağ tarafını yukarı/aşağı kaydırarak sesi ayarla.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: _gestureVolume,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _gestureVolume = val),
          ),
          const Divider(color: AppColors.border, height: 32),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Otomatik Sonraki Bölüm',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Bölüm bittiğinde otomatik sonraki bölüme geçer.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: _autoNext,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _autoNext = val),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Otomatik İntro Atlama',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'İntro tespit edildiğinde dokunmaya gerek kalmadan atlar.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
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
                if (_curPassController.text.isNotEmpty &&
                    _newPassController.text.isNotEmpty) {
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
              child: const Text(
                'Şifreyi Güncelle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 48),

          Text('Oturum', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.accentCrimson,
              ),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(
                  color: AppColors.accentCrimson,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accentCrimson),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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

  Widget _buildIntegrationsTab() {
    final tracking = TrackingService.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global Auto Scrobble Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Otomatik Bölüm Senkronizasyonu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bir bölümün en az %85\'i izlendiğinde bağlı hesaplarınızdaki izleme geçmişi otomatik güncellenir.',
                        style: TextStyle(
                          color: AppColors.textSecondary.withAlpha(200),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: tracking.autoScrobble,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      tracking.setAutoScrobble(val);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── 1. AniList Integration Card ──────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(
                color: tracking.isAniListConnected
                    ? const Color(0xFF02A9FF).withAlpha(120)
                    : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF02A9FF).withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'AL',
                          style: TextStyle(
                            color: Color(0xFF02A9FF),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AniList',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            tracking.isAniListConnected
                                ? 'Bağlantı Aktif'
                                : 'Bağlı Değil',
                            style: TextStyle(
                              color: tracking.isAniListConnected
                                  ? AppColors.successGreen
                                  : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tracking.isAniListConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.successGreen,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Bağlandı',
                              style: TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (tracking.isAniListConnected) ...[
                  if (tracking.aniListUser != null) ...[
                    Row(
                      children: [
                        if (tracking.aniListUser!['avatar']?['medium'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              tracking.aniListUser!['avatar']['medium'],
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          '@${tracking.aniListUser!['name'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.link_off_rounded,
                        color: AppColors.accentCrimson,
                        size: 18,
                      ),
                      label: const Text(
                        'AniList Bağlantısını Kes',
                        style: TextStyle(color: AppColors.accentCrimson),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.accentCrimson.withAlpha(120),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await tracking.disconnectAniList();
                        setState(() {});
                      },
                    ),
                  ),
                ] else ...[
                  const Text(
                    'İzlediğiniz bölümleri, puanlarınızı ve anime durumunuzu AniList profilinizle anlık senkronize edin.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'AniList Token ile Bağlan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02A9FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showTokenInputDialog(
                        title: 'AniList Bağlantısı',
                        hintText: 'AniList OAuth Personal Token yapıştırın...',
                        infoUrl: 'https://anilist.co/api/v2/oauth/authorize?client_id=19349&response_type=token',
                        infoUrlLabel: 'AniList Token Al (Web Sayfası Aç)',
                        onConnect: (token) async {
                          final ok = await tracking.connectAniList(token);
                          if (ok && mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'AniList hesabı başarıyla bağlandı!',
                                ),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'AniList bağlantısı başarısız. Lütfen tokenı kontrol edin.',
                                ),
                                backgroundColor: AppColors.accentCrimson,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── 2. MyAnimeList (MAL) Integration Card ─────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(
                color: tracking.isMalConnected
                    ? const Color(0xFF2E51A2).withAlpha(120)
                    : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E51A2).withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'MAL',
                          style: TextStyle(
                            color: Color(0xFF2E51A2),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MyAnimeList (MAL)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            tracking.isMalConnected
                                ? 'Bağlantı Aktif'
                                : 'Bağlı Değil',
                            style: TextStyle(
                              color: tracking.isMalConnected
                                  ? AppColors.successGreen
                                  : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tracking.isMalConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.successGreen,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Bağlandı',
                              style: TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (tracking.isMalConnected) ...[
                  if (tracking.malUser != null) ...[
                    Row(
                      children: [
                        if (tracking.malUser!['picture'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              tracking.malUser!['picture'],
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          '@${tracking.malUser!['name'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.link_off_rounded,
                        color: AppColors.accentCrimson,
                        size: 18,
                      ),
                      label: const Text(
                        'MyAnimeList Bağlantısını Kes',
                        style: TextStyle(color: AppColors.accentCrimson),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.accentCrimson.withAlpha(120),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await tracking.disconnectMal();
                        setState(() {});
                      },
                    ),
                  ),
                ] else ...[
                  const Text(
                    'İzleme listenizi MyAnimeList hesabınızla otomatik olarak güncel tutun.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'MAL Token ile Bağlan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E51A2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showTokenInputDialog(
                        title: 'MyAnimeList Bağlantısı',
                        hintText: 'MAL Access Token veya URL yapıştırın...',
                        infoUrl: 'https://myanimelist.net/apiconfig/references/authorization_code',
                        infoUrlLabel: 'MAL API Yetkilendirme Sayfası (Web Aç)',
                        onConnect: (token) async {
                          final ok = await tracking.connectMal(token);
                          if (ok && mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'MyAnimeList hesabı başarıyla bağlandı!',
                                ),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'MAL bağlantısı başarısız. Lütfen tokenı kontrol edin.',
                                ),
                                backgroundColor: AppColors.accentCrimson,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bağlantı açılamadı: $url'),
              backgroundColor: AppColors.accentCrimson,
            ),
          );
        }
      }
    }
  }

  String _extractTokenFromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('access_token=')) {
      final match = RegExp(r'access_token=([a-zA-Z0-9_\.\-]+)')
          .firstMatch(trimmed);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }
    return trimmed;
  }

  Widget _buildAboutAndDeveloperTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(40),
                  AppColors.surfaceElevated,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(
                color: AppColors.primary.withAlpha(70),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(120),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calium Mobile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'v1.1.2 (Beta) • Libmpv Video Engine',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Hardware Acceleration: Active (Vulkan/OpenGL ES)',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Developer & Community Links
          Text(
            'Geliştirici & Topluluk Bağlantıları',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          _buildLinkTile(
            icon: Icons.language_rounded,
            title: 'Resmi Web Sitesi',
            subtitle: 'calium.fun',
            url: 'https://calium.fun',
          ),
          const SizedBox(height: 10),

          _buildLinkTile(
            icon: Icons.code_rounded,
            title: 'GitHub Kaynak Kodu & Geliştirici',
            subtitle: 'github.com/calium-app',
            url: 'https://github.com/calium-app',
          ),
          const SizedBox(height: 10),

          _buildLinkTile(
            icon: Icons.discord_rounded,
            title: 'Discord Topluluğu',
            subtitle: 'discord.gg/calium',
            url: 'https://discord.gg/calium',
          ),
          const SizedBox(height: 10),

          _buildLinkTile(
            icon: Icons.api_rounded,
            title: 'Anizium Video API',
            subtitle: 'anizium.com',
            url: 'https://anizium.com',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Open Source Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Calium açık kaynaklı ve topluluk destekli bir anime streaming projesidir.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.open_in_new_rounded,
          color: Colors.white60,
          size: 18,
        ),
        onTap: () => _openExternalUrl(url),
      ),
    );
  }

  void _showTokenInputDialog({
    required String title,
    required String hintText,
    String? infoUrl,
    String? infoUrlLabel,
    required Future<void> Function(String token) onConnect,
  }) {
    final controller = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (infoUrl != null) ...[
                GestureDetector(
                  onTap: () => _openExternalUrl(infoUrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF02A9FF).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: Color(0xFF02A9FF),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            infoUrlLabel ?? 'Yetkilendirme Sayfasını Aç (URL)',
                            style: const TextStyle(
                              color: Color(0xFF02A9FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      '$hintText\n(Tam URL veya token yapıştırabilirsiniz)',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final rawInput = controller.text.trim();
                      if (rawInput.isEmpty) return;
                      final token = _extractTokenFromInput(rawInput);
                      if (token.isEmpty) return;
                      setDialogState(() => isSubmitting = true);
                      await onConnect(token);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Bağla',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
