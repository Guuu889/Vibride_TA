import 'package:flutter/material.dart';

class RouteSelector extends StatelessWidget {
  final List<Map<String, dynamic>> routeOptions;
  final int selectedRouteIndex;
  final Function(int) onRouteSelected;

  const RouteSelector({
    Key? key,
    required this.routeOptions,
    required this.selectedRouteIndex,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (routeOptions.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Rute:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                routeOptions.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ElevatedButton(
                    onPressed: () => onRouteSelected(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedRouteIndex == index ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Rute ${index + 1}: ${routeOptions[index]['distance'].toStringAsFixed(2)} km, ${routeOptions[index]['duration']} menit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}