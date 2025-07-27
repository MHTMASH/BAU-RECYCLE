// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/Screen/add_product_page.dart';
import 'package:my_app/Screen/login.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import 'package:my_app/Screen/edit_product_page.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(color: Colors.green.shade800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.green.shade800),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.green.shade800),
            onPressed: _signOut,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.green.shade600),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    _buildUserStats(),
                    _buildMyListingsHeader(),
                    _buildUserProducts(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.green.shade50,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.green.shade200,
            child: Icon(Icons.person, size: 50, color: Colors.green.shade700),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.displayName ?? 'UniCycle User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  currentUser?.email ?? 'No email provided',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                SizedBox(height: 10),
                Text(
                  'Member since: ${_formatDate(currentUser?.metadata.creationTime)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('products')
                .where('sellerId', isEqualTo: currentUser?.uid)
                .snapshots(),
        builder: (context, snapshot) {
          int totalListings = 0;
          int activeListings = 0;

          if (snapshot.hasData) {
            totalListings = snapshot.data!.docs.length;
            final now = DateTime.now();

            activeListings =
                snapshot.data!.docs.where((doc) {
                  final product = Product.fromFirestore(doc);
                  return product.isAvailable && product.expiresAt.isAfter(now);
                }).length;
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Total Listings', totalListings.toString()),
              _buildStatCard('Active Listings', activeListings.toString()),
              // You can add more stat cards if needed
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.43,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMyListingsHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Listings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              // Refresh the listings
              setState(() {});
            },
            icon: Icon(Icons.refresh, color: Colors.green.shade600, size: 18),
            label: Text(
              'Refresh',
              style: TextStyle(color: Colors.green.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProducts() {
    print("Current user UID: ${currentUser?.uid}"); // Add this debug print

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
              .where('sellerId', isEqualTo: currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        // Add these debug prints
        print("Snapshot has error: ${snapshot.hasError}");
        print("Snapshot error: ${snapshot.error}");
        print("Snapshot has data: ${snapshot.hasData}");
        if (snapshot.hasData) {
          print("Number of documents: ${snapshot.data!.docs.length}");
          for (var doc in snapshot.data!.docs) {
            print("Document ID: ${doc.id}");
            print("Document sellerId: ${doc.get('sellerId')}");
          }
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.green.shade400),
          );
        }

        final products =
            snapshot.data!.docs
                .map((doc) => Product.fromFirestore(doc))
                .toList();

        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'You haven\'t created any listings yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProductScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Create New Listing',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductListItem(product);
          },
        );
      },
    );
  }

  Widget _buildProductListItem(Product product) {
    final now = DateTime.now();
    final isExpired = product.expiresAt.isBefore(now);
    final isActive = product.isAvailable && !isExpired;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child:
                    product.imageUrls.isNotEmpty
                        ? Image.network(
                          product.imageUrls[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        )
                        : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        ),
              ),
            ),
            SizedBox(width: 16),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status Indicator
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? Colors.green.shade100
                                  : (isExpired
                                      ? Colors.red.shade100
                                      : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive
                              ? 'Active'
                              : (isExpired ? 'Expired' : 'Inactive'),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isActive
                                    ? Colors.green.shade800
                                    : (isExpired
                                        ? Colors.red.shade800
                                        : Colors.grey.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '৳${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isExpired
                        ? 'Expired: ${_formatDate(product.expiresAt)}'
                        : 'Expires: ${_formatDate(product.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isExpired
                              ? Colors.red.shade700
                              : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _editProduct(product),
                        icon: Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        label: Text(
                          'Edit',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, 36),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      // Delete Button
                      TextButton.icon(
                        onPressed: () => _confirmDelete(product),
                        icon: Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red.shade700,
                        ),
                        label: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, 36),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
    // Refresh the page when returning
    setState(() {});
  }

  Future<void> _confirmDelete(Product product) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Listing'),
          content: Text(
            'Are you sure you want to delete "${product.title}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(product.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Listing deleted successfully'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting listing: $error'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signout();
      // Clear all routes and navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(date);
  }
}
