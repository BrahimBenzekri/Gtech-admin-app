import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'models/category.dart';
import 'services/category_service.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('No categories found.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryCard(category: category);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          child: category.imageUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    category.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.category,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                )
              : const Icon(Icons.category, color: AppTheme.primaryBlue),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        subtitle: Text(
          category.slug,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref
                    .read(categoryServiceProvider)
                    .updateCategory(category.id, name);
                ref.invalidate(categoriesProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(categoryServiceProvider)
                  .deleteCategory(category.id);
              ref.invalidate(categoriesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void showAddCategoryDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add Category'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Category Name'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              await ref.read(categoryServiceProvider).addCategory(name);
              ref.invalidate(categoriesProvider);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
