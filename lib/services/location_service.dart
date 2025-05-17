import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final BuildContext context;
  final Function(Position) onPositionUpdate;
  final Function(String) onAddressUpdate;
  StreamSubscription<Position>? positionStream;
  bool isNavigating = false;

  LocationService({
    required this.context,
    required this.onPositionUpdate,
    required this.onAddressUpdate,
  });

  Future<void> getCurrentLocation(
    void Function(VoidCallback) setState,
    void Function(CameraPosition) updateInitialLocation,
  ) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan lokasi dinonaktifkan.')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak secara permanen. Aktifkan di pengaturan.',
              ),
            ),
          );
          await Geolocator.openLocationSettings();
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      print(
        'Lokasi saat ini: ${position.latitude}, ${position.longitude}, Akurasi: ${position.accuracy} meter',
      );

      setState(() {
        onPositionUpdate(position);
        updateInitialLocation(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18.0,
          ),
        );
      });

      if (isNavigating && position.accuracy > 20 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akurasi lokasi rendah, pindah ke area terbuka.'),
          ),
        );
      }

      await getAddress(position);
    } catch (e) {
      print('Error mendapatkan lokasi: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan lokasi saat ini.')),
        );
      }
    }
  }

  Future<void> getAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks[0];
      final address =
          "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
      print('Alamat: $address');
      onAddressUpdate(address);
    } catch (e) {
      print('Error mendapatkan alamat: $e');
    }
  }

  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks[0];
      final address =
          "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
      print('Alamat dari LatLng: $address');
      return address;
    } catch (e) {
      print('Error mendapatkan alamat dari koordinat: $e');
      return "Alamat tidak dikenal";
    }
  }

  void initializeLocationStream() {
    print('Memulai inisialisasi stream lokasi');
    try {
      positionStream?.cancel(); // Batalkan stream sebelumnya jika ada
      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
          timeLimit: Duration(milliseconds: 500),
        ),
      ).listen(
        (Position newPosition) {
          final now = DateTime.now();
          print(
            'Pembaruan lokasi [$now]: ${newPosition.latitude}, ${newPosition.longitude}, Akurasi: ${newPosition.accuracy} meter',
          );
          onPositionUpdate(newPosition);

          if (isNavigating && newPosition.accuracy > 20 && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akurasi lokasi rendah, pindah ke area terbuka.'),
              ),
            );
          }
        },
        onError: (e) {
          print('Error stream lokasi: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error stream lokasi: $e')),
            );
          }
        },
        onDone: () {
          print('Stream lokasi selesai');
        },
      );
      print('Stream lokasi aktif');
    } catch (e) {
      print('Error inisialisasi stream lokasi: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal inisialisasi stream lokasi: $e')),
        );
      }
    }
  }

  void setNavigationState(bool navigating) {
    isNavigating = navigating;
    print('Status navigasi LocationService: $isNavigating');
  }

  void dispose() {
    positionStream?.cancel();
    print('Stream lokasi dibatalkan');
  }
}
