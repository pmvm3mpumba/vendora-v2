import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/vendora_logo.dart';
import '../../models/enums.dart';

/// Complétion du profil — comptes créés via la console Firebase SANS
/// document `users/{uid}` (ex. les 3 comptes existants du projet).
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  UserRole _role = UserRole.client;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AuthController>().completeProfile(
          name: _name.text,
          phone: _phone.text,
          role: _role,
          whatsappNumber: _whatsapp.text,
        );
    // AuthGate rebascule automatiquement dès que le profil existe.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final email = auth.firebaseUser?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VendoraLogo(),
                    const SizedBox(height: 24),
                    const InfoPill(label: 'Dernière étape'),
                    const SizedBox(height: 18),
                    Text('Complétez\nvotre profil.',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    Text(
                      'Le compte $email existe déjà. Indiquez vos informations pour continuer.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniRole(
                              label: 'Client',
                              selected: _role == UserRole.client,
                              onTap: () =>
                                  setState(() => _role = UserRole.client)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniRole(
                              label: 'Vendeur',
                              selected: _role == UserRole.seller,
                              onTap: () =>
                                  setState(() => _role = UserRole.seller)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FieldLabel(
                      'Nom complet',
                      child: TextFormField(
                        controller: _name,
                        validator: (v) => Validators.required(v, 'Le nom'),
                        decoration:
                            const InputDecoration(hintText: 'Prénom et nom'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(
                      'Téléphone',
                      child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        decoration: const InputDecoration(hintText: '+257…'),
                      ),
                    ),
                    if (_role == UserRole.seller) ...[
                      const SizedBox(height: 16),
                      FieldLabel(
                        'Numéro WhatsApp (obligatoire vendeur)',
                        child: TextFormField(
                          controller: _whatsapp,
                          keyboardType: TextInputType.phone,
                          validator: Validators.whatsapp,
                          decoration:
                              const InputDecoration(hintText: 'Ex. 257 79 000 000'),
                        ),
                      ),
                    ],
                    if (auth.error != null) ...[
                      const SizedBox(height: 14),
                      Text(auth.error!,
                          style: const TextStyle(
                              color: AppTheme.danger, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: auth.isBusy ? null : _submit,
                      child: auth.isBusy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.4))
                          : const Text('Continuer'),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            context.read<AuthController>().logout(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Utiliser un autre compte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniRole extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MiniRole(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (context.isDark
                  ? AppTheme.brand.withValues(alpha: 0.12)
                  : AppTheme.peach)
              : context.cardColor,
          border: Border.all(
              color: selected ? AppTheme.brand : context.lineColor,
              width: selected ? 1.6 : 1),
          borderRadius: BorderRadius.circular(AppTheme.rMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.brand : context.textColor,
          ),
        ),
      ),
    );
  }
}
