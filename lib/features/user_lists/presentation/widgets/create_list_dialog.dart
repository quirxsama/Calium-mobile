import 'package:flutter/material.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';

class CreateListDialog extends StatefulWidget {
  const CreateListDialog({
    required this.onCreate,
    super.key,
  });

  final void Function(String name, String? description, bool isPublic) onCreate;

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPublic = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg)),
      title: Text('Yeni Liste Oluştur', style: AppTypography.headlineMedium.copyWith(fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Liste Adı',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'Örn: 2026 Favorilerim',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Açıklama (İsteğe bağlı)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'Listenizi tanıtan kısa bir not...',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Herkese Açık Liste', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Diğer kullanıcılar listenizi görebilir', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              value: _isPublic,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _isPublic = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              widget.onCreate(name, _descController.text.trim().isEmpty ? null : _descController.text.trim(), _isPublic);
              Navigator.pop(context);
            }
          },
          child: const Text('Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
