import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image gallery
            _buildImageGallery(context),

            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  Text(
                    product.title,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '৳${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Condition: ${product.condition}',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Divider(height: 32),

                  // Description section
                  _buildSectionTitle('Description'),
                  SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Location section
                  _buildSectionTitle('Location'),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      if (product.latitude != 0.0 && product.longitude != 0.0) {
                        MapsLauncher.launchCoordinates(
                          product.latitude ?? 0.0,
                          product.longitude ?? 0.0,
                          product.location,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Location coordinates not available'),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.green.shade600,
                            size: 28,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.location.isEmpty
                                      ? 'Location not specified'
                                      : product.location,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.open_in_new,
                                      size: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'View on Google Maps',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.map_outlined,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Availability and expiry info
                  _buildSectionTitle('Availability'),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.amber.shade800),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Available until: ${_formatDateTime(product.expiresAt)}',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),
                  Text(
                    'Listed on: ${_formatDateTime(product.createdAt)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),

                  Divider(height: 32),

                  // Seller info
                  _buildSectionTitle('Seller Information'),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          product.sellerName.isNotEmpty
                              ? product.sellerName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.sellerName.isNotEmpty
                                  ? product.sellerName
                                  : 'Unknown Seller',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (product.contactInfo.isNotEmpty)
                              Text(
                                '+880${product.contactInfo}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32),

                  // Contact button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Contact seller logic
                        _showContactDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Contact Seller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    if (product.imageUrls.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 80,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: product.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullScreenImage(context, index),
                child: Hero(
                  tag: 'product-image-${product.id}-$index',
                  child: Image.network(
                    product.imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: Colors.green.shade400,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
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
                  ),
                ),
              );
            },
          ),
          if (product.imageUrls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  product.imageUrls.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${product.imageUrls.length} ${product.imageUrls.length == 1 ? 'photo' : 'photos'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FullScreenImageViewer(
              imageUrls: product.imageUrls,
              initialIndex: initialIndex,
              productId: product.id,
            ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    // Clean the phone number to ensure it's in a proper format
    String? phoneNumber =
        '+880${product.contactInfo.replaceAll(RegExp(r'\s+'), '')}';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Contact Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (phoneNumber.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.phone, color: Colors.green.shade600),
                    title: Text('Call Seller'),
                    onTap: () async {
                      final Uri phoneUri = Uri.parse('tel:$phoneNumber');
                      try {
                        if (await launchUrl(phoneUri)) {
                          // Call launched successfully
                          Navigator.pop(context);
                        } else {
                          // Could not launch call
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not launch phone call. Try manually dialing $phoneNumber',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        print('Error launching phone call: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error launching phone app: $e'),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.message, color: Colors.green.shade600),
                  title: Text('In-App Message'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement in-app messaging
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Messaging functionality coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade800,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Full-screen image viewer for better image examination
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String productId;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.productId,
  });

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_currentIndex + 1}/${widget.imageUrls.length}'),
      ),
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: Hero(
                  tag: 'product-image-${widget.productId}-$index',
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
