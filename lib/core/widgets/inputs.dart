import 'package:flutter/material.dart';

import '../../app/theme.dart';

// StatusPill est défini plus bas dans ce fichier.

/// Label gras AU-DESSUS du champ (style des formulaires des maquettes).
class FieldLabel extends StatelessWidget {
  final String text;
  final Widget child;
  const FieldLabel(this.text, {super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.5)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Petit libellé de section en majuscules espacées (ex. « MON ACTIVITÉ »).
class SectionCaption extends StatelessWidget {
  final String text;
  const SectionCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 22),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.mutedColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// Titre de section + lien orange à droite (ex. « À chaque envie / Tout voir → »).
class SectionTitle extends StatelessWidget {
  final String title;
  final String? linkLabel;
  final VoidCallback? onLink;
  const SectionTitle(this.title, {super.key, this.linkLabel, this.onLink});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (linkLabel != null)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onLink,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Text(linkLabel!,
                      style: const TextStyle(
                          color: AppTheme.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward,
                      size: 15, color: AppTheme.brand),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Pastille d'information (ex. « Bienvenue chez vous », « Confirmée »).
class InfoPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  const InfoPill({
    super.key,
    required this.label,
    this.background = AppTheme.peach,
    this.foreground = AppTheme.brand,
    this.icon,
  });

  const InfoPill.success({super.key, required this.label, this.icon})
      : background = AppTheme.greenSoft,
        foreground = AppTheme.greenText;

  @override
  Widget build(BuildContext context) {
    final bg = context.isDark ? foreground.withValues(alpha: 0.18) : background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
                color: foreground, fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de quantité « − 1 + » (fiche produit / panier) — maquette.
class QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool compact;
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = compact ? 36.0 : 44.0;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(context, Icons.remove, onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$quantity',
                style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ),
          _btn(context, Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: context.textColor),
        ),
      );
}

/// Pastille de statut de commande (historique / détails / vendeur).
class StatusPill extends StatelessWidget {
  final String label;
  final StatusPillKind kind;
  const StatusPill(this.label,
      {super.key, this.kind = StatusPillKind.neutral});

  factory StatusPill.of(String orderStatus, {Key? key}) {
    switch (orderStatus) {
      case 'confirmed':
        return StatusPill('Confirmée', key: key, kind: StatusPillKind.success);
      case 'delivered':
        return StatusPill('En livraison', key: key, kind: StatusPillKind.forest);
      case 'cancelled':
        return StatusPill('Annulée', key: key, kind: StatusPillKind.danger);
      default:
        return StatusPill('En attente', key: key, kind: StatusPillKind.pending);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      StatusPillKind.success => (AppTheme.greenSoft, AppTheme.greenText),
      StatusPillKind.forest => (AppTheme.forestSoft, AppTheme.forest),
      StatusPillKind.pending => (AppTheme.peach, AppTheme.brand),
      StatusPillKind.danger => (
          AppTheme.danger.withValues(alpha: 0.1),
          AppTheme.danger
        ),
      StatusPillKind.neutral => (
          context.isDark ? context.cardColor : const Color(0xFFEFEDE7),
          context.mutedColor
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

enum StatusPillKind { success, forest, pending, danger, neutral }

/// Carte d'option avec radio (livraison / retrait / moyen de paiement).
/// Sélectionnée = fond pêche + bordure orange + radio orange (maquette).
class OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.rLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? (context.isDark
                  ? AppTheme.brand.withValues(alpha: 0.12)
                  : AppTheme.peach)
              : context.cardColor,
          border: Border.all(
            color: selected ? AppTheme.brand : context.lineColor,
            width: selected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.rLg),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppTheme.brand : context.mutedColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 22, color: AppTheme.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: context.mutedColor, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
