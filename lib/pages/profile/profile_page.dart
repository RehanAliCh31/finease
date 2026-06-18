import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/saving_goal.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../utils/profile_image_utils.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/about_page.dart';
import '../settings/settings_screen.dart';

double _profileDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0;
  return 0;
}

String _profileText(Map<String, dynamic> profile, String key, String fallback) {
  final value = profile[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

double _profileSavingsPercent(dynamic value) {
  final raw = _profileDouble(value);
  if (raw <= 0) return 0;
  return raw <= 1 ? raw * 100 : raw;
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = authService.firestoreService;
    final user = authService.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: AppTheme.primary),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        StreamBuilder<Map<String, dynamic>>(
                          stream: firestoreService?.getUserProfile(),
                          builder: (context, snapshot) {
                            final profile = snapshot.data ?? const {};
                            final image = profileImageProvider(
                              photoUrl:
                                  profile['photoUrl'] as String? ??
                                  user?.photoURL,
                              photoDataUrl: profile['photoDataUrl'] as String?,
                            );
                            return GestureDetector(
                              onTap: () => _showProfilePhotoActions(
                                context,
                                authService,
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                backgroundImage: image,
                                child: image == null
                                    ? Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: AppTheme.primary,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<Map<String, dynamic>>(
                          stream: firestoreService?.getUserProfile(),
                          builder: (context, snapshot) {
                            final profile = snapshot.data ?? const {};
                            final name =
                                profile['fullName'] as String? ??
                                user?.displayName ??
                                user?.email?.split('@').first ??
                                'User';
                            final role = profile['role'] as String? ?? 'user';
                            return Column(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user?.email ?? '',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.74),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    role == 'admin'
                                        ? 'Admin account'
                                        : (profile['isDemoAccount'] == true
                                              ? 'Demo account'
                                              : 'Personal account'),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (firestoreService != null)
                    StreamBuilder<List<SavingGoal>>(
                      stream: firestoreService.getSavingGoals(),
                      builder: (context, snapshot) {
                        final goals = snapshot.data ?? const <SavingGoal>[];
                        final saved = goals.fold<double>(
                          0,
                          (sum, goal) => sum + goal.currentAmount,
                        );
                        return Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Saved',
                                value: CurrencyUtils.format(saved),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Goals',
                                value: '${goals.length}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Fingerprint',
                                value: authService.isBiometricEnabled
                                    ? 'On'
                                    : 'Off',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  if (firestoreService != null) ...[
                    const SizedBox(height: 16),
                    StreamBuilder<Map<String, dynamic>>(
                      stream: firestoreService.getUserProfile(),
                      builder: (context, snapshot) {
                        final profile = snapshot.data ?? const {};
                        return _FinancialProfileCard(
                          profile: profile,
                          onEdit: () => _showFinancialProfileSheet(
                            context,
                            authService,
                            profile,
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: authService.isBiometricEnabled,
                          onChanged: (value) async {
                            if (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sign in again from the login screen to enable fingerprint unlock.',
                                  ),
                                ),
                              );
                            } else {
                              await authService.disableBiometricLogin();
                            }
                          },
                          title: Text(
                            'Fingerprint unlock',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            authService.isBiometricEnabled
                                ? 'Fingerprint quick login is active on this device.'
                                : 'Enable this from login after entering your password.',
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.account_circle_outlined),
                          title: const Text('Profile Picture'),
                          subtitle: const Text(
                            'Choose a photo, take one, or paste an image URL',
                          ),
                          onTap: () =>
                              _showProfilePhotoActions(context, authService),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.settings_outlined),
                          title: const Text('Settings'),
                          subtitle: const Text(
                            'Notifications, security, language, and app preferences',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.info_outline_rounded),
                          title: const Text('About FinEase'),
                          subtitle: const Text(
                            'App overview, features, and developer details',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutPage(),
                            ),
                          ),
                        ),
                        if (authService.isAdmin) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.admin_panel_settings_outlined),
                            title: const Text('Admin Panel'),
                            subtitle: const Text(
                              'Moderation, metrics, and operational controls',
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminDashboardScreen(),
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 1),
                        // ListTile(
                        //   leading: Icon(Icons.shield_outlined),
                        //   title: const Text('Security'),
                        //   subtitle: const Text(
                        //     'Firebase authentication with secure local storage',
                        //   ),
                        // ),
                        const Divider(height: 1),
                        // ListTile(
                        //   leading: Icon(Icons.school_rounded),
                        //   title: const Text('Learning Progress'),
                        //   subtitle: const Text(
                        //     'Course progress and quiz scores sync to your profile',
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Launch readiness',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          authService.isDemoAccount
                              ? 'You are in the presentation account. Create a personal account to store your own transactions, budgets, savings goals, forum activity, and quiz progress in Firebase.'
                              : 'Your account stores transactions, budgets, savings goals, literacy progress, and community activity directly in Firebase.',
                          style: GoogleFonts.inter(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => authService.signOut(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                      ),
                      child: Text(
                        'Log Out',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinancialProfileSheet(
    BuildContext context,
    AuthService authService,
    Map<String, dynamic> profile,
  ) async {
    final nameController = TextEditingController(
      text: _profileText(
        profile,
        'fullName',
        authService.user?.displayName ?? '',
      ),
    );
    final incomeController = TextEditingController(
      text: _profileDouble(profile['monthlyIncome']) > 0
          ? _profileDouble(profile['monthlyIncome']).toStringAsFixed(0)
          : '',
    );
    final savingsController = TextEditingController(
      text: _profileSavingsPercent(profile['targetSavingsRate']) > 0
          ? _profileSavingsPercent(
              profile['targetSavingsRate'],
            ).toStringAsFixed(0)
          : '',
    );
    final countryController = TextEditingController(
      text: _profileText(profile, 'country', 'Pakistan'),
    );
    final languageController = TextEditingController(
      text: _profileText(profile, 'language', 'English (Pakistan)'),
    );

    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (modalContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.viewInsetsOf(modalContext).bottom + 20,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These details improve budgets, forecasts, welfare matching, and loan affordability checks.',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProfileEditField(
                    controller: nameController,
                    label: 'Full name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  _ProfileEditField(
                    controller: incomeController,
                    label: 'Monthly income',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileEditField(
                    controller: savingsController,
                    label: 'Savings target (%)',
                    icon: Icons.savings_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileEditField(
                    controller: countryController,
                    label: 'Country',
                    icon: Icons.public_rounded,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  _ProfileEditField(
                    controller: languageController,
                    label: 'Language',
                    icon: Icons.language_rounded,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              final income =
                                  double.tryParse(
                                    incomeController.text.trim().replaceAll(
                                      ',',
                                      '',
                                    ),
                                  ) ??
                                  0;
                              final savingsPercent =
                                  double.tryParse(
                                    savingsController.text.trim().replaceAll(
                                      ',',
                                      '',
                                    ),
                                  ) ??
                                  0;
                              try {
                                await authService.firestoreService
                                    ?.saveUserProfile({
                                      'fullName': nameController.text.trim(),
                                      'monthlyIncome': income.clamp(
                                        0,
                                        double.infinity,
                                      ),
                                      'targetSavingsRate':
                                          savingsPercent.clamp(0, 100) / 100,
                                      'country': countryController.text.trim(),
                                      'language': languageController.text
                                          .trim(),
                                    });
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                _showSavingSnack(
                                  context,
                                  'Financial profile updated.',
                                );
                              } catch (error) {
                                setSheetState(() => saving = false);
                                if (!sheetContext.mounted) return;
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not update profile: $error',
                                    ),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              }
                            },
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(saving ? 'Saving...' : 'Save profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    incomeController.dispose();
    savingsController.dispose();
    countryController.dispose();
    languageController.dispose();
  }

  Future<void> _showProfilePhotoActions(
    BuildContext context,
    AuthService authService,
  ) async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profile Picture',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _PhotoActionTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                subtitle: 'Upload an existing image',
                onTap: () => Navigator.pop(sheetContext, _PhotoAction.gallery),
              ),
              _PhotoActionTile(
                icon: Icons.photo_camera_outlined,
                title: 'Take Photo',
                subtitle: 'Use your camera',
                onTap: () => Navigator.pop(sheetContext, _PhotoAction.camera),
              ),
              _PhotoActionTile(
                icon: Icons.link_rounded,
                title: 'Use Image URL',
                subtitle: 'Paste a public image link',
                onTap: () => Navigator.pop(sheetContext, _PhotoAction.url),
              ),
              if ((authService.user?.photoURL ?? '').isNotEmpty)
                _PhotoActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Photo',
                  subtitle: 'Return to the default avatar',
                  isDestructive: true,
                  onTap: () => Navigator.pop(sheetContext, _PhotoAction.remove),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _PhotoAction.gallery:
        await _pickAndUploadPhoto(context, authService, ImageSource.gallery);
      case _PhotoAction.camera:
        await _pickAndUploadPhoto(context, authService, ImageSource.camera);
      case _PhotoAction.url:
        _showProfilePhotoUrlDialog(context, authService);
      case _PhotoAction.remove:
        await _saveProfilePhotoUrl(context, authService, '');
    }
  }

  Future<void> _pickAndUploadPhoto(
    BuildContext context,
    AuthService authService,
    ImageSource source,
  ) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 68,
        maxWidth: 360,
      );
      if (picked == null) return;
      if (!context.mounted) return;
      _showSavingSnack(context, 'Uploading profile picture...');
      final bytes = await picked.readAsBytes();
      await authService.updateProfilePhotoBytes(
        bytes: bytes,
        fileName: picked.name,
        contentType: picked.mimeType,
      );
      if (!context.mounted) return;
      _showSavingSnack(context, 'Profile picture updated.');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update photo: $error'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<bool> _saveProfilePhotoUrl(
    BuildContext context,
    AuthService authService,
    String photoUrl,
  ) async {
    try {
      await authService.updateProfilePhotoUrl(photoUrl);
      if (!context.mounted) return true;
      _showSavingSnack(
        context,
        photoUrl.isEmpty
            ? 'Profile picture removed.'
            : 'Profile picture updated.',
      );
      return true;
    } catch (error) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update photo: $error'),
          backgroundColor: AppTheme.error,
        ),
      );
      return false;
    }
  }

  void _showSavingSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showProfilePhotoUrlDialog(
    BuildContext context,
    AuthService authService,
  ) {
    final controller = TextEditingController(
      text: authService.user?.photoURL ?? '',
    );
    final formKey = GlobalKey<FormState>();
    var saving = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Profile Picture',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://example.com/photo.jpg',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final uri = Uri.tryParse(text);
                if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                  return 'Enter a valid image URL';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      try {
                        final saved = await _saveProfilePhotoUrl(
                          dialogContext,
                          authService,
                          controller.text.trim(),
                        );
                        if (saved && dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        } else {
                          setDialogState(() => saving = false);
                        }
                      } catch (error) {
                        setDialogState(() => saving = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Could not update photo: $error'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoAction { gallery, camera, url, remove }

class _PhotoActionTile extends StatelessWidget {
  const _PhotoActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDestructive
                ? AppTheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDestructive ? AppTheme.error : Colors.grey[400],
        ),
      ),
    );
  }
}

class _FinancialProfileCard extends StatelessWidget {
  const _FinancialProfileCard({required this.profile, required this.onEdit});

  final Map<String, dynamic> profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final income = _profileDouble(profile['monthlyIncome']);
    final savingsTarget = _profileSavingsPercent(profile['targetSavingsRate']);
    final country = _profileText(profile, 'country', 'Pakistan');
    final language = _profileText(profile, 'language', 'English (Pakistan)');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.manage_accounts_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Used by budgets, forecast, welfare, loans, and coach.',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 360;
              final width = wide
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FinancePill(
                    width: width,
                    label: 'Monthly income',
                    value: income > 0 ? CurrencyUtils.format(income) : 'Add',
                    icon: Icons.payments_rounded,
                  ),
                  _FinancePill(
                    width: width,
                    label: 'Savings target',
                    value: savingsTarget > 0
                        ? '${savingsTarget.toStringAsFixed(0)}%'
                        : 'Set',
                    icon: Icons.savings_rounded,
                  ),
                  _FinancePill(
                    width: width,
                    label: 'Country',
                    value: country,
                    icon: Icons.public_rounded,
                  ),
                  _FinancePill(
                    width: width,
                    label: 'Language',
                    value: language,
                    icon: Icons.language_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Update financial profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancePill extends StatelessWidget {
  const _FinancePill({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditField extends StatelessWidget {
  const _ProfileEditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
