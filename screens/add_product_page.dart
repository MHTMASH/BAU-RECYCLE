import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/product.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  LatLng? _selectedLocation;
  String _formattedAddress = '';
  final TextEditingController _locationController = TextEditingController();
  final mapController = MapController();
  // Cloudinary instance - replace with your cloud name and upload preset
  final cloudinary =
      CloudinaryPublic('dw7ay6rgt', 'my_app_uploads', cache: false);
  String _selectedHall = 'Other'; // Default value
  String _selectedCategory = '';
  String _selectedCondition = 'Good';
  DateTime _expiryDate = DateTime.now().add(Duration(days: 30));
  final List<File> _selectedImages = [];
  bool _isUploading = false;

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];

  @override
  void initState() {
    super.initState();
    // Pre-fill contact info if available from user profile
    _loadUserProfile();
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Add this method to show map selection dialog
  Future<void> _showLocationPicker() async {
    try {
      final Position position = await _getCurrentLocation();
      final LatLng initialLocation =
          LatLng(position.latitude, position.longitude);

      final LatLng? result = await showDialog<LatLng>(
        context: context,
        builder: (BuildContext context) {
          LatLng selectedLocation = initialLocation;

          return AlertDialog(
            title: Text('Select Location'),
            content: SizedBox(
              height: 400,
              width: 400,
              child: Column(
                children: [
                  Expanded(
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: initialLocation,
                        initialZoom: 15,
                        onTap: (tapPosition, point) {
                          selectedLocation = point;
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.your.app.package',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selectedLocation,
                              width: 80,
                              height: 80,
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Tap on the map to select location',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Confirm'),
                onPressed: () => Navigator.of(context).pop(selectedLocation),
              ),
            ],
          );
        },
      );

      if (result != null) {
        // Get address from coordinates
        List<Placemark> placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _formattedAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';

          setState(() {
            _selectedLocation = result;
            _locationController.text = _formattedAddress;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting location: $e')),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            final userData = userDoc.data() as Map<String, dynamic>;
            _contactInfoController.text = userData['contactInfo'] ?? '';
            _locationController.text = userData['location'] ?? '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }
  }

  Future<void> _selectImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages
            .addAll(images.map((xFile) => File(xFile.path)).toList());
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  // New method to upload images to Cloudinary
  Future<List<String>> _uploadImagesToCloudinary() async {
    List<String> imageUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        File imageFile = _selectedImages[i];

        // Debug log file size
        print('Processing image ${i + 1}/${_selectedImages.length}');
        print('Original file size: ${await imageFile.length()} bytes');

        // Compress the image before uploading to save bandwidth
        final compressedFile = await FlutterImageCompress.compressWithFile(
          imageFile.path,
          minHeight: 800,
          minWidth: 800,
          quality: 70,
        );

        if (compressedFile == null) {
          throw Exception('Failed to compress image');
        }

        print('Compressed size: ${compressedFile.length} bytes');

        // Create a temporary file from compressed bytes for uploading
        final tempFile = File('${imageFile.path}_compressed.jpg')
          ..writeAsBytesSync(compressedFile);

        // Upload to Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            tempFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'product_images', // Organize images in folders
          ),
        );

        // Get the secure URL from the response
        final secureUrl = response.secureUrl;
        imageUrls.add(secureUrl);

        print('Uploaded image ${i + 1}: $secureUrl');

        // Clean up temporary file
        await tempFile.delete();
      } catch (e) {
        print('Error uploading image $i: $e');
        // Continue with other images even if one fails
        continue;
      }
    }

    if (imageUrls.isEmpty) {
      throw Exception('No images were successfully uploaded');
    }

    print('Successfully uploaded ${imageUrls.length} images');
    return imageUrls;
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add at least one image')),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        // Get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Get user profile
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userData = userDoc.data() as Map<String, dynamic>;
        final sellerName = userData['fullName'] ?? 'Anonymous';

        // Upload images to Cloudinary
        final uploadProgress = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading images...'),
            duration: Duration(minutes: 5), // Long duration as placeholder
          ),
        );

        List<String> imageUrls = await _uploadImagesToCloudinary();

        // Dismiss the uploading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Create product with Cloudinary URLs
        final product = Product(
          id: '', // Will be set by Firestore
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          category: _selectedCategory,
          sellerId: user.uid,
          sellerName: sellerName,
          contactInfo: _contactInfoController.text,
          imageUrls: imageUrls, // Store Cloudinary URLs
          base64Images: [], // No need to store base64 images
          createdAt: DateTime.now(),
          expiresAt: _expiryDate,
          hallDormitory: _selectedHall,
          isAvailable: true,
          condition: _selectedCondition,
          location: _locationController.text,
          latitude: _selectedLocation?.latitude ?? 0.0,
          longitude: _selectedLocation?.longitude ?? 0.0,
        );

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('products')
            .add(product.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product posted successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post product: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post New Item',
          style: TextStyle(color: Colors.green.shade800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.green.shade800),
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green.shade600),
                  SizedBox(height: 16),
                  Text('Uploading your product...',
                      style: TextStyle(color: Colors.green.shade800)),
                  SizedBox(height: 8),
                  Text('This may take a moment if you have multiple images',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSelector(),
                    SizedBox(height: 24),
                    _buildBasicInfoSection(),
                    SizedBox(height: 24),
                    _buildDetailsSection(),
                    SizedBox(height: 24),
                    _buildContactSection(),
                    SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            )),
        SizedBox(height: 8),
        if (_selectedImages.isEmpty)
          // Full width buttons when no images
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 150,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library,
                          color: Colors.green.shade600, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Gallery',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).onTap(() => _selectImages()),
              ),
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          color: Colors.green.shade600, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Camera',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).onTap(() => _takePicture()),
              ),
            ],
          )
        else
          // Scrollable list with images and buttons
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...List.generate(
                  _selectedImages.length,
                  (index) => _buildImageTile(index),
                ),
                // Add buttons after images
                Container(
                  width: 120,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library,
                          color: Colors.green.shade600, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Gallery',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).onTap(() => _selectImages()),
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          color: Colors.green.shade600, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Camera',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).onTap(() => _takePicture()),
              ],
            ),
          ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Note: Images will be uploaded to cloud storage',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile(int index) {
    return Stack(
      children: [
        Container(
          width: 120,
          margin: EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImages[index],
              fit: BoxFit.cover,
              height: 150,
              width: 120,
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 13,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: Colors.red.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            )),
        SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: 'Enter a descriptive title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your item in detail',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'Price',
            prefix: Text('৳ ',
                style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            hintText: 'Enter the price',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a price';
            }
            try {
              final price = double.parse(value);
              if (price <= 0) {
                return 'Price must be greater than zero';
              }
            } catch (e) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            )),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
          ),
          items: Category.defaultCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue!;
            });
          },
          value: _selectedCategory.isEmpty ? null : _selectedCategory,
          hint: Text('Select a category'),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Condition',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
          ),
          items: _conditions.map((condition) {
            return DropdownMenuItem<String>(
              value: condition,
              child: Text(condition),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCondition = newValue!;
            });
          },
          value: _selectedCondition,
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _selectExpiryDate,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Listing Expiry Date',
                hintText: 'When should this listing expire?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.green.shade400, width: 2),
                ),
                suffixIcon:
                    Icon(Icons.calendar_today, color: Colors.green.shade600),
              ),
              controller: TextEditingController(
                text: DateFormat('MMM dd, yyyy').format(_expiryDate),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            )),
        SizedBox(height: 16),

        // Hall Selection Dropdown
        DropdownButtonFormField<String>(
          isExpanded: true, // Add this line
          decoration: InputDecoration(
            labelText: 'Hall/Dormitory',
            hintText: 'Select your hall or dormitory',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.apartment, color: Colors.green.shade600),
          ),
          items: [
            'Isha Khan Hall',
            'Shahjalal Hall',
            'Shaheed Shamsul Haque Hall',
            'Hossain Shaheed Suhrawardy Hall',
            'Fazlul Haque Hall',
            'Shaheed Nazmul Ahsan Hall',
            'Ashraful Haque Hall',
            'Shahid Jamal Hossain Hall',
            'Bangabandhu Sheikh Mujib Hall',
            'Sultana Razia Hall',
            'Taposhi Rabeya Hall',
            'July 36 Hall',
            'Begum Rokeya Hall',
            'Krishikanna Hall',
            'Shahid Saad Ibney Momtaz PhD Dormitory',
            'Other'
          ].map((String hall) {
            return DropdownMenuItem<String>(
              value: hall,
              child: Text(hall),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedHall = newValue!;
            });
          },
          value: _selectedHall,
        ),
        SizedBox(height: 16),

        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Enter location or select from map',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.location_on, color: Colors.green.shade600),
            suffixIcon: IconButton(
              icon: Icon(Icons.map, color: Colors.green.shade600),
              onPressed: () => _openFullScreenMap(),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter or select a location';
            }
            return null;
          },
          onChanged: (value) {
            // Clear coordinates when user types manually
            if (_selectedLocation != null) {
              setState(() {
                _selectedLocation = null;
              });
            }
          },
        ),
        SizedBox(height: 16),
        // Phone number field remains the same
        TextFormField(
          controller: _contactInfoController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '1XXXXXXXXX',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade400, width: 2),
            ),
            prefixIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              margin: EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, color: Colors.green.shade600),
                  SizedBox(width: 8),
                  Text(
                    '+880',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter contact information';
            }
            if (value.length < 9) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
          onSaved: (value) {
            if (value != null && value.isNotEmpty) {
              _contactInfoController.text = '+880${value.trim()}';
            }
          },
        ),
      ],
    );
  }

  Future<void> _openFullScreenMap() async {
    try {
      LatLng initialLocation;

      if (_selectedLocation != null) {
        initialLocation = _selectedLocation!;
      } else {
        // Try to get current location
        final position = await _getCurrentLocation();
        initialLocation = LatLng(position.latitude, position.longitude);
      }

      final result = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenMap(initialLocation: initialLocation),
        ),
      );

      if (result != null) {
        try {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(width: 16),
                  Text('Getting location details...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );

          // Get address from coordinates
          List<Placemark> placemarks = await placemarkFromCoordinates(
            result.latitude,
            result.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String formattedAddress = [
              if (place.street?.isNotEmpty ?? false) place.street,
              if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
              if (place.locality?.isNotEmpty ?? false) place.locality,
              if (place.administrativeArea?.isNotEmpty ?? false)
                place.administrativeArea,
            ].where((element) => element != null).join(', ');

            setState(() {
              _selectedLocation = result;
              _locationController.text = formattedAddress;
            });
          }
        } catch (e) {
          print('Error getting address: $e');
          setState(() {
            _selectedLocation = result;
            _locationController.text =
                'Selected location (${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)})';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening map: $e')),
      );
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Post Item',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }
}

extension TapExtension on Widget {
  Widget onTap(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: this,
    );
  }
}

class FullScreenMap extends StatefulWidget {
  final LatLng? initialLocation;

  const FullScreenMap({super.key, this.initialLocation});

  @override
  _FullScreenMapState createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
  late LatLng selectedLocation;
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    selectedLocation =
        widget.initialLocation ?? LatLng(23.8103, 90.4125); // Default to Dhaka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selectedLocation);
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: Colors.green.shade600),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.your.app.package',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Optional: Add a center button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.green.shade600),
              onPressed: () async {
                try {
                  final position = await Geolocator.getCurrentPosition();
                  final newLocation =
                      LatLng(position.latitude, position.longitude);
                  mapController.move(newLocation, 15);
                  setState(() {
                    selectedLocation = newLocation;
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error getting location: $e')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
