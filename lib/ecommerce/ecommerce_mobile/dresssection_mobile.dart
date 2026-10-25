
// dress_screen_mobile.dart
import 'package:flutter/material.dart';

/// Mobile section: "Browse by Dress Style"
/// - Designed to be embedded inside a scrollable parent (e.g., HomeScreenMobile).
/// - No Scaffold/SafeArea/inner scrolling here.
/// - Handle taps via [onCategoryTap].
class DressScreenMobile extends StatelessWidget {
  final void Function(String category)? onCategoryTap;

  const DressScreenMobile({super.key, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final pad = w * 0.06;
    final titleSize = _clamp(w * 0.075, 18, 26);

    final items = const <_DressItem>[
      _DressItem('Casual', 'assets/casual.png'),
      _DressItem('Formal', 'assets/formal.png'),
      _DressItem('Party',  'assets/party.png'),
      _DressItem('Gym',    'assets/gym.png'),
    ];

    // ✅ No Scaffold. This container fits neatly inside the outer scroll view.
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Text(
            'BROWSE BY\nDRESS STYLE',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Vertical list of category tiles
          ...items.map(
                (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryTile(
                item: i,
                onTap: () => onCategoryTap?.call(i.title),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _clamp(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}

class _CategoryTile extends StatelessWidget {
  final _DressItem item;
  final VoidCallback? onTap;

  const _CategoryTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: _clamp(w * 0.34, 96, 120), // responsive height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Left title
              Expanded(
                flex: 45,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Right image (rounded, fills height area)
              Expanded(
                flex: 55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      item.assetPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _clamp(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}

class _DressItem {
  final String title;
  final String assetPath;
  const _DressItem(this.title, this.assetPath);
}
