import 'package:flutter/material.dart';

class RouteInfo extends StatelessWidget {
  final String? placeDistance;
  final String? placeDuration;

  const RouteInfo({
    Key? key,
    required this.placeDistance,
    required this.placeDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (placeDistance != null)
          Text(
            'Jarak: $placeDistance km',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (placeDuration != null)
          Text(
            'Estimasi Waktu: $placeDuration',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}