import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/inputs.dart';
import '../../models/enums.dart';

/// Écran 2 — Inscription (maquette « 11 / INSCRIPTION »).
/// Choix du rôle client / vendeur ; WhatsApp exigé pour un vendeur (§4).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.client;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _whatsapp, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }
    final ok = await context.read<AuthController>().register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          phone: _phone.text,
          role: _role,
          whatsappNumber: _whatsapp.text,
        );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoPill(
                        label: 'Un compte, de nouvelles possibilités'),
                    const SizedBox(height: 18),
                    Text('Vos prochaines\ntrouvailles commencent ici.',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(
                      'Achetez en toute simplicité ou créez votre boutique.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    _RoleSelector(
                      role: _role,
                      onChanged: (r) => setState(() => _role = r),
                    ),
                    const SizedBox(height: 22),
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
                      'Adresse email',
                      child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        decoration:
                            const InputDecoration(hintText: 'vous@exemple.com'),
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
                        'Numéro WhatsApp (pour recevoir vos commandes)',
                        child: TextFormField(
                          controller: _whatsapp,
                          keyboardType: TextInputType.phone,
                          validator: Validators.whatsapp,
                          decoration: const InputDecoration(
                              hintText: 'Ex. 257 79 000 000'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FieldLabel(
                      'Mot de passe',
                      child: TextFormField(
                        controller: _password,
                        obscureText: _obscure1,
                        validator: Validators.password,
                        decoration: InputDecoration(
                          hintText: '8 caractères minimum',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure1
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _obscure1 = !_obscure1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(
                      'Confirmer le mot de passe',
                      child: TextFormField(
                        controller: _confirm,
                        obscureText: _obscure2,
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Confirmation requise';
                          if (v != _password.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'Répétez le mot de passe',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure2
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _obscure2 = !_obscure2),
                          ),
                        ),
                      ),
                    ),
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Créer mon compte'),
                                SizedBox(width: 6),
                                Icon(Icons.chevron_right, size: 22),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Déjà un compte ?',
                              style: Theme.of(context).textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Se connecter'),
                          ),
                        ],
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

/// Sélecteur de rôle — maquette : deux pastilles côte à côte,
/// sélectionnée = fond pêche + bordure + texte orange.
class _RoleSelector extends StatelessWidget {
  final UserRole role;
  final ValueChanged<UserRole> onChanged;
  const _RoleSelector({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleButton(
            label: 'Je suis client',
            icon: Icons.shopping_bag_outlined,
            selected: role == UserRole.client,
            onTap: () => onChanged(UserRole.client),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleButton(
            label: 'Je suis vendeur',
            icon: Icons.storefront_outlined,
            selected: role == UserRole.seller,
            onTap: () => onChanged(UserRole.seller),
          ),
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppTheme.brand : context.textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.brand : context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
