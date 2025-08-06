// lib/models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String sellerId;
  final String sellerName;
  final String contactInfo;
  final List<String> imageUrls; // Keep for backward compatibility
  final List<String> base64Images; // Add this field
  final DateTime createdAt;
  final String hallDormitory;
  final DateTime expiresAt;
  final bool isAvailable;
  final String condition;
  final String location;
  final double? latitude;
  final double? longitude;
  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.contactInfo,
    required this.imageUrls,
    this.base64Images = const [], // Default to empty list
    required this.createdAt,
    required this.hallDormitory,
    required this.expiresAt,
    required this.isAvailable,
    required this.condition,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      contactInfo: data['contactInfo'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      base64Images: List<String>.from(data['base64Images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      hallDormitory: data['hallDormitory'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      condition: data['condition'] ?? 'Good',
      location: data['location'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
    );
  }

  // Update toFirestore method to include base64Images
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'contactInfo': contactInfo,
      'imageUrls': imageUrls,
      'base64Images': base64Images,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isAvailable': isAvailable,
      'condition': condition,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Category {
  final String id;
  final String name;
  final IconData icon;

  Category({required this.id, required this.name, required this.icon});

  static List<Category> defaultCategories = [
    Category(
      id: 'furniture ',
      name: 'Furniture ',
      icon: Icons.chair, // This one is correct
    ),
    Category(
      id: 'electronics',
      name: 'Electronics',
      icon: Icons.devices, // Changed to appropriate icon
    ),
    Category(
      id: 'b&s',
      name: 'Books',
      icon: Icons.menu_book, // Changed to appropriate icon
    ),
    Category(
      id: 'clothing',
      name: 'Clothing',
      icon: Icons.checkroom, // Changed to appropriate icon
    ),
    Category(
      id: 'b&v',
      name: 'Vehicles',
      icon: Icons.directions_bike, // Changed to appropriate icon
    ),
    Category(id: 'h&k', name: 'Kitchen', icon: Icons.kitchen),
    Category(
      id: 'sports',
      name: 'Sports',
      icon: Icons.sports, // Changed to appropriate icon
    ),
    Category(
      id: 'tolet',
      name: 'ToLet',
      icon: Icons.house, // Changed to appropriate icon
    ),
    Category(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz, // Changed to appropriate icon
    ),
  ];
}
