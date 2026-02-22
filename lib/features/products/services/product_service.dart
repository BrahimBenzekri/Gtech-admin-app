import 'dart:developer';
import 'dart:io';

import 'package:admin_app/core/services/cloudinary_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseService _supabase = SupabaseService();
  final CloudinaryService _cloudinary = CloudinaryService();

  // Stream of products (Realtime)
  Stream<List<Product>> getProducts() {
    log('getProducts: Starting to stream products');
    return _supabase.client.from('products').stream(primaryKey: ['id'])
        //.select('*, product_images(*)') // Join not supported directly in stream() for now in simple Flutter SDK usage without modifiers or explicit .rpc
        // Standard stream() only listens to single table changes.
        // Workaround for MVP: Fetch plain products. Images might need separate fetch or view.
        // For accurate Realtime with joins, we need a custom view or client-side join.
        // Let's stick to simple stream for now and assume basic fields.
        // If image is critical, we might need a fetch instead of stream, or a postgres view.
        .map((data) {
      log('getProducts: Received ${data.length} products from stream');
      return data.map((json) {
        // Map Supabase fields to Product model
        // 'image_url' might not be in 'products' table, but let's try to map what we can.
        // If schema has 'stock' instead of 'in_stock':
        final stock = json['stock'] as int? ?? 0;

        // Construct map for fromMap
        final map = Map<String, dynamic>.from(json);
        map['in_stock'] = stock > 0;
        // map['image_url'] = ... (Missing unless we fetch)

        return Product.fromMap(json['id'], map);
      }).toList();
    });
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

    log('Current user: ${_supabase.currentUser?.id}');
    log('User metadata: ${_supabase.currentUser?.appMetadata}');

    // 1. Insert Product
    log('addProduct: Inserting product into Supabase');
    try {
      final productResponse = await _supabase
          .from('products')
          .insert({
            'name': product.name,
            'slug': _generateSlug(product.name),
            'price': product.price,
            'description': product.description,
            'stock': product.inStock ? 10 : 0, // Fallback logic
            // 'category_id': ...
          })
          .select()
          .single();
      final newProductId = productResponse['id'];
      log('addProduct: Product inserted with ID: $newProductId');
    } on Exception catch (e) {
      log("addPProduct failed: $e");
    }

    // 2. Insert Image
    // if (imageUrl.isNotEmpty) {
    //   log('addProduct: Inserting product image record');
    //   await _supabase.from('product_images').insert({
    //     'product_id': newProductId,
    //     'image_url': imageUrl,
    //     'is_main': true,
    //   });
    //   log('addProduct: Product image record inserted successfully');
    // }
    // log('addProduct: Product "${product.name}" added successfully');
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
      'description': product.description,
      'stock': product.inStock ? 10 : 0,
      // 'slug' is usually not updated to preserve URLs, or updated carefully. Leaving as is.
    }).eq('id', product.id);
    log('updateProduct: Product fields updated successfully');

    // If image changed, update product_images table
    if (imageUrl != product.imageUrl) {
      log('updateProduct: Image changed, updating product_images table');
      // Ideally verify if product_images entry exists.
      // For MVP ensuring 'is_main' is updated or inserted.
      // This is complex without transaction.
      // Simplest: Delete old main, insert new.
      await _supabase
          .from('product_images')
          .delete()
          .eq('product_id', product.id)
          .eq('is_main', true);
      await _supabase.from('product_images').insert({
        'product_id': product.id,
        'image_url': imageUrl,
        'is_main': true,
      });
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

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).getProducts();
});
