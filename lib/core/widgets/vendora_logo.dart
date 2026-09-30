import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Logo Vendora des maquettes : pastille orange « V » + wordmark.
class VendoraLogo extends StatelessWidget {
  final double size;
  final bool withText;
  const VendoraLogo({super.key, this.size = 34, this.withText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.brand,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          alignment: Alignment.center,
          child: Text(
            'V',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.55,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (withText) ...[
          const SizedBox(width: 8),
          Text(
            'vendora',
            style: TextStyle(
              color: context.textColor,
              fontSize: size * 0.62,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Wordmark seul avec le point orange (écran Connexion : « vendora. »).
class VendoraWordmark extends StatelessWidget {
  final double fontSize;
  const VendoraWordmark({super.key, this.fontSize = 34});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'vendora',
            style: TextStyle(
              color: AppTheme.brand,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          TextSpan(
            text: '.',
            style: TextStyle(
              color: context.textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
