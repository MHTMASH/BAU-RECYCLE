import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/Screen/add_product_page.dart';
import 'package:my_app/Screen/profile_page.dart';
import '../models/product.dart';
import 'package:my_app/Screen/product_details_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategories(),
          Expanded(child: _buildProductGrid()), // <-- our scrollable area
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddProductScreen()),
        ),
        backgroundColor: Colors.green.shade600,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        title: Text(
          'BAU Recycle',
          style: TextStyle(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.green.shade800),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage()),
            ),
          ),
        ],
      );

  Widget _buildSearchBar() => Padding(
        padding: EdgeInsets.all(16.0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search items...',
            prefixIcon: Icon(Icons.search, color: Colors.green.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      );

  Widget _buildCategories() {
    final allCategories = [
      Category(id: 'all', name: 'All', icon: Icons.category),
      ...Category.defaultCategories,
    ];
    return SizedBox(
      height: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: allCategories.length,
              itemBuilder: (ctx, i) {
                final c = allCategories[i];
                final sel = _selectedCategory == c.id;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: sel ? 1 : 0),
                  duration: Duration(milliseconds: 200),
                  builder: (ctx, v, child) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = c.id);
                        _animationController.forward(from: 0);
                      },
                      child: Container(
                        width: 100,
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color:
                              Color.lerp(Colors.white, Colors.green.shade50, v),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color.lerp(Colors.grey.shade300,
                                Colors.green.shade400, v)!,
                            width: 1.5 + .5 * v,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: Color.lerp(Colors.grey.shade50,
                                  Colors.green.shade100, v),
                              child: Icon(c.icon,
                                  color: Colors.green.shade700, size: 28),
                            ),
                            SizedBox(height: 8),
                            Text(
                              c.name,
                              style: TextStyle(
                                color: Color.lerp(Colors.grey.shade700,
                                    Colors.green.shade800, v),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final products = snapshot.data!.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) {
          final matchesSearch = _searchQuery.isEmpty ||
              product.title.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == 'all' ||
              product.category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        if (products.isEmpty) return _buildEmptyState();

        return GridView.builder(
          padding: EdgeInsets.all(16),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← prevent expanding
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          SizedBox(height: 16),
          Text('Something went wrong',
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Please try again later',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← prevent expanding
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20)),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text('Loading items...',
              style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← prevent expanding
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(
              _searchQuery.isEmpty ? Icons.category_outlined : Icons.search_off,
              size: 60,
              color: Colors.green.shade300,
            ),
          ),
          SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? (_selectedCategory == 'all'
                    ? 'No items available'
                    : 'No items in this category')
                : 'No items match your search',
            style: TextStyle(
                color: Colors.green.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Try selecting a different category'
                : 'Try adjusting your search terms',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
                _selectedCategory = 'all';
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Clear Filters',
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildProductsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ FIX: prevents overflow
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls[0],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.green.shade400,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // ✅ Optional extra safety
                children: [
                  Text(
                    product.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '৳${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Expires in: ${_getTimeUntilExpiry(product.expiresAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  String _getTimeUntilExpiry(DateTime expiryDate) {
    final d = expiryDate.difference(DateTime.now());
    if (d.inDays > 0) return '${d.inDays} days';
    if (d.inHours > 0) return '${d.inHours} hours';
    return '${d.inMinutes} minutes';
  }
}
