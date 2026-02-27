import 'dart:developer';

import 'package:admin_app/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';

class CategoryService {
  final SupabaseService _supabase = SupabaseService();

  Future<List<Category>> getCategories() async {
    log('getCategories: Fetching categories');
    final data = await _supabase.from('categories').select().order('name');
    log('getCategories: Fetched ${data.length} categories');
    return data.map((json) => Category.fromMap(json)).toList();
  }

  Future<void> addCategory(String name, {String imageUrl = ''}) async {
    log('addCategory: Adding category "$name"');
    final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    await _supabase.from('categories').insert({
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
    });
    log('addCategory: Category "$name" added successfully');
  }

  Future<void> updateCategory(String id, String name,
      {String? imageUrl}) async {
    log('updateCategory: Updating category $id');
    final updates = <String, dynamic>{
      'name': name,
      'slug': name.toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
    };
    if (imageUrl != null) {
      updates['image_url'] = imageUrl;
    }
    await _supabase.from('categories').update(updates).eq('id', id);
    log('updateCategory: Category $id updated successfully');
  }

  Future<void> deleteCategory(String id) async {
    log('deleteCategory: Deleting category $id');
    await _supabase.from('categories').delete().eq('id', id);
    log('deleteCategory: Category $id deleted successfully');
  }
}

final categoryServiceProvider =
    Provider<CategoryService>((ref) => CategoryService());

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryServiceProvider).getCategories();
});
