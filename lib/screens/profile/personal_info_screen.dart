import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/inputs.dart';
import '../../models/enums.dart';

/// Informations personnelles — nom, téléphone, WhatsApp (vendeur).
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().appUser;
    if (user != null) {
      _name.text = user.name;
      _phone.text = user.phone;
      _whatsapp.text = user.whatsappNumber;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await context.read<AuthController>().updateProfile(
          name: _name.text,
          phone: _phone.text,
          whatsapp: _whatsapp.text,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour ✓')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<AuthController>().error ??
              'Erreur lors de la mise à jour')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isSeller = auth.appUser?.role == UserRole.seller;
    return Scaffold(
      appBar: AppBar(title: const Text('Informations personnelles')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              FieldLabel(
                'Nom complet',
                child: TextFormField(
                  controller: _name,
                  validator: (v) => Validators.required(v, 'Le nom'),
                  decoration:
                      const InputDecoration(hintText: 'Prénom et nom'),
                ),
              ),
              const SizedBox(height: 18),
              FieldLabel(
                'Téléphone',
                child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  decoration: const InputDecoration(hintText: '+257…'),
                ),
              ),
              if (isSeller) ...[
                const SizedBox(height: 18),
                FieldLabel(
                  'Numéro WhatsApp (reçoit les commandes)',
                  child: TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    validator: Validators.whatsapp,
                    decoration:
                        const InputDecoration(hintText: 'Ex. 257 79 000 000'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ce numéro est joint à chacun de vos produits : les clients vous y envoient leurs commandes.',
                  style:
                      TextStyle(color: context.mutedColor, fontSize: 12),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: auth.isBusy ? null : _save,
                child: auth.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.4))
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
