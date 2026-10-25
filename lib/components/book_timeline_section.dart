import 'package:flutter/material.dart';

class BookTimelineSection extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  const BookTimelineSection({
    super.key,
    required this.currentStep,
    required this.steps,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Books List Timeline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                for (int i = 0; i < steps.length; i++) ...[
                  _StepItem(
                    stepNumber: (i + 1).toString(),
                    label: steps[i],
                    isActive: i == currentStep,
                    isCompleted: i < currentStep,
                  ),
                  if (i != steps.length - 1)
                    const Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String stepNumber;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepItem({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Color fillColor = isActive
        ? Colors.blue
        : isCompleted
        ? Colors.green
        : Colors.white;
    Color textColor = isActive || isCompleted ? Colors.white : Colors.black;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: fillColor,
          child: Text(
            stepNumber,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.black
                : isCompleted
                ? Colors.green
                : Colors.grey,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
