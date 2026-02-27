import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/image_display.dart';
import '../auth/auth_service.dart';
import '../categories/categories_tab.dart';
import '../categories/services/category_service.dart';
import '../customers/customer_list_screen.dart';
import '../products/models/product.dart';
import '../products/services/product_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Rebuild to update FAB visibility
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('G-Tech'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentTeal,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Products'),
            Tab(icon: Icon(Icons.people), text: 'Customers'),
            Tab(icon: Icon(Icons.category), text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProductsTab(),
          CustomersTab(),
          CategoriesTab(),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    final tabIndex = _tabController.index;

    // Products tab
    if (tabIndex == 0) {
      return FloatingActionButton(
        backgroundColor: AppTheme.accentTeal,
        onPressed: () async {
          await context.push('/product/new');
          // Refresh products after returning
          ref.invalidate(productsProvider);
        },
        child: const Icon(Icons.add, color: Colors.white),
      );
    }

    // Categories tab
    if (tabIndex == 2) {
      return FloatingActionButton(
        backgroundColor: AppTheme.accentTeal,
        onPressed: () {
          showAddCategoryDialog(context, ref);
        },
        child: const Icon(Icons.add, color: Colors.white),
      );
    }

    // Customers tab — no FAB
    return null;
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('No products found.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(product: product);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    // Resolve category name from ID
    String categoryName = '';
    categoriesAsync.whenData((categories) {
      final match = categories.where((c) => c.id == product.categoryId);
      if (match.isNotEmpty) categoryName = match.first.name;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/product/${product.id}', extra: product);
          ref.invalidate(productsProvider);
        },
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 100,
              height: 100,
              child: ImageDisplay(imageUrl: product.imageUrl),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (categoryName.isNotEmpty)
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.price.toStringAsFixed(2)} DA',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Stock Status
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(
                product.inStock ? Icons.check_circle : Icons.cancel,
                color: product.inStock ? AppTheme.accentTeal : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
