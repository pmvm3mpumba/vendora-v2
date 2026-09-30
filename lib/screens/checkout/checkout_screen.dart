import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../controllers/order_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/payment_test_data.dart';
import '../../core/utils/currency_converter.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/currency_menu.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/state_views.dart';
import '../../models/delivery_zone.dart';
import '../../models/enums.dart';

/// Écrans 7/8/9 — Finaliser la commande (maquette « 06 / LIVRAISON &
/// PAIEMENT ») : réception (livraison/retrait), paiement simulé,
/// « Scénario à tester », récapitulatif complet avant confirmation (§9).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();

  DeliveryOption _option = DeliveryOption.delivery;
  DeliveryZone _zone = AppConstants.deliveryZones.first;
  PaymentMethod _method = PaymentMethod.mobileMoney;
  String _scenario = PaymentTestData.scenarioSuccess;

  @override
  void initState() {
    super.initState();
    // Pré-remplit le téléphone avec celui du profil (UX).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().appUser;
      if (user != null && user.phone.isNotEmpty) _phone.text = user.phone;
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final orders = context.watch<OrderController>();
    final currency = context.watch<CurrencyController>().selected;

    if (!auth.isAuthenticated || auth.appUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finaliser ma commande')),
        body: const EmptyView(
          icon: Icons.lock_outline,
          title: 'Connexion requise',
          message: 'Connectez-vous pour finaliser votre commande.',
        ),
      );
    }
    if (cart.isEmpty && !orders.isProcessing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finaliser ma commande')),
        body: const EmptyView(
          icon: Icons.shopping_cart_outlined,
          title: 'Votre panier est vide',
          message: 'Ajoutez des produits avant de passer commande.',
        ),
      );
    }

    final subtotal = cart.subtotalIn(currency);
    final feeBif = _option == DeliveryOption.delivery ? _zone.feeBif : 0.0;
    final fee = CurrencyConverter.convert(feeBif, 'BIF', currency);
    final total = subtotal + fee;
    final readyForPayment = _option == DeliveryOption.pickup ||
        (_address.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser ma commande'),
        actions: const [CurrencyMenu(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              _StepIndicator(current: readyForPayment ? 2 : 1),
              const SizedBox(height: 22),
              Text('Comment recevoir votre commande ?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              // ── Livraison à domicile ──
              OptionCard(
                icon: Icons.local_shipping_outlined,
                title: 'Livraison à domicile',
                subtitle:
                    'À partir de ${Formatters.price(AppConstants.deliveryZones.first.feeBif, 'BIF')} selon la zone',
                selected: _option == DeliveryOption.delivery,
                onTap: () => setState(() => _option = DeliveryOption.delivery),
              ),
              const SizedBox(height: 10),
              OptionCard(
                icon: Icons.storefront_outlined,
                title: 'Retrait en boutique',
                subtitle:
                    'Gratuit · Adresse : ${AppConstants.pickupAddress}',
                selected: _option == DeliveryOption.pickup,
                onTap: () => setState(() => _option = DeliveryOption.pickup),
              ),

              if (_option == DeliveryOption.delivery) ...[
                const SizedBox(height: 20),
                FieldLabel(
                  'Zone de livraison',
                  child: DropdownButtonFormField<DeliveryZone>(
                    value: AppConstants.deliveryZones
                            .contains(_zone)
                        ? _zone
                        : AppConstants.deliveryZones.first,
                    decoration:
                        const InputDecoration(hintText: 'Choisissez une zone'),
                    items: [
                      for (final z in AppConstants.deliveryZones)
                        DropdownMenuItem(
                          value: z,
                          child: Text(
                              '${z.name} · +${Formatters.price(z.feeBif, 'BIF')}'),
                        ),
                    ],
                    onChanged: (z) =>
                        setState(() => _zone = z ?? _zone),
                  ),
                ),
                const SizedBox(height: 16),
                FieldLabel(
                  'Adresse de livraison',
                  child: TextFormField(
                    controller: _address,
                    validator: (v) =>
                        Validators.required(v, 'L\'adresse de livraison'),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        hintText: 'Quartier, avenue et repère'),
                  ),
                ),
                const SizedBox(height: 16),
                FieldLabel(
                  'Téléphone de contact',
                  child: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '+257…'),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Text('Paiement de démonstration',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              OptionCard(
                icon: Icons.smartphone,
                title: 'Mobile Money',
                subtitle: 'Simulation uniquement',
                selected: _method == PaymentMethod.mobileMoney,
                onTap: () =>
                    setState(() => _method = PaymentMethod.mobileMoney),
              ),
              const SizedBox(height: 10),
              OptionCard(
                icon: Icons.credit_card,
                title: 'Carte bancaire',
                subtitle: 'Aucune donnée bancaire demandée',
                selected: _method == PaymentMethod.card,
                onTap: () => setState(() => _method = PaymentMethod.card),
              ),
              const SizedBox(height: 16),
              FieldLabel(
                'Scénario à tester',
                child: DropdownButtonFormField<String>(
                  value: _scenario,
                  items: [
                    for (final s in PaymentTestData.scenarios)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (s) =>
                      setState(() => _scenario = s ?? _scenario),
                ),
              ),

              const SizedBox(height: 20),
              _RecapCard(
                  cart: cart, currency: currency, fee: fee, total: total),

              const SizedBox(height: 14),
              if (orders.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.rSm),
                    border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(orders.error!,
                            style: const TextStyle(
                                color: AppTheme.danger, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              Text(
                'Aucune transaction réelle. Ce paiement est entièrement simulé pour la démonstration.',
                style: TextStyle(color: context.mutedColor, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: context.lineColor)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: orders.isProcessing
                ? null
                : () => _pay(context, subtotal, fee, total, currency),
            child: orders.isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4))
                : Text('Payer · ${Formatters.price(total, currency)}'),
          ),
        ),
      ),
    );
  }

  Future<void> _pay(BuildContext context, double subtotal, double fee,
      double total, String currency) async {
    FocusScope.of(context).unfocus();
    if (_option == DeliveryOption.delivery &&
        !(_formKey.currentState?.validate() ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complétez les informations de livraison')));
      return;
    }
    final orders = context.read<OrderController>();
    orders.clearError();
    final orderId = await orders.checkout(
      client: context.read<AuthController>().appUser!,
      cart: context.read<CartController>(),
      currency: currency,
      option: _option,
      zone: _option == DeliveryOption.delivery ? _zone : null,
      location: _address.text,
      phone: _option == DeliveryOption.delivery
          ? _phone.text
          : context.read<AuthController>().appUser!.phone,
      paymentMethod: _method,
      paymentShouldSucceed: _scenario == PaymentTestData.scenarioSuccess,
    );
    if (!context.mounted) return;
    if (orderId != null) {
      AppRoutes.pushConfirmation(context, orderId); // étape 3
    } else if (orders.error != null) {
      // §21 — échec du paiement simulé : message SANS crash, on reste ici.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(orders.error!)));
    }
  }
}

/// Indicateur d'étapes 1 Réception · 2 Paiement · 3 Confirmation.
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _step(context, 1, 'Réception'),
        _line(context),
        _step(context, 2, 'Paiement'),
        _line(context),
        _step(context, 3, 'Confirmation'),
      ],
    );
  }

  Widget _line(BuildContext context) => Expanded(
        child:
            Container(height: 1.5, color: context.lineColor, margin: const EdgeInsets.symmetric(horizontal: 4)),
      );

  Widget _step(BuildContext context, int number, String label) {
    final done = number < current;
    final active = number <= current;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppTheme.forest : context.cardColor,
            shape: BoxShape.circle,
            border: Border.all(
                color: active ? AppTheme.forest : context.lineColor),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$number',
                  style: TextStyle(
                      color: active ? Colors.white : context.mutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: active ? context.textColor : context.mutedColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// « Votre récapitulatif » — §9 : produits, quantités, prix unitaires,
/// sous-total, livraison, total AVANT de confirmer.
class _RecapCard extends StatelessWidget {
  final CartController cart;
  final String currency;
  final double fee;
  final double total;
  const _RecapCard({
    required this.cart,
    required this.currency,
    required this.fee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.subtotalIn(currency);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre récapitulatif',
              style: TextStyle(
                  color: context.textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 12),
          for (final item in cart.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.product.name} × ${item.quantity}',
                          style: TextStyle(
                              color: context.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      Text(
                        '${Formatters.price(item.subtotalIn(currency) / item.quantity, currency)} / unité',
                        style: TextStyle(
                            color: context.mutedColor, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.price(item.subtotalIn(currency), currency),
                  style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sous-total',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(Formatters.price(subtotal, currency),
                  style: TextStyle(
                      color: context.textColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Livraison', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                fee == 0 ? 'Gratuite (retrait)' : Formatters.price(fee, currency),
                style: TextStyle(
                    color: context.textColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.lineColor, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              Text(Formatters.price(total, currency),
                  style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 19)),
            ],
          ),
        ],
      ),
    );
  }
}
