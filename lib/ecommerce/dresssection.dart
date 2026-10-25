import 'package:flutter/material.dart';

class DressStyleSection extends StatelessWidget {
  const DressStyleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = Theme.of(context).platform == TargetPlatform.macOS;

    final containerWidth = screenWidth * 0.77;
    final containerHeight = screenHeight * 0.6;

    return Center(
      child: Container(
        width: containerWidth,
        height: containerHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'BROWSE BY DRESS STYLE',
              style: TextStyle(
                fontSize: isSmall ? 20 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  // Top row: Casual (smaller) + Formal (larger)
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          flex: 4, // 40% width
                          child: _buildCategoryBox(
                            title: 'Casual',
                            assetPath: 'assets/casual.png',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 6, // 60% width
                          child: _buildCategoryBox(
                            title: 'Formal',
                            assetPath: 'assets/formal.png',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bottom row: Party (larger) + Gym (smaller)
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          flex: 6, // 60% width
                          child: _buildCategoryBox(
                            title: 'Party',
                            assetPath: 'assets/party.png',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 4, // 40% width
                          child: _buildCategoryBox(
                            title: 'Gym',
                            assetPath: 'assets/gym.png',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBox({
    required String title,
    required String assetPath,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              assetPath,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  backgroundColor: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
