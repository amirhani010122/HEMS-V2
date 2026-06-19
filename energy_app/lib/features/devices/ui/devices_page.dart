import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/devices_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/models/device_model.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(filteredDevicesProvider);
    final search = ref.watch(deviceSearchProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('My Devices'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          // ⭐ زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(devicesProvider.notifier).refresh(),
          ),
          // ⭐ زر الإشعارات
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Alerts',
            onPressed: () => context.push('/alerts'),
          ),
          // زر إضافة جهاز
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddDevice(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              onChanged: (v) =>
                  ref.read(deviceSearchProvider.notifier).state = v,
              decoration: const InputDecoration(
                hintText: 'Search devices...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Devices list
          Expanded(
            child: devicesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                itemBuilder: (_, __) => const SkeletonCard(),
              ),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.read(devicesProvider.notifier).refresh(),
              ),
              data: (devices) {
                if (devices.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.devices_other,
                    title: search.isNotEmpty ? 'No devices found' : 'No devices yet',
                    subtitle: search.isNotEmpty
                        ? 'Try a different search term'
                        : 'Add your first IoT device to start monitoring energy consumption.',
                    actionLabel: search.isEmpty ? 'Add Device' : null,
                    onAction: search.isEmpty
                        ? () => _showAddDevice(context, ref)
                        : null,
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.darkCard,
                  onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _DeviceCard(device: devices[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDevice(BuildContext context, WidgetRef ref) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Add Device', style: AppTextStyles.h3),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: idCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Device ID',
                    hintText: 'e.g. ESP32-001',
                    prefixIcon: Icon(Icons.fingerprint),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Device ID is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    hintText: 'e.g. Living Room AC',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Device name is required' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              setState(() => loading = true);
                              try {
                                await ref.read(devicesProvider.notifier).addDevice(
                                    idCtrl.text.trim(), nameCtrl.text.trim());
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                setState(() => loading = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    child: loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.darkBg),
                          )
                        : const Text('Add Device'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  final DeviceModel device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(device.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          ref.read(devicesProvider.notifier).deleteDevice(device.deviceId),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      child: GestureDetector(
        onTap: () => context.push('/devices/${device.deviceId}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Row(
            children: [
              // Device icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: device.isActive
                      ? AppTheme.primary.withOpacity(0.12)
                      : AppTheme.darkBorder,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.memory_rounded,
                  color: device.isActive ? AppTheme.primary : AppTheme.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Device info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.deviceName, style: AppTextStyles.h4),
                    const SizedBox(height: 2),
                    Text(
                      device.deviceId,
                      style: AppTextStyles.caption.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (device.lastSeen != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last seen: ${_formatTime(device.lastSeen!)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: device.isActive
                          ? AppTheme.success.withOpacity(0.12)
                          : AppTheme.textMuted.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: device.isActive
                                ? AppTheme.success
                                : AppTheme.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          device.isActive ? 'Active' : 'Offline',
                          style: TextStyle(
                            color: device.isActive
                                ? AppTheme.success
                                : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textMuted, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Device', style: AppTextStyles.h3),
        content: Text(
          'Remove "${device.deviceName}" from your account? This cannot be undone.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
