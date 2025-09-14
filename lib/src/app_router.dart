import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';

class AppRouter {
  Route? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/product-detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: args['id']),
        );
      case '/':
      default:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
final appRouter = AppRouter();
