import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../pages/global.dart';

class RouteService {
  final BuildContext context;
  final String apiKey;
  final PolylinePoints polylinePoints = PolylinePoints();
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  DateTime? _lastSnapTime;
  DateTime? _lastVibrationTime;
  Map<String, dynamic>? _lastManeuver; // Menyimpan manuver terakhir yang dipicu

  RouteService({required this.context, required this.apiKey});

  Future<void> sendVibrationCommand(String command) async {
    if (Global.connectedDeviceId == null) {
      print('Tidak ada ESP32 terhubung');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada ESP32 yang terhubung')),
        );
      }
      return;
    }

    print('Mengirim perintah: $command ke device ${Global.connectedDeviceId}');

    try {
      final qualifiedCharacteristic = QualifiedCharacteristic(
        serviceId: Global.serviceUuid,
        characteristicId: Global.characteristicUuid,
        deviceId: Global.connectedDeviceId!,
      );
      await _ble.writeCharacteristicWithoutResponse(
        qualifiedCharacteristic,
        value: command.codeUnits,
      );
      print('Berhasil mengirim perintah: $command');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perintah $command dikirim ke ESP32')),
        );
      }
    } catch (e) {
      print('Error mengirim perintah vibrasi: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim perintah: $e')),
        );
      }
    }
  }

  bool _shouldSnapToRoads() {
    const minInterval = Duration(seconds: 2);
    if (_lastSnapTime == null) return true;
    return DateTime.now().difference(_lastSnapTime!) > minInterval;
  }

  bool _shouldVibrate() {
    const minInterval = Duration(seconds: 3);
    if (_lastVibrationTime == null) return true;
    return DateTime.now().difference(_lastVibrationTime!) > minInterval;
  }

  Future<List<LatLng>> snapToRoads(List<LatLng> gpsPoints) async {
    if (gpsPoints.isEmpty) return [];

    final path = gpsPoints
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');

    final url = Uri.parse(
      'https://roads.googleapis.com/v1/snapToRoads'
      '?path=$path'
      '&interpolate=true'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['snappedPoints'] != null) {
          return data['snappedPoints']
              .map<LatLng>((point) => LatLng(
                    point['location']['latitude'],
                    point['location']['longitude'],
                  ))
              .toList();
        } else {
          print('No snappedPoints in response: ${data['status']}');
          return gpsPoints;
        }
      } else {
        print('API error: ${response.statusCode}, ${response.body}');
        return gpsPoints;
      }
    } catch (e) {
      print('Error calling Snap to Roads API: $e');
      return gpsPoints;
    }
  }

  Future<void> createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
    List<Map<String, dynamic>> routeOptions,
    void Function(VoidCallback) setState,
  ) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$startLatitude,$startLongitude&destination=$destinationLatitude,$destinationLongitude&mode=driving&alternatives=true&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          routeOptions.clear();
          final routes = data['routes'] as List<dynamic>;

          for (var i = 0; i < routes.length; i++) {
            final routePoints = <LatLng>[];
            final polyline = routes[i]['overview_polyline']['points'];
            final decodedPoints = polylinePoints.decodePolyline(polyline);
            routePoints.addAll(decodedPoints
                .map((point) => LatLng(point.latitude, point.longitude)));

            final distanceInMeters =
                routes[i]['legs'][0]['distance']['value'].toDouble();
            final distanceInKm = distanceInMeters / 1000;
            final durationInSeconds =
                routes[i]['legs'][0]['duration']['value'] as int;
            final durationInMinutes = (durationInSeconds / 60).round();

            final steps = routes[i]['legs'][0]['steps'] as List<dynamic>;
            final maneuvers = steps
                .asMap()
                .entries
                .where((entry) => entry.value['maneuver'] != null)
                .map((entry) {
              final step = entry.value;
              final maneuver = step['maneuver'];
              final endLocation = step['end_location'];
              return {
                'maneuver': maneuver,
                'position': LatLng(endLocation['lat'], endLocation['lng']),
                'instruction': step['html_instructions'],
              };
            }).toList();

            print('Maneuvers for route $i: $maneuvers');

            routeOptions.add({
              'points': routePoints,
              'distance': distanceInKm,
              'duration': durationInMinutes,
              'maneuvers': maneuvers,
            });
          }

          print('Total routes: ${routeOptions.length}');
          setState(() {});
        } else {
          print('Failed to get routes: ${data['status']}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to get routes: ${data['status']}')),
            );
          }
        }
      } else {
        print('API error: ${response.statusCode}, ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to contact Directions API: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Error creating polylines: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create route. Try again?'),
            action: SnackBarAction(
              label: 'Try Again',
              onPressed: () => createPolylines(
                startLatitude,
                startLongitude,
                destinationLatitude,
                destinationLongitude,
                routeOptions,
                setState,
              ),
            ),
          ),
        );
      }
    }
  }

  void checkGeofenceAndTriggerVibration(
    Position position,
    List<Map<String, dynamic>> maneuvers,
  ) async {
    if (!_shouldVibrate()) {
      print('Getaran ditunda karena cooldown');
      return;
    }

    if (maneuvers.isEmpty) {
      print('Tidak ada manuver tersedia');
      if (_lastManeuver != null) {
        print('Mengirim STOP karena tidak ada manuver');
        await sendVibrationCommand('STOP');
        _lastManeuver = null;
      }
      return;
    }

    LatLng currentPos = LatLng(position.latitude, position.longitude);
    print(
        'Posisi saat ini: $currentPos, Akurasi GPS: ${position.accuracy} meter');

    bool maneuverTriggered = false;
    for (var maneuver in maneuvers) {
      LatLng maneuverPos = maneuver['position'];
      double distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        maneuverPos.latitude,
        maneuverPos.longitude,
      );

      print(
          'Manuver: ${maneuver['maneuver']}, Jarak: $distance meter, Posisi manuver: $maneuverPos');

      // Picu getaran pada jarak 8–12 meter untuk akomodasi akurasi GPS
      if (distance >= 8 && distance <= 12) {
        String command = '';
        switch (maneuver['maneuver']) {
          case 'turn-left':
            command = 'TURN_LEFT';
            break;
          case 'turn-right':
            command = 'TURN_RIGHT';
            break;
          case 'turn-slight-left':
            command = 'TURN_SLIGHT_LEFT';
            break;
          case 'turn-slight-right':
            command = 'TURN_SLIGHT_RIGHT';
            break;
          case 'turn-sharp-left':
            command = 'TURN_SHARP_LEFT';
            break;
          case 'turn-sharp-right':
            command = 'TURN_SHARP_RIGHT';
            break;
          case 'fork-left':
            command = 'FORK_LEFT';
            break;
          case 'fork-right':
            command = 'FORK_RIGHT';
            break;
          case 'uturn-right':
            command = 'UTURN_RIGHT';
            break;
          case 'roundabout':
            command = 'ROUNDABOUT';
            break;
          case 'destination-left':
            command = 'DESTINATION_LEFT';
            break;
          case 'destination-right':
            command = 'DESTINATION_RIGHT';
            break;
          default:
            print('Manuver ${maneuver['maneuver']} diabaikan');
            continue;
        }
        print('Memicu getaran untuk $command pada jarak $distance meter');
        await sendVibrationCommand(command);
        _lastVibrationTime = DateTime.now();
        _lastManeuver = maneuver; // Simpan manuver yang dipicu
        maneuverTriggered = true;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Getaran $command pada $distance meter')),
          );
        }
        break;
      }
    }

    // Jika tidak ada manuver yang dipicu dan ada manuver sebelumnya, kirim STOP
    if (!maneuverTriggered && _lastManeuver != null) {
      double distanceToLastManeuver = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        _lastManeuver!['position'].latitude,
        _lastManeuver!['position'].longitude,
      );
      if (distanceToLastManeuver < 8 || distanceToLastManeuver > 12) {
        print(
            'Mengirim STOP karena melewati manuver ${_lastManeuver!['maneuver']}');
        await sendVibrationCommand('STOP');
        _lastManeuver = null;
      }
    }
  }

  void updatePolylineBasedOnPosition(
    Position position,
    List<LatLng> polylineCoordinates,
    LatLng? destinationLatLng,
    Map<PolylineId, Polyline> polylines,
    Set<Marker> markers,
    GoogleMapController mapController,
    void Function(VoidCallback) setState,
    List<Map<String, dynamic>> routeOptions,
    int selectedRouteIndex,
  ) async {
    final startTime = DateTime.now();
    print(
        'Memulai updatePolylineBasedOnPosition, posisi: ${LatLng(position.latitude, position.longitude)}');

    if (polylineCoordinates.isEmpty || destinationLatLng == null) {
      print('Polyline kosong atau tidak ada tujuan');
      if (_lastManeuver != null) {
        print('Mengirim STOP karena polyline kosong');
        await sendVibrationCommand('STOP');
        _lastManeuver = null;
      }
      return;
    }

    print(
        'Memperbarui posisi: ${LatLng(position.latitude, position.longitude)}, Route index: $selectedRouteIndex');

    if (routeOptions.isEmpty) {
      print('Route options kosong. Tidak ada rute yang tersedia.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada rute yang tersedia')),
        );
      }
      if (_lastManeuver != null) {
        print('Mengirim STOP karena tidak ada rute');
        await sendVibrationCommand('STOP');
        _lastManeuver = null;
      }
      return;
    }

    if (selectedRouteIndex >= routeOptions.length) {
      print(
          'Index rute tidak valid: $selectedRouteIndex, Total rute: ${routeOptions.length}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rute tidak valid')),
        );
      }
      if (_lastManeuver != null) {
        print('Mengirim STOP karena rute tidak valid');
        await sendVibrationCommand('STOP');
        _lastManeuver = null;
      }
      return;
    }

    List<Map<String, dynamic>> maneuvers =
        routeOptions[selectedRouteIndex]['maneuvers'];
    print('Jumlah manuver untuk rute $selectedRouteIndex: ${maneuvers.length}');
    checkGeofenceAndTriggerVibration(position, maneuvers);

    LatLng currentPos = LatLng(position.latitude, position.longitude);
    LatLng snappedCurrentPos = currentPos;
    List<LatLng> updatedCoordinates = List.from(polylineCoordinates);
    List<LatLng> passedCoordinates = [];

    if (position.accuracy > 20 || _shouldSnapToRoads()) {
      List<LatLng> gpsPoints = [currentPos];
      int closestIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < polylineCoordinates.length; i++) {
        double distance = Geolocator.distanceBetween(
          currentPos.latitude,
          currentPos.longitude,
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestIndex = i;
        }
      }
      print('Jarak terdekat: $minDistance meter, Index: $closestIndex');

      if (closestIndex > 0)
        gpsPoints.add(polylineCoordinates[closestIndex - 1]);
      gpsPoints.add(polylineCoordinates[closestIndex]);
      if (closestIndex < polylineCoordinates.length - 1)
        gpsPoints.add(polylineCoordinates[closestIndex + 1]);

      List<LatLng> snappedPoints = await snapToRoads(gpsPoints);
      if (snappedPoints.isNotEmpty) {
        snappedCurrentPos = snappedPoints.first;
        _lastSnapTime = DateTime.now();
        print('Snapped ke: $snappedCurrentPos');
      } else {
        print('Snap to Roads gagal, menggunakan posisi asli');
      }
    }

    int closestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < polylineCoordinates.length; i++) {
      double distance = Geolocator.distanceBetween(
        snappedCurrentPos.latitude,
        snappedCurrentPos.longitude,
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    print('Index terdekat setelah snap: $closestIndex');

    double distanceToDestination = Geolocator.distanceBetween(
      snappedCurrentPos.latitude,
      snappedCurrentPos.longitude,
      destinationLatLng.latitude,
      destinationLatLng.longitude,
    );
    if (distanceToDestination < 20) {
      setState(() {
        polylines.clear();
        polylineCoordinates.clear();
        _lastSnapTime = null;
        _lastVibrationTime = null;
      });
      if (_lastManeuver != null) {
        print('Mengirim STOP karena mencapai tujuan');
        await sendVibrationCommand('STOP');
        _lastManeuver = null;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have reached your destination!')),
        );
      }
      return;
    }

    if (closestIndex < polylineCoordinates.length - 1) {
      passedCoordinates = polylineCoordinates.sublist(0, closestIndex + 1);
      updatedCoordinates = polylineCoordinates.sublist(closestIndex);
    } else {
      passedCoordinates = List.from(polylineCoordinates);
      updatedCoordinates = [];
    }
    print(
        'Passed: ${passedCoordinates.length}, Remaining: ${updatedCoordinates.length}');

    setState(() {
      markers.removeWhere((m) => m.markerId.value == 'current_location');
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: snappedCurrentPos,
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      polylines.clear();
      if (updatedCoordinates.length >= 2) {
        polylines[const PolylineId('polyline')] = Polyline(
          polylineId: const PolylineId('polyline'),
          color: Colors.red,
          points: updatedCoordinates,
          width: 4,
        );
      }
      if (passedCoordinates.length >= 2) {
        polylines[const PolylineId('passed_polyline')] = Polyline(
          polylineId: const PolylineId('passed_polyline'),
          color: Colors.grey,
          points: passedCoordinates,
          width: 4,
        );
      }
    });

    mapController.animateCamera(
      CameraUpdate.newLatLng(snappedCurrentPos),
    );
  }

  Future<bool> calculateDistance(
    String startAddress,
    String destinationAddress,
    String currentAddress,
    Position? currentPosition,
    LatLng? destinationLatLng,
    Set<Marker> markers,
    List<LatLng> polylineCoordinates,
    List<LatLng> originalPolylineCoordinates,
    Map<PolylineId, Polyline> polylines,
    List<Map<String, dynamic>> routeOptions,
    void Function(VoidCallback) setState,
    void Function(String?, String?) updateDistanceDuration,
    void Function(bool) setCalculating,
  ) async {
    setCalculating(true);
    try {
      if (startAddress.isEmpty || destinationAddress.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Addresses cannot be empty')),
          );
        }
        return false;
      }

      if (currentPosition == null && startAddress == currentAddress) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Current location not available.')),
          );
        }
        return false;
      }

      final double startLatitude = startAddress == currentAddress
          ? currentPosition!.latitude
          : (await locationFromAddress(startAddress))[0].latitude;
      final double startLongitude = startAddress == currentAddress
          ? currentPosition!.longitude
          : (await locationFromAddress(startAddress))[0].longitude;

      double destinationLatitude;
      double destinationLongitude;
      if (destinationLatLng != null) {
        destinationLatitude = destinationLatLng.latitude;
        destinationLongitude = destinationLatLng.longitude;
      } else {
        final destinationPlacemark =
            await locationFromAddress(destinationAddress);
        destinationLatitude = destinationPlacemark[0].latitude;
        destinationLongitude = destinationPlacemark[0].longitude;
      }

      if (startLatitude == destinationLatitude &&
          startLongitude == destinationLongitude) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Start and destination cannot be the same')),
          );
        }
        return false;
      }

      final startMarker = Marker(
        markerId: const MarkerId('start'),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(title: 'Start', snippet: startAddress),
        icon: BitmapDescriptor.defaultMarker,
      );

      final destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow:
            InfoWindow(title: 'Destination', snippet: destinationAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      setState(() {
        markers.removeWhere((m) =>
            m.markerId.value == 'start' || m.markerId.value == 'destination');
        markers.add(startMarker);
        markers.add(destinationMarker);
      });

      await createPolylines(
        startLatitude,
        startLongitude,
        destinationLatitude,
        destinationLongitude,
        routeOptions,
        setState,
      );

      if (routeOptions.isNotEmpty) {
        selectRoute(
          0,
          routeOptions,
          polylineCoordinates,
          originalPolylineCoordinates,
          polylines,
          setState,
          updateDistanceDuration,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route calculated successfully')),
          );
        }
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to calculate route.')),
          );
        }
        return false;
      }
    } catch (e) {
      print('Error calculating distance: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to calculate distance.')),
        );
      }
      return false;
    } finally {
      setCalculating(false);
    }
  }

  void selectRoute(
    int index,
    List<Map<String, dynamic>> routeOptions,
    List<LatLng> polylineCoordinates,
    List<LatLng> originalPolylineCoordinates,
    Map<PolylineId, Polyline> polylines,
    void Function(VoidCallback) setState,
    void Function(String?, String?) updateDistanceDuration,
  ) {
    setState(() {
      polylineCoordinates.clear();
      polylineCoordinates.addAll(List.from(routeOptions[index]['points']));
      originalPolylineCoordinates.clear();
      originalPolylineCoordinates
          .addAll(List.from(routeOptions[index]['points']));
      final distance = routeOptions[index]['distance'].toStringAsFixed(2);
      final duration = "${routeOptions[index]['duration']} minutes";

      print(
          'Memilih rute $index, polylineCoordinates: ${polylineCoordinates.length} titik');
      print('DestinationLatLng: ${routeOptions[index]['points'].last}');

      const id = PolylineId('polyline');
      final polyline = Polyline(
        polylineId: id,
        color: Colors.red,
        points: polylineCoordinates,
        width: 4,
      );
      polylines[id] = polyline;

      updateDistanceDuration(distance, duration);
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route ${index + 1} selected')),
      );
    }
  }

  void cancelRoute(
    Map<PolylineId, Polyline> polylines,
    List<LatLng> polylineCoordinates,
    List<LatLng> originalPolylineCoordinates,
    List<Map<String, dynamic>> routeOptions,
    Set<Marker> markers,
    TextEditingController destinationAddressController,
    void Function(VoidCallback) setState,
    VoidCallback clearDestination,
  ) {
    setState(() {
      polylines.clear();
      polylineCoordinates.clear();
      originalPolylineCoordinates.clear();
      routeOptions.clear();
      markers.removeWhere((m) =>
          m.markerId.value == 'start' || m.markerId.value == 'destination');
      destinationAddressController.clear();
      _lastSnapTime = null;
      _lastVibrationTime = null;
      _lastManeuver = null;
    });
    print('Mengirim STOP karena rute dibatalkan');
    sendVibrationCommand('STOP');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route cancelled successfully')),
      );
    }
  }
}
