import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';

/// BONUS — Notifications internes (maquette : cloche avec badge).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  /// Icône + couleur selon le TYPE de notification (déduit du titre) —
  /// bonne pratique UX : on identifie l'action d'un coup d'œil.
  static (IconData, Color) _styleFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('paiement')) {
      return (Icons.payments_outlined, AppTheme.brand);
    }
    if (t.contains('annul')) {
      return (Icons.cancel_outlined, AppTheme.danger);
    }
    if (t.contains('livré')) {
      return (Icons.local_shipping_outlined, AppTheme.greenText);
    }
    if (t.contains('confirm')) {
      return (Icons.task_alt_outlined, AppTheme.greenText);
    }
    if (t.contains('nouvelle commande')) {
      return (Icons.receipt_long_outlined, AppTheme.brand);
    }
    return (Icons.inventory_2_outlined, AppTheme.brand);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final notifs = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifs.unreadCount > 0)
            TextButton(
              onPressed: notifs.markAllAsRead,
              child: const Text('Tout marquer lu'),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: !auth.isAuthenticated
            ? const EmptyView(
                icon: Icons.notifications_none,
                title: 'Rien à voir ici',
                message: 'Connectez-vous pour recevoir vos notifications.',
              )
            : notifs.isLoading
                ? const LoadingView()
                : notifs.notifications.isEmpty
                    ? const EmptyView(
                        icon: Icons.notifications_none,
                        title: 'Aucune notification',
                        message:
                            'Les nouvelles commandes et suivis apparaîtront ici.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifs.notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final n = notifs.notifications[i];
                          final (icon, color) = _styleFor(n.title);
                          return InkWell(
                            borderRadius:
                                BorderRadius.circular(AppTheme.rLg),
                            onTap: () {
                              notifs.markAsRead(n);
                              if (n.orderId.isNotEmpty) {
                                AppRoutes.pushOrderDetails(
                                    context, n.orderId);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                border: Border.all(
                                    color: n.read
                                        ? context.lineColor
                                        : AppTheme.brand
                                            .withValues(alpha: 0.4)),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.rLg),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withValues(
                                          alpha:
                                              context.isDark ? 0.2 : 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon,
                                        size: 19, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(n.title,
                                            style: TextStyle(
                                                color: context.textColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        if (n.body.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(n.body,
                                              style: TextStyle(
                                                  color:
                                                      context.mutedColor,
                                                  fontSize: 12.5)),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                            Formatters.date(n.createdAt),
                                            style: TextStyle(
                                                color:
                                                    context.mutedColor,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  if (!n.read)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      margin:
                                          const EdgeInsets.only(top: 4),
                                      decoration: const BoxDecoration(
                                          color: AppTheme.brand,
                                          shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
