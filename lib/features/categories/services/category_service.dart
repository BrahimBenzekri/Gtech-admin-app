import 'dart:developer';
import 'dart:io';

import 'package:admin_app/core/services/cloudinary_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';

class CategoryService {
  final SupabaseService _supabase = SupabaseService();
  final CloudinaryService _cloudinary = CloudinaryService();

  Future<List<Category>> getCategories() async {
    log('getCategories: Fetching categories');
    final data = await _supabase.from('categories').select().order('name');
    log('getCategories: Fetched ${data.length} categories');
    return data.map((json) => Category.fromMap(json)).toList();
  }

  Future<void> addCategory(String name, {File? imageFile}) async {
    log('addCategory: Adding category "$name"');
    String imageUrl = '';

    if (imageFile != null) {
      log('addCategory: Uploading image to Cloudinary');
      final url = await _cloudinary.uploadImage(imageFile);
      if (url != null) {
        imageUrl = url;
        log('addCategory: Image uploaded successfully: $imageUrl');
      } else {
        log('addCategory: Image upload failed');
      }
    }

    final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    await _supabase.from('categories').insert({
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
    });
    log('addCategory: Category "$name" added successfully');
  }

  Future<void> updateCategory(String id, String name,
      {File? imageFile}) async {
    log('updateCategory: Updating category $id');
    String? imageUrl;

    if (imageFile != null) {
      log('updateCategory: Uploading new image to Cloudinary');
      final url = await _cloudinary.uploadImage(imageFile);
      if (url != null) {
        imageUrl = url;
        log('updateCategory: Image uploaded successfully: $imageUrl');
      } else {
        log('updateCategory: Image upload failed');
      }
    }

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
