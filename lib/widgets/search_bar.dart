import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart' as gp;

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final Icon prefixIcon;
  final Widget? suffixIcon;
  final double width;
  final Function(String) onChanged;
  final List<gp.AutocompletePrediction> predictions;
  final Function(gp.AutocompletePrediction) onPredictionTap;

  const SearchBar({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    required this.width,
    required this.onChanged,
    required this.predictions,
    required this.onPredictionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: width * 0.8,
          child: TextField(
            onChanged: onChanged,
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
              ),
              contentPadding: const EdgeInsets.all(15),
              hintText: hint,
            ),
          ),
        ),
        if (predictions.isNotEmpty)
          Container(
            width: width * 0.8,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListView.builder(
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(predictions[index].description ?? ''),
                  onTap: () => onPredictionTap(predictions[index]),
                );
              },
            ),
          ),
      ],
    );
  }
}