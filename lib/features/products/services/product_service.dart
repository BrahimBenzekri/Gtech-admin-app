import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      imageUrl = await _uploadImage(imageFile);
    }

    // Create a new document reference with auto-ID if product.id is empty, or use logic.
    // Usually we want to generate ID or let Firestore do it.
    // Here we'll let Firestore generate it if empty, or use the one we have?
    // Let's assume we pass a Product object which might have empty ID if new.
    
    final docRef = _firestore.collection('products').doc(); // Auto ID
    
    final newProduct = Product(
        id: docRef.id,
        name: product.name,
        category: product.category,
        basePrice: product.basePrice,
        oldPrice: product.oldPrice,
        imageUrl: imageUrl,
        description: product.description,
        inStock: product.inStock,
        storeIds: product.storeIds
    );

    await docRef.set(newProduct.toMap());
  }
  
  Future<void> updateProduct(Product product, File? imageFile) async {
     String imageUrl = product.imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile);
    }
    
    // We update the fields.
     final updatedData = product.toMap();
     updatedData['image_url'] = imageUrl; // Update URL if changed

     await _firestore.collection('products').doc(product.id).update(updatedData);
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<String> _uploadImage(File file) async {
    final String uuid = const Uuid().v4();
    final ref = _storage.ref().child('product_images/$uuid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).getProducts();
});
