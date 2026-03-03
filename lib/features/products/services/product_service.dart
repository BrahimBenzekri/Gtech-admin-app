import 'dart:developer';
import 'dart:io';

import 'package:admin_app/core/services/cloudinary_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseService _supabase = SupabaseService();
  final CloudinaryService _cloudinary = CloudinaryService();

  // Fetch products with joined images
  Future<List<Product>> getProducts() async {
    log('getProducts: Fetching products with images');
    final data = await _supabase
        .from('products')
        .select('*, product_images(*)')
        .order('created_at', ascending: false);
    log('getProducts: Fetched ${data.length} products');
    return data.map((json) {
      return Product.fromMap(json['id'], json);
    }).toList();
  }

  Future<void> addProduct(Product product, File? imageFile) async {
    log('addProduct: Adding product "${product.name}"');
    String imageUrl = product.imageUrl;

    if (imageFile != null) {
      log('addProduct: Uploading image to Cloudinary');
      final url = await _cloudinary.uploadImage(imageFile);
      if (url != null) {
        imageUrl = url;
        log('addProduct: Image uploaded successfully: $imageUrl');
      } else {
        log('addProduct: Image upload failed, using existing URL');
      }
    }

    // 1. Insert Product
    log('addProduct: Inserting product into Supabase');
    final productResponse = await _supabase
        .from('products')
        .insert({
          'name': product.name,
          'slug': _generateSlug(product.name),
          'price': product.price,
          'discount_price': product.discountPrice,
          'description': product.description,
          'stock': product.stock,
          'category_id': product.categoryId,
        })
        .select()
        .single();

    final newProductId = productResponse['id'];
    log('addProduct: Product inserted with ID: $newProductId');

    // 2. Insert Image
    if (imageUrl.isNotEmpty) {
      log('addProduct: Inserting product image record');
      await _supabase.from('product_images').insert({
        'product_id': newProductId,
        'image_url': imageUrl,
        'is_main': true,
      });
      log('addProduct: Product image record inserted successfully');
    }
    log('addProduct: Product "${product.name}" added successfully');
  }

  Future<void> updateProduct(Product product, File? imageFile) async {
    log('updateProduct: Updating product "${product.name}" (ID: ${product.id})');
    String imageUrl = product.imageUrl;

    if (imageFile != null) {
      log('updateProduct: Uploading new image to Cloudinary');
      final url = await _cloudinary.uploadImage(imageFile);
      if (url != null) {
        imageUrl = url;
        log('updateProduct: New image uploaded successfully: $imageUrl');
      } else {
        log('updateProduct: Image upload failed, keeping existing URL');
      }
    }

    log('updateProduct: Updating product fields in Supabase');
    await _supabase.from('products').update({
      'name': product.name,
      'price': product.price,
      'discount_price': product.discountPrice,
      'description': product.description,
      'stock': product.stock,
      'category_id': product.categoryId,
    }).eq('id', product.id);
    log('updateProduct: Product fields updated successfully');

    // If image changed, update product_images table
    if (imageFile != null) {
      log('updateProduct: Image changed, updating product_images table');
      await _supabase
          .from('product_images')
          .delete()
          .eq('product_id', product.id)
          .eq('is_main', true);
      if (imageUrl.isNotEmpty) {
        await _supabase.from('product_images').insert({
          'product_id': product.id,
          'image_url': imageUrl,
          'is_main': true,
        });
      }
      log('updateProduct: Product image updated successfully');
    }
    log('updateProduct: Product "${product.name}" update complete');
  }

  Future<void> deleteProduct(String productId) async {
    log('deleteProduct: Deleting product with ID: $productId');
    await _supabase.from('products').delete().eq('id', productId);
    log('deleteProduct: Product $productId deleted successfully');
  }

  String _generateSlug(String name) {
    log('_generateSlug: Generating slug for "$name"');
    final slug =
        '${name.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}-${DateTime.now().millisecondsSinceEpoch}';
    log('_generateSlug: Generated slug: $slug');
    return slug;
  }
}

final productServiceProvider =
    Provider<ProductService>((ref) => ProductService());

final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).getProducts();
});
