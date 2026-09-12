import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.divider.withAlpha(80), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: navigationShell.currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: Icons.explore_rounded,
                label: 'Discover',
                isSelected: navigationShell.currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _CreateNavItem(
                onTap: () => _onTap(2),
              ),
              _NavItem(
                icon: Icons.forum_rounded,
                label: 'Forum',
                isSelected: navigationShell.currentIndex == 3,
                onTap: () => _onTap(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: navigationShell.currentIndex == 4,
                onTap: () => _onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateNavItem extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateNavItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(120),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}
