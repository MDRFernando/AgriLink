import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(myNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const EmptyStateView(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: 'Order, payment, and delivery updates will appear here.',
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = items[i];
                return ListTile(
                  title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(n.body),
                  trailing: Text(DateFormat('HH:mm').format(n.createdAt)),
                );
              },
            ),
    );
  }
}
