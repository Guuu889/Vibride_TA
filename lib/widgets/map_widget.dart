import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final CameraPosition initialLocation;
  final Set<Marker> markers;
  final Map<PolylineId, Polyline> polylines;
  final Function(GoogleMapController) onMapCreated;
  final Function(LatLng) onLongPress;

  const MapWidget({
    Key? key,
    required this.initialLocation,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
    required this.onLongPress, required bool liteModeEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: initialLocation,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomGesturesEnabled: true,
      zoomControlsEnabled: true,
      polylines: Set<Polyline>.of(polylines.values),
      onMapCreated: onMapCreated,
      onLongPress: onLongPress,
    );
  }
}