  import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isCalculatingRoute;
  final VoidCallback onShowRoute;
  final VoidCallback onCancelRoute;

  const ActionButtons({
    Key? key,
    required this.isCalculatingRoute,
    required this.onShowRoute,
    required this.onCancelRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: isCalculatingRoute ? null : onShowRoute,
          child: Text(isCalculatingRoute
              ? 'Menghitung...'
              : 'Tampilkan Rute'.toUpperCase()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onCancelRoute,
          child: Text('Cancel Rute'.toUpperCase()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 20,
            ),
          ),
        ),
      ],
    );
  }
}