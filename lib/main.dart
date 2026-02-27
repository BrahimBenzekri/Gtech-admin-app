import 'package:admin_app/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/products/models/product.dart';
import 'features/products/product_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseService().initialize();
  runApp(const ProviderScope(child: AdminApp()));
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authServiceProvider).authStateChanges,
    ),
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/product/new',
        builder: (context, state) => const ProductScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final product = state.extra as Product?;
          final id = state.pathParameters['id'];
          return ProductScreen(productId: id, product: product);
        },
      ),
    ],
  );
});

// Helper for Stream to Listenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard mobile design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Gtech',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
