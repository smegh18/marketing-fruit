import 'package:flutter/material.dart';

class ChannelSearchSection extends StatelessWidget {
  final void Function() onChannelCreated;

  const ChannelSearchSection({
    super.key,
    required this.onChannelCreated,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;

    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: onChannelCreated,
            icon: const Icon(Icons.add),
            label: const Text("Add a New Channel"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
