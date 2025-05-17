import 'package:flutter/material.dart' hide SearchBar;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../services/location_service.dart';
import 'package:ta/services/place_service.dart';
import 'package:ta/services/route_service.dart';
import '../widgets/map_widget.dart';
import '../widgets/search_bar.dart';
import '../widgets/route_info.dart';
import '../widgets/route_selector.dart';
import '../widgets/action_buttons.dart';
import '../secrets.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const String _currentLocationMarkerId = 'current_location';

  CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(-0.9231824, 100.4481168),
    zoom: 12.0,
  );
  GoogleMapController? mapController;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();

  Position? _currentPosition;
  String? _placeDistance;
  String? _placeDuration;
  bool _isCalculatingRoute = false;
  bool isNavigating = false;
  bool _isLocationUpdateActive =
      false; // Menandakan apakah pembaruan lokasi aktif

  String _currentAddress = '';
  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();
  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  LatLng? _destinationLatLng;

  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  List<LatLng> originalPolylineCoordinates = [];

  List<Map<String, dynamic>> _routeOptions = [];
  int _selectedRouteIndex = 0;

  late final LocationService _locationService;
  late final RouteService _routeService;
  late final PlaceService _placeService;

  late Future<void> _initialLocationFuture;
  Timer? _locationUpdateTimer; // Timer untuk pembaruan lokasi

  @override
  void initState() {
    super.initState();
    print(
        'Inisialisasi MapPage, routeOptions: ${_routeOptions.length}, selectedRouteIndex: $_selectedRouteIndex');
    _locationService = LocationService(
      context: context,
      onPositionUpdate: (Position position) {
        print(
            'Posisi baru: ${position.latitude}, ${position.longitude}, Akurasi: ${position.accuracy} meter');
        setState(() {
          _currentPosition = position;
          markers
              .removeWhere((m) => m.markerId.value == _currentLocationMarkerId);
          markers.add(
            Marker(
              markerId: const MarkerId(_currentLocationMarkerId),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(title: 'Current Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
            ),
          );
        });
        if (isNavigating && polylines.isNotEmpty && mapController != null) {
          print(
              'Navigasi aktif, routeOptions: ${_routeOptions.length}, selectedRouteIndex: $_selectedRouteIndex');
          _routeService.updatePolylineBasedOnPosition(
            position,
            polylineCoordinates,
            _destinationLatLng,
            polylines,
            markers,
            mapController!,
            setState,
            _routeOptions,
            _selectedRouteIndex,
          );
        } else if (mapController != null) {
          print('Navigasi tidak aktif, hanya memperbarui kamera');
          mapController!
              .animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          )
              .catchError((e) {
            print('Error animasi kamera: $e');
          });
        }
      },
      onAddressUpdate: (String address) {
        setState(() {
          _currentAddress = address;
          startAddressController.text = address;
          _startAddress = address;
        });
      },
    );
    _routeService = RouteService(context: context, apiKey: Secrets.API_KEY);
    _placeService = PlaceService(apiKey: Secrets.API_KEY);
    _initialLocationFuture = _locationService.getCurrentLocation(
      setState,
      (CameraPosition position) => _initialLocation = position,
    );
    _locationService.initializeLocationStream();
    // Tidak ada Timer.periodic di sini karena dikontrol oleh FAB
  }

  // Metode untuk memperbarui lokasi
  void _updateCurrentLocation() async {
    print("Memperbarui lokasi secara otomatis");
    await _locationService.getCurrentLocation(
      setState,
      (CameraPosition position) => _initialLocation = position,
    );
    if (_currentPosition != null && mapController != null && mounted) {
      mapController!
          .animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 18.0,
          ),
        ),
      )
          .catchError((e) {
        print('Error kamera myLocation: $e');
      });
    }
  }

  // Memulai navigasi dan pembaruan lokasi otomatis
  void _startLocationUpdates() {
    if (!_isLocationUpdateActive) {
      setState(() {
        _isLocationUpdateActive = true;
        isNavigating = true;
      });
      _locationService.setNavigationState(true);
      _locationUpdateTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        if (mounted) {
          _updateCurrentLocation();
        }
      });
      print('Pembaruan lokasi otomatis dimulai');
    }
  }

  // Menghentikan navigasi dan pembaruan lokasi otomatis
  void _stopLocationUpdates() {
    if (_isLocationUpdateActive) {
      _locationUpdateTimer?.cancel();
      setState(() {
        _isLocationUpdateActive = false;
        isNavigating = false;
      });
      _locationService.setNavigationState(false);
      print('Pembaruan lokasi otomatis dihentikan');
    }
  }

  void startNavigation() {
    setState(() {
      isNavigating = true;
      print(
          'Mulai navigasi, routeOptions: ${_routeOptions.length}, selectedRouteIndex: $_selectedRouteIndex');
    });
    _locationService.setNavigationState(true);
  }

  @override
  void dispose() {
    print('Dispose MapPage');
    _locationUpdateTimer?.cancel(); // Membatalkan timer jika ada
    _locationService.dispose();
    startAddressController.dispose();
    destinationAddressController.dispose();
    startAddressFocusNode.dispose();
    destinationAddressFocusNode.dispose();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initialLocationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              MapWidget(
                initialLocation: _initialLocation,
                markers: markers,
                polylines: polylines,
                liteModeEnabled: true,
                onMapCreated: (controller) {
                  print('Peta dibuat');
                  mapController = controller;
                  _mapControllerCompleter.complete(controller);
                },
                onLongPress: (LatLng position) async {
                  final address =
                      await _locationService.getAddressFromLatLng(position);
                  setState(() {
                    _destinationAddress = address;
                    _destinationLatLng = position;
                    destinationAddressController.text = address;
                    markers
                        .removeWhere((m) => m.markerId.value == 'destination');
                    markers.add(
                      Marker(
                        markerId: const MarkerId('destination'),
                        position: position,
                        infoWindow:
                            InfoWindow(title: 'Destination', snippet: address),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue),
                      ),
                    );
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Destination selected: $address')),
                    );
                  }
                },
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      width: width * 0.9,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Location',
                              style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 10),
                          SearchBar(
                            controller: startAddressController,
                            focusNode: startAddressFocusNode,
                            label: 'Current Location',
                            hint: 'Select starting point',
                            prefixIcon: const Icon(Icons.looks_one),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: () {
                                startAddressController.text = _currentAddress;
                                setState(() {
                                  _startAddress = _currentAddress;
                                });
                              },
                            ),
                            width: width,
                            onChanged: (value) {
                              setState(() {
                                _startAddress = value;
                              });
                              _placeService.searchPlaces(value, (predictions) {
                                setState(() {
                                  _placeService.startPredictions = predictions;
                                });
                              });
                            },
                            predictions: _placeService.startPredictions,
                            onPredictionTap: (prediction) async {
                              final details = await _placeService
                                  .getPlaceDetails(prediction.placeId!);
                              if (details != null &&
                                  details.result?.geometry?.location != null) {
                                final location =
                                    details.result!.geometry!.location!;
                                final selectedLatLng =
                                    LatLng(location.lat!, location.lng!);
                                startAddressController.text =
                                    prediction.description ?? '';
                                setState(() {
                                  _startAddress = startAddressController.text;
                                  markers.removeWhere(
                                      (m) => m.markerId.value == 'start');
                                  markers.add(
                                    Marker(
                                      markerId: const MarkerId('start'),
                                      position: selectedLatLng,
                                      infoWindow:
                                          const InfoWindow(title: 'Start'),
                                      icon: BitmapDescriptor.defaultMarker,
                                    ),
                                  );
                                  _placeService.startPredictions = [];
                                });
                                if (mapController != null) {
                                  mapController!
                                      .animateCamera(
                                    CameraUpdate.newLatLng(selectedLatLng),
                                  )
                                      .catchError((e) {
                                    print('Error animasi kamera: $e');
                                  });
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          SearchBar(
                            controller: destinationAddressController,
                            focusNode: destinationAddressFocusNode,
                            label: 'Destination',
                            hint: 'Select destination or long press on map',
                            prefixIcon: const Icon(Icons.looks_two),
                            width: width,
                            onChanged: (value) {
                              setState(() {
                                _destinationAddress = value;
                              });
                              _placeService.searchPlaces(value, (predictions) {
                                setState(() {
                                  _placeService.destinationPredictions =
                                      predictions;
                                });
                              });
                            },
                            predictions: _placeService.destinationPredictions,
                            onPredictionTap: (prediction) async {
                              final details = await _placeService
                                  .getPlaceDetails(prediction.placeId!);
                              if (details != null &&
                                  details.result?.geometry?.location != null) {
                                final location =
                                    details.result!.geometry!.location!;
                                final selectedLatLng =
                                    LatLng(location.lat!, location.lng!);
                                destinationAddressController.text =
                                    prediction.description ?? '';
                                setState(() {
                                  _destinationAddress =
                                      destinationAddressController.text;
                                  _destinationLatLng = selectedLatLng;
                                  markers.removeWhere(
                                      (m) => m.markerId.value == 'destination');
                                  markers.add(
                                    Marker(
                                      markerId: const MarkerId('destination'),
                                      position: selectedLatLng,
                                      infoWindow: const InfoWindow(
                                          title: 'Destination'),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueBlue),
                                    ),
                                  );
                                  _placeService.destinationPredictions = [];
                                });
                                if (mapController != null) {
                                  mapController!
                                      .animateCamera(
                                    CameraUpdate.newLatLng(selectedLatLng),
                                  )
                                      .catchError((e) {
                                    print('Error animasi kamera: $e');
                                  });
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          RouteInfo(
                            placeDistance: _placeDistance,
                            placeDuration: _placeDuration,
                          ),
                          const SizedBox(height: 10),
                          RouteSelector(
                            routeOptions: _routeOptions,
                            selectedRouteIndex: _selectedRouteIndex,
                            onRouteSelected: (index) {
                              _routeService.selectRoute(
                                index,
                                _routeOptions,
                                polylineCoordinates,
                                originalPolylineCoordinates,
                                polylines,
                                setState,
                                (distance, duration) {
                                  setState(() {
                                    _placeDistance = distance;
                                    _placeDuration = duration;
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 5),
                          ActionButtons(
                            isCalculatingRoute: _isCalculatingRoute,
                            onShowRoute: () async {
                              startAddressFocusNode.unfocus();
                              destinationAddressFocusNode.unfocus();
                              final success =
                                  await _routeService.calculateDistance(
                                _startAddress,
                                _destinationAddress,
                                _currentAddress,
                                _currentPosition,
                                _destinationLatLng,
                                markers,
                                polylineCoordinates,
                                originalPolylineCoordinates,
                                polylines,
                                _routeOptions,
                                setState,
                                (distance, duration) {
                                  setState(() {
                                    _placeDistance = distance;
                                    _placeDuration = duration;
                                  });
                                },
                                (isCalculating) {
                                  setState(() {
                                    _isCalculatingRoute = isCalculating;
                                  });
                                },
                              );
                              if (success) {
                                startNavigation();
                              } else {
                                print('Gagal menghitung rute');
                              }
                            },
                            onCancelRoute: () {
                              print(
                                  'Membatalkan rute, routeOptions sebelum: ${_routeOptions.length}');
                              _routeService.cancelRoute(
                                polylines,
                                polylineCoordinates,
                                originalPolylineCoordinates,
                                _routeOptions,
                                markers,
                                destinationAddressController,
                                setState,
                                () {
                                  setState(() {
                                    _placeDistance = null;
                                    _placeDuration = null;
                                    _destinationLatLng = null;
                                    _destinationAddress = '';
                                    isNavigating = false;
                                  });
                                },
                              );
                              print(
                                  'Rute dibatalkan, routeOptions sesudah: ${_routeOptions.length}');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // FAB untuk Start/Stop Navigation
                        _isLocationUpdateActive
                            ? FloatingActionButton(
                                heroTag: "stopNavigation",
                                child: const Icon(Icons.stop),
                                backgroundColor: Colors.red,
                                onPressed: _stopLocationUpdates,
                                mini: true,
                              )
                            : FloatingActionButton(
                                heroTag: "startNavigation",
                                child: const Icon(Icons.navigation),
                                backgroundColor: Colors.green,
                                onPressed: _startLocationUpdates,
                                mini: true,
                              ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          heroTag: "zoomIn",
                          child: const Icon(Icons.add),
                          onPressed: () {
                            mapController
                                ?.animateCamera(CameraUpdate.zoomIn())
                                .catchError((e) {
                              print('Error zoom in: $e');
                            });
                          },
                          mini: true,
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          heroTag: "zoomOut",
                          child: const Icon(Icons.remove),
                          onPressed: () {
                            mapController
                                ?.animateCamera(CameraUpdate.zoomOut())
                                .catchError((e) {
                              print('Error zoom out: $e');
                            });
                          },
                          mini: true,
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          heroTag: "myLocation",
                          child: const Icon(Icons.my_location),
                          backgroundColor: Colors.orange,
                          onPressed: _updateCurrentLocation,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isCalculatingRoute)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
