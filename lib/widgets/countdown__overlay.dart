import 'package:flutter/material.dart';

class CountdownOverlay extends StatelessWidget {

  final int countdown;
  final VoidCallback onCancel;

  const CountdownOverlay({
    super.key,
    required this.countdown,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Sending SOS in $countdown",
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onCancel,
                  child: const Text("Cancel"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}