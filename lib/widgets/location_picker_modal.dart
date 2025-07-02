import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B81),
            ),
            onPressed: () {
              if (_pickedLocation != null) {
                Navigator.pop(context, _pickedLocation);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a location on the map'),
                  ),
                );
              }
            },
            child: const Text(
              'Confirm Location',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
