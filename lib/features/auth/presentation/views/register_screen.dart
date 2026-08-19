import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/glass_container.dart';
import 'package:calium_stream/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';
import 'package:calium_stream/features/social/presentation/bloc/social_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              email: _emailController.text.trim(),
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.read<LibraryBloc>().add(LoadLibraryRequested());
            context.read<SocialBloc>().add(LoadSocialDataRequested());
            context.go('/library');
          } else if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.accentCrimson,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Title ─────────────────────────────────────
                      Text(
                        'CALIUM',
                        style: AppTypography.headlineLarge.copyWith(
                          color: AppColors.primary,
                          fontSize: 32,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Yeni Hesap Oluştur',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // ── Register Card ─────────────────────────────
                      GlassContainer(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Kayıt Ol',
                              style: AppTypography.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Username
                            TextFormField(
                              controller: _usernameController,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Kullanıcı Adı',
                                labelStyle: AppTypography.bodyMedium,
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceElevated,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusMd,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Kullanıcı adı gerekli';
                                }
                                if (val.trim().length < 3) {
                                  return 'En az 3 karakter olmalı';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'E-posta',
                                labelStyle: AppTypography.bodyMedium,
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceElevated,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusMd,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'E-posta gerekli';
                                }
                                if (!val.contains('@')) {
                                  return 'Geçerli bir e-posta girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                labelStyle: AppTypography.bodyMedium,
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceElevated,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusMd,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Şifre gerekli';
                                }
                                if (val.length < 6) {
                                  return 'En az 6 karakter olmalı';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePassword,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Şifreyi Onayla',
                                labelStyle: AppTypography.bodyMedium,
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceElevated,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusMd,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val != _passwordController.text) {
                                  return 'Şifreler eşleşmiyor';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Submit Button
                            ElevatedButton(
                              onPressed: isLoading ? null : _onRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusMd,
                                  ),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Kayıt Ol',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Zaten hesabın var mı? ',
                            style: AppTypography.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Giriş Yap',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
