import 'package:flutter/material.dart';

import 'core/config/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/customer_login_page.dart';
import 'features/auth/presentation/customer_register_page.dart';
import 'features/auth/presentation/delivery_login_page.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/cart/presentation/cart_page.dart';
import 'features/cart/presentation/checkout_page.dart';
import 'features/catalog/presentation/home_store_page.dart';
import 'features/catalog/presentation/product_detail_page.dart';
import 'features/delivery/presentation/delivery_assignments_page.dart';
import 'features/delivery/presentation/delivery_home_page.dart';
import 'features/delivery/presentation/delivery_status_page.dart';
import 'features/delivery/presentation/delivery_stores_page.dart';
import 'features/home/presentation/welcome_page.dart';
import 'features/orders/presentation/my_orders_page.dart';
import 'features/profile/presentation/customer_profile_page.dart';

class EcoCustomerApp extends StatelessWidget {
  const EcoCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcomSaaS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.home: (_) => const WelcomePage(),
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.customerLogin: (_) => const CustomerLoginPage(),
        AppRoutes.customerRegister: (_) => const CustomerRegisterPage(),
        AppRoutes.deliveryLogin: (_) => const DeliveryLoginPage(),
        AppRoutes.deliveryHome: (_) => const DeliveryHomePage(),
        AppRoutes.deliveryStores: (_) => const DeliveryStoresPage(),
        AppRoutes.deliveryAssignments: (_) => const DeliveryAssignmentsPage(),
        AppRoutes.deliveryConfirm: (_) =>
            const DeliveryAssignmentsPage(confirmMode: true),
        AppRoutes.deliveryStatus: (_) => const DeliveryStatusPage(),
        AppRoutes.customerProfile: (_) => const CustomerProfilePage(),
        AppRoutes.store: (_) => const HomeStorePage(),
        AppRoutes.myOrders: (_) => const MyOrdersPage(),
        AppRoutes.cart: (_) => const CartPage(),
        AppRoutes.checkout: (_) => const CheckoutPage(),
        CheckoutSuccessPage.routeName: (_) => const CheckoutSuccessPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.productDetail &&
            settings.arguments is ProductDetailArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => ProductDetailPage(
              args: settings.arguments! as ProductDetailArgs,
            ),
          );
        }

        return null;
      },
    );
  }
}
