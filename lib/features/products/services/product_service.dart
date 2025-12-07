import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Product>> getProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addProduct(Product product, File? imageFile) async {
    String imageUrl = product.imageUrl;

    if (imageFile != null) {
      imageUrl = await _fileToBase64(imageFile);
    }

    final docRef = _firestore.collection('products').doc(); // Auto ID

    final newProduct = Product(
        id: docRef.id,
        name: product.name,
        category: product.category,
        basePrice: product.basePrice,
        oldPrice: product.oldPrice,
        imageUrl: imageUrl, // Now Base64
        description: product.description,
        inStock: product.inStock,
        storeIds: product.storeIds);

    await docRef.set(newProduct.toMap());
  }

  Future<void> updateProduct(Product product, File? imageFile) async {
    String imageUrl = product.imageUrl;

    if (imageFile != null) {
      imageUrl = await _fileToBase64(imageFile);
    }

    // We update the fields.
    final updatedData = product.toMap();
    updatedData['image_url'] = imageUrl; // Update URL/Base64 if changed

    await _firestore.collection('products').doc(product.id).update(updatedData);
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<String> _fileToBase64(File file) async {
     try {
       log('Converting file to Base64...');
       final bytes = await file.readAsBytes();
       final base64String = base64Encode(bytes);
       return base64String;
     } catch (e) {
       log('Conversion Error: $e');
       rethrow;
     }
  }
}

final productServiceProvider =
    Provider<ProductService>((ref) => ProductService());

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).getProducts();
});
