import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

import 'package:http/http.dart' as http;

class PostConfessionScreen extends StatefulWidget {
  const PostConfessionScreen({super.key});

  @override
  State<PostConfessionScreen> createState() => _PostConfessionScreenState();
}

class _PostConfessionScreenState extends State<PostConfessionScreen> {
  final TextEditingController _controller = TextEditingController();
  String _selectedCategory = 'Funny';
  final int _maxLength = 280;

  LatLng? _selectedLocation;
  String? _locationName;
  String? _city;
  String? _state;
  String? _country;

  final MapController _mapController = MapController();

  final List<String> _categories = ['Funny', 'Sad', 'Love', 'Work', 'Other'];

  Future<void> _selectLocation() async {
    LatLng? pickedLocation = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return FractionallySizedBox(
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

        // fallback to lat/lng if fullName empty
        if (fullName.isEmpty) {
          fullName =
              '${pickedLocation.latitude.toStringAsFixed(4)}, ${pickedLocation.longitude.toStringAsFixed(4)}';
        }

        setState(() {
          _selectedLocation = pickedLocation;
          _city = city;
          _state = state;
          _country = country;
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

    if (text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter confession text and select location'),
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://whisper-2nhg.onrender.com/api/confessions/create',
    );

    final body = {
      'text': text,
      'category': _selectedCategory,
      'location': {
        'type': "Point",
        "coordinates": [
          _selectedLocation!.longitude,
          _selectedLocation!.latitude,
        ],
      },
      "address": _locationName ?? "",
      'authorId': "6861b49812acae8f31fa3cbb",
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
          SnackBar(content: Text('Confession Posted Successfull')),
        );
        _controller.clear();

        setState(() {
          _selectedLocation = null;
          _locationName = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post confession')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error posting confession')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confession input
            Text(
              "Write your confession",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            SizedBox(height: 28),

            // Category section
            Text(
              'Category',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF6C5CE7) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? Color(0xFF6C5CE7)
                            : Colors.grey[300]!,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(0xFF6C5CE7).withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 28),

            // Location picker
            Text(
              'Location',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: _selectLocation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Color(0xFF6C5CE7)),
                    SizedBox(width: 10),
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
                    Icon(Icons.edit, color: Color(0xFF6C5CE7)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Map preview
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
              ),
            SizedBox(height: 40),

            // Post button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B81),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: _postConfession,
                child: Text(
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
    );
  }
}

// Location picker modal as bottom sheet overlay (without title)
class LocationPickerModal extends StatefulWidget {
  const LocationPickerModal({super.key});

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  LatLng? _pickedLocation;
  final LatLng _initialLocation = LatLng(19.0760, 72.8777); // Mumbai

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _initialLocation,
              initialZoom: 13.0,
              onTap: (tapPosition, latlng) {
                setState(() {
                  _pickedLocation = latlng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.whisprapp',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation!,
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
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF6B81)),
            onPressed: () {
              if (_pickedLocation != null) {
                Navigator.pop(context, _pickedLocation);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please select a location on the map'),
                  ),
                );
              }
            },
            child: Text(
              'Confirm Location',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
