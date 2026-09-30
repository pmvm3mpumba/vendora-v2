import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/catalogue/product_details_screen.dart';
import '../screens/catalogue/search_filter_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_confirmation_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/orders/order_details_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/profile/personal_info_screen.dart';
import '../screens/seller/product_form_screen.dart';

/// Routes hors-coque (écrans poussés au-dessus de la barre du bas).
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const search = '/search';
  static const checkout = '/checkout';
  static const orderHistory = '/orders';
  static const notifications = '/notifications';
  static const personalInfo = '/profile/edit';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _page(const LoginScreen());
      case register:
        return _page(const RegisterScreen());
      case search:
        return _page(const SearchFilterScreen());
      case checkout:
        return _page(const CheckoutScreen());
      case orderHistory:
        return _page(const OrderHistoryScreen());
      case notifications:
        return _page(const NotificationsScreen());
      case personalInfo:
        return _page(const PersonalInfoScreen());
      default:
        return null;
    }
  }

  static MaterialPageRoute<T> _page<T>(Widget child) =>
      MaterialPageRoute<T>(builder: (_) => child);

  // --- Navigation typée avec arguments ---
  static void pushProductDetails(BuildContext context, String productId) {
    Navigator.of(context)
        .push(_page(ProductDetailsScreen(productId: productId)));
  }

  static void pushOrderDetails(BuildContext context, String orderId) {
    Navigator.of(context).push(_page(OrderDetailsScreen(orderId: orderId)));
  }

  static void pushConfirmation(BuildContext context, String orderId) {
    Navigator.of(context).pushAndRemoveUntil(
      _page(OrderConfirmationScreen(orderId: orderId)),
      (route) => route.isFirst, // on garde uniquement la coque dessous
    );
  }

  static void pushProductForm(BuildContext context, {String? productId}) {
    Navigator.of(context)
        .push(_page(ProductFormScreen(productId: productId)));
  }
}

/// Exige une authentification AVANT une action protégée (énoncé §3/§21).
/// Visiteur → pousse l'écran Connexion ; retourne true une fois connecté.
Future<bool> requireAuth(BuildContext context) async {
  final auth = context.read<AuthController>();
  if (auth.isAuthenticated) return true;
  final result = await Navigator.of(context).pushNamed(AppRoutes.login);
  if (!context.mounted) return false;
  return result == true;
}
