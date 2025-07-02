import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:whispr_app/widgets/location_picker_modal.dart';

class PostConfessionScreen extends StatefulWidget {
  final VoidCallback? onPostSuccess;

  const PostConfessionScreen({super.key, this.onPostSuccess});

  @override
  State<PostConfessionScreen> createState() => _PostConfessionScreenState();
}

class _PostConfessionScreenState extends State<PostConfessionScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedCategoryId;
  final int _maxLength = 280;

  LatLng? _selectedLocation;
  String? _locationName;

  String? _authorId;
  String? _username;

  final MapController _mapController = MapController();

  List<Category> _categories = [];
  bool _isLoadingCategories = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCategories();
  }

  /// Load authorId and username from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authorId = prefs.getString('userId');
      _username = prefs.getString('username');
    });
  }

  /// Fetch categories from API
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://whisper-2nhg.onrender.com/api/confession-categories',
        ),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _categories = data.map((e) => Category.fromJson(e)).toList();
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      } else {
        print('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }

    setState(() {
      _isLoadingCategories = false;
    });
  }

  Future<void> _selectLocation() async {
    LatLng? pickedLocation = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return const FractionallySizedBox(
          heightFactor: 0.9,
          child: LocationPickerModal(),
        );
      },
    );

    if (pickedLocation != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pickedLocation.latitude,
          pickedLocation.longitude,
        );

        Placemark place = placemarks.first;

        String city = place.locality ?? '';
        String state = place.administrativeArea ?? '';
        String country = place.country ?? '';

        String fullName = '';
        if (city.isNotEmpty) fullName += city;
        if (state.isNotEmpty)
          fullName += (fullName.isNotEmpty ? ', ' : '') + state;
        if (country.isNotEmpty)
          fullName += (fullName.isNotEmpty ? ', ' : '') + country;

        if (fullName.isEmpty) {
          fullName =
              '${pickedLocation.latitude.toStringAsFixed(4)}, ${pickedLocation.longitude.toStringAsFixed(4)}';
        }

        setState(() {
          _selectedLocation = pickedLocation;
          _locationName = fullName;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(pickedLocation, 13.0);
          }
        });
      } catch (e) {
        print('Geocoding failed: $e');
        setState(() {
          _selectedLocation = pickedLocation;
          _locationName =
              '${pickedLocation.latitude.toStringAsFixed(4)}, ${pickedLocation.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  Future<void> _postConfession() async {
    final text = _controller.text.trim();

    if (text.isEmpty ||
        _selectedLocation == null ||
        _authorId == null ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and ensure user is registered'),
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    final url = Uri.parse(
      'https://whisper-2nhg.onrender.com/api/confessions/create',
    );

    final body = {
      'text': text,
      'categoryId': _selectedCategoryId,
      'location': {
        'type': "Point",
        "coordinates": [
          _selectedLocation!.longitude,
          _selectedLocation!.latitude,
        ],
      },
      "address": _locationName ?? "",
      'authorId': _authorId,
      'username': _username,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('response statuscode ${response.statusCode}');
      print('response body ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confession Posted Successfully')),
        );
        _controller.clear();

        setState(() {
          _selectedLocation = null;
          _locationName = null;
        });

        /// Call onPostSuccess callback to navigate back to feed screen tab
        if (widget.onPostSuccess != null) {
          widget.onPostSuccess!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to post confession: ${response.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error posting confession: $e')));
    }

    setState(() {
      _isPosting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Confession input
                Text(
                  "Write your confession",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLength: _maxLength,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "What's on your mind...",
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 28),

                /// Category section
                Text(
                  'Category',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategoryId == category.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = category.id;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6C5CE7)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6C5CE7)
                                      : Colors.grey[300]!,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6C5CE7,
                                          ).withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                category.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 28),

                /// Location picker
                Text(
                  'Location',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _selectLocation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF6C5CE7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedLocation != null
                                ? _locationName ?? 'Fetching location name...'
                                : 'Select location',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.edit, color: Color(0xFF6C5CE7)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// Map preview
                if (_selectedLocation != null)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation!,
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName: 'com.example.whisprapp',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
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
                  ),
                const SizedBox(height: 40),

                /// Post button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B81),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isPosting ? null : _postConfession,
                    child: _isPosting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Post Confession',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Category model class
class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['_id'] ?? '', name: json['name'] ?? '');
  }
}
