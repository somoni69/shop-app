import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../locator.dart';
import '../screens/auth_screen.dart';
import '../screens/product_list_screen.dart';
import '../providers/cart_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: getIt<SupabaseClient>().auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        if (session != null) {
          // When user is logged in, load their cart
          // Use a delayed future to avoid calling setState during build
          Future.microtask(() {
            if (context.mounted) {
              Provider.of<CartProvider>(context, listen: false).loadCart();
            }
          });
          return const ProductListScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
