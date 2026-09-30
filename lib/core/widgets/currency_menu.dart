import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/currency_controller.dart';
import '../constants/currencies.dart';

/// Sélecteur de devise « BIF ⌄ » des maquettes (AppBar / accueil / compte).
class CurrencyMenu extends StatelessWidget {
  final bool prominent;
  const CurrencyMenu({super.key, this.prominent = false});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<CurrencyController, String>((c) => c.selected);
    return PopupMenuButton<String>(
      tooltip: 'Devise d\'affichage',
      onSelected: (v) => context.read<CurrencyController>().select(v),
      itemBuilder: (_) => Currencies.supported
          .map((c) => PopupMenuItem(
                value: c,
                child: Row(
                  children: [
                    Icon(
                      c == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                      color: c == selected ? AppTheme.brand : context.mutedColor,
                    ),
                    const SizedBox(width: 10),
                    Text(c),
                  ],
                ),
              ))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: prominent ? AppTheme.brand : context.textColor,
                fontSize: 14,
              ),
            ),
            Icon(Icons.keyboard_arrow_down,
                size: 18,
                color: prominent ? AppTheme.brand : context.textColor),
          ],
        ),
      ),
    );
  }
}
