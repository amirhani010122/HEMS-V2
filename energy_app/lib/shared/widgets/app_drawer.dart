import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/profile/logic/profile_provider.dart';
import '../../features/auth/logic/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/skeleton_loader.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Drawer(
      backgroundColor: AppTheme.darkSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Padding(
              padding: const EdgeInsets.all(20),
              child: userAsync.when(
                loading: () => Row(
                  children: [
                    const SkeletonBox(width: 48, height: 48, borderRadius: 999),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(height: 18),
                          SizedBox(height: 4),
                          SkeletonBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
                error: (e, _) => const SizedBox.shrink(),
                data: (user) => Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.username,
                              style: AppTextStyles.h4,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(user.email,
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: AppTheme.darkBorder),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/dashboard');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.memory_outlined,
                    label: 'Devices',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/devices');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Consumption',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/consumption');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Alerts',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/alerts');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bolt_outlined,
                    label: 'Plans',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/plans');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.auto_awesome_outlined,
                    label: 'AI Insights',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/ai-insights');
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppTheme.darkBorder),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outlined,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                ],
              ),
            ),

            // Footer
            const Divider(color: AppTheme.darkBorder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.darkCard,
                        title: const Text('Logout',
                            style: AppTextStyles.h3),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: AppTextStyles.bodySecondary,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error.withOpacity(0.12),
                    foregroundColor: AppTheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(label, style: AppTextStyles.body),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: AppTheme.primary.withOpacity(0.08),
    );
  }
}
