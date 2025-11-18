import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton(() => AuthService(getIt<SupabaseClient>()));
  getIt.registerLazySingleton(() => CartService(getIt<SupabaseClient>()));
  getIt.registerLazySingleton(() => OrderService(getIt<SupabaseClient>()));
}