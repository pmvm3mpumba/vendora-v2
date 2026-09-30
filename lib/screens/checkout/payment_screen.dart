import 'package:flutter/material.dart';

/// Ecran 9 - Choix Mobile Money / Carte, formulaire factice, processing, succes/echec (PaymentSimulator).
/// TODO(maquettes) : reproduire STRICTEMENT le design fourni
/// (couleurs, fonds, bordures, etats focus, espacements, UX).
class PaymentScreen extends StatelessWidget {

  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement simulé')),
      body: const Center(
        child: Text('UI a implementer selon la maquette - logique prete.'),
      ),
    );
  }
}
