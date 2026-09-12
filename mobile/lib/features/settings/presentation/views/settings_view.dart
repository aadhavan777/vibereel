import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notifications = true;
  bool _autoPlay = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Preferences')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Account Settings', style: AppTypography.caption),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          const Divider(color: AppColors.divider),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('App Preferences', style: AppTypography.caption),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
            title: const Text('Push Notifications'),
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
            activeThumbColor: AppColors.primary,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.play_circle_outline, color: AppColors.accent),
            title: const Text('Autoplay Videos on Mobile Data'),
            value: _autoPlay,
            onChanged: (val) => setState(() => _autoPlay = val),
            activeThumbColor: AppColors.primary,
          ),
          const Divider(color: AppColors.divider),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Support & Legal', style: AppTypography.caption),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.textSecondary),
            title: const Text('Help Center & FAQs'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: AppColors.textSecondary),
            title: const Text('Privacy Policy & Terms'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              onPressed: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }
}
