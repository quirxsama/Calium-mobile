import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/navigation_utils.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/app_content_frame.dart';
import 'package:calium_stream/core/services/app_preferences.dart';
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
  bool _commentsPublic = true;

  String _defaultQuality = AppPreferences.instance.defaultQuality;
  String _defaultAudio = AppPreferences.instance.defaultAudio;
  double _subtitleSize = AppPreferences.instance.subtitleSize.toDouble();
  bool _gestureBrightness = AppPreferences.instance.gestureBrightness;
  bool _gestureVolume = AppPreferences.instance.gestureVolume;
  bool _autoNext = AppPreferences.instance.autoNext;
  bool _autoSkipIntro = AppPreferences.instance.autoSkipIntro;
  bool _autoDownloadNewEpisodes =
      AppPreferences.instance.autoDownloadNewEpisodes;
  bool _isConnectingIntegration = false;

  static const _qualityLabels = {
    '2160p': '2160p (4K)',
    '1440p': '1440p (2K)',
    '1080p': '1080p',
    '720p': '720p',
    '480p': '480p',
    '360p': '360p',
  };

  static const _audioLabels = {
    'original': 'Orijinal (Japonca)',
    'tr': 'Türkçe Dublaj',
    'en': 'İngilizce Dublaj',
  };

  bool _initialized = false;

  Future<void> _handleLinkProvider(String provider) async {
    setState(() => _isConnectingIntegration = true);
    try {
      final ok = await TrackingService.instance.linkProvider(
        provider: provider,
        onOpenUrl: (url) =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${provider.toUpperCase()} hesabı başarıyla bağlandı!',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${provider.toUpperCase()} bağlantısı kurulamadı veya iptal edildi.',
            ),
            backgroundColor: AppColors.accentCrimson,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectingIntegration = false);
    }
  }

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
      _commentsPublic = authState.user.commentsPublic;
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
                onPressed: () => goBackOrHome(context),
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
          const Divider(color: AppColors.border, height: 32),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Yorumlar profilimde görünsün',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Kapatırsanız seri ve bölüm yorumlarınız profilinizde yalnızca size görünür.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: _commentsPublic,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _commentsPublic = val);
              context.read<SettingsBloc>().add(
                UpdateProfileRequested(commentsPublic: val),
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
            children: _qualityLabels.entries.map((entry) {
              final isSel = _defaultQuality == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSel,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: isSel ? Colors.black : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() => _defaultQuality = entry.key);
                  AppPreferences.instance.setDefaultQuality(entry.key);
                },
              );
            }).toList(),
          ),
          const Divider(color: AppColors.border, height: 32),

          Text('Varsayılan Ses Dili', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _audioLabels.entries.map((entry) {
              final isSel = _defaultAudio == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSel,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: isSel ? Colors.black : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() => _defaultAudio = entry.key);
                  AppPreferences.instance.setDefaultAudio(entry.key);
                },
              );
            }).toList(),
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
            min: 30.0,
            max: 64.0,
            divisions: 34,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceElevated,
            label: '${_subtitleSize.toInt()} pt',
            onChanged: (val) => setState(() => _subtitleSize = val),
            onChangeEnd: (val) =>
                AppPreferences.instance.setSubtitleSize(val.round()),
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
            onChanged: (val) {
              setState(() => _gestureBrightness = val);
              AppPreferences.instance.setGestureBrightness(val);
            },
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
            onChanged: (val) {
              setState(() => _gestureVolume = val);
              AppPreferences.instance.setGestureVolume(val);
            },
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
            onChanged: (val) {
              setState(() => _autoNext = val);
              AppPreferences.instance.setAutoNext(val);
            },
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
            onChanged: (val) {
              setState(() => _autoSkipIntro = val);
              AppPreferences.instance.setAutoSkipIntro(val);
            },
          ),
          const Divider(color: AppColors.border, height: 32),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Yeni Bölümleri Otomatik İndir',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Favori animelerinize yeni bölüm eklendiğinde varsayılan kalitede otomatik indirilir.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: _autoDownloadNewEpisodes,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _autoDownloadNewEpisodes = val);
              AppPreferences.instance.setAutoDownloadNewEpisodes(val);
            },
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

    return AnimatedBuilder(
      animation: tracking,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusMd,
                  ),
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
                      onChanged: (val) => tracking.setAutoScrobble(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (tracking.isSyncing || _isConnectingIntegration)
                      ? null
                      : () => tracking.triggerSync(),
                  icon: tracking.isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    tracking.isSyncing
                        ? 'Senkronize Ediliyor...'
                        : 'Tümünü Şimdi Senkronize Et',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (tracking.conflicts.isNotEmpty) ...[
                Text(
                  'Çözülmesi Gereken Çakışmalar (${tracking.conflicts.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.ratingAmber,
                  ),
                ),
                const SizedBox(height: 8),
                ...tracking.conflicts.map((conflict) {
                  final entryId = conflict['entryId']?.toString() ?? '';
                  final provider = conflict['provider']?.toString() ?? '';
                  final version = (conflict['version'] as num?)?.toInt() ?? 0;
                  final fields =
                      (conflict['fields'] as List?)?.join(', ') ?? '';
                  final localEntry = tracking.entries.firstWhere(
                    (e) => e['id'] == entryId,
                    orElse: () => {},
                  );
                  final title =
                      localEntry['title']?.toString() ?? 'Anime ($entryId)';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.ratingAmber.withAlpha(120),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Farklı alanlar: $fields ($provider)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => tracking.resolveConflict(
                                  entryId: entryId,
                                  provider: provider,
                                  version: version,
                                  entryVersion:
                                      (localEntry['version'] as num?)
                                          ?.toInt() ??
                                      1,
                                  choice: 'local',
                                ),
                                child: const Text(
                                  'Calium Değerini Tut',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => tracking.resolveConflict(
                                  entryId: entryId,
                                  provider: provider,
                                  version: version,
                                  entryVersion:
                                      (localEntry['version'] as num?)
                                          ?.toInt() ??
                                      1,
                                  choice: 'remote',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: Text(
                                  '${provider.toUpperCase()} Verisini Al',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
              ],

              _buildProviderCard(
                name: 'AniList',
                badge: 'AL',
                badgeColor: const Color(0xFF02A9FF),
                isConnected: tracking.isAniListConnected,
                username: tracking.aniListUsername,
                status: tracking.aniListStatus,
                lastSyncedAt: tracking.aniListLastSyncedAt,
                onConnect: () => _handleLinkProvider('anilist'),
                onDisconnect: () => tracking.disconnectAniList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              _buildProviderCard(
                name: 'MyAnimeList (MAL)',
                badge: 'MAL',
                badgeColor: const Color(0xFF2E51A2),
                isConnected: tracking.isMalConnected,
                username: tracking.malUsername,
                status: tracking.malStatus,
                lastSyncedAt: tracking.malLastSyncedAt,
                onConnect: () => _handleLinkProvider('mal'),
                onDisconnect: () => tracking.disconnectMal(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderCard({
    required String name,
    required String badge,
    required Color badgeColor,
    required bool isConnected,
    String? username,
    String? status,
    DateTime? lastSyncedAt,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(
          color: isConnected ? badgeColor.withAlpha(120) : AppColors.border,
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
                  color: badgeColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w900,
                      fontSize: badge.length > 2 ? 13 : 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isConnected
                          ? 'Bağlantı Aktif${username != null && username.isNotEmpty ? ' (@$username)' : ''}'
                          : 'Bağlı Değil',
                      style: TextStyle(
                        color: isConnected
                            ? AppColors.successGreen
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected)
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
          const SizedBox(height: 14),
          if (isConnected) ...[
            if (lastSyncedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Son Senkronizasyon: ${lastSyncedAt.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.link_off_rounded,
                  color: AppColors.accentCrimson,
                  size: 18,
                ),
                label: Text(
                  '$name Bağlantısını Kes',
                  style: const TextStyle(color: AppColors.accentCrimson),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.accentCrimson.withAlpha(120),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isConnectingIntegration ? null : onDisconnect,
              ),
            ),
          ] else ...[
            Text(
              'İzleme listenizi ve bölüm geçmişinizi $name ile çift taraflı senkronize edin.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isConnectingIntegration
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  '$name ile Bağlan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: badgeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isConnectingIntegration ? null : onConnect,
              ),
            ),
          ],
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
                        'v1.3.1 • Libmpv Video Engine',
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
}
