
// rating_screen_mobile.dart
import 'package:flutter/material.dart';

class RatingScreenMobile extends StatefulWidget {
  /// Provide your own reviews or use the defaults below.
  final List<Review>? reviews;

  /// Called when user taps "Write a Review".
  final VoidCallback? onWriteReview;

  const RatingScreenMobile({super.key, this.reviews, this.onWriteReview});

  @override
  State<RatingScreenMobile> createState() => _RatingScreenMobileState();
}

class _RatingScreenMobileState extends State<RatingScreenMobile> {
  /// 0: Product Details, 1: Rating & Reviews, 2: FAQs
  int _tab = 1; // default to "Rating & Reviews"

  List<Review> get _items => widget.reviews ??
      const [
        Review(
          name: 'Samantha D.',
          rating: 4.5,
          verified: true,
          content:
          "I absolutely love this t-shirt! The design is unique and the fabric feels so comfortable. As a fellow designer, I appreciate the attention to detail. It's become my favorite go-to shirt.",
          date: 'August 14, 2023',
        ),
        Review(
          name: 'Alex M.',
          rating: 5.0,
          verified: true,
          content:
          "The t-shirt exceeded my expectations! The colors are vibrant and the print quality is top-notch. Being a UI/UX designer myself, I'm quite picky about aesthetics, and this t-shirt definitely gets a thumbs up from me.",
          date: 'August 15, 2023',
        ),
        Review(
          name: 'Ethan R.',
          rating: 4.5,
          verified: true,
          content:
          "This t-shirt is a must-have for anyone who appreciates good design. The minimalistic yet stylish pattern caught my eye, and the fit is perfect. I can see the designer's touch in every aspect of this shirt.",
          date: 'August 16, 2023',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final pad = w * 0.06;
    final titleSize = _clamp(w * 0.045, 14, 18);

    // ✅ No Scaffold/inner scroll. This is a simple block for your outer scroll view.
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Tabs(
            current: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 14),

          if (_tab == 0) ...[
            _ProductDetailsCard(),
          ] else if (_tab == 1) ...[
            _HeaderRow(
              countLabel: 'All Reviews (451)',
              onWrite: widget.onWriteReview,
            ),
            const SizedBox(height: 12),

            // Non-scrollable so the OUTER page scrolls.
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ReviewCard(item: _items[i]),
            ),

            const SizedBox(height: 16),

            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  // TODO: paginate/load more or navigate to full reviews page
                },
                child: const Text('Load More Reviews'),
              ),
            ),
          ] else ...[
            _FaqsPlaceholder(titleSize: titleSize),
          ],
        ],
      ),
    );
  }
}

/// ------------------ Tabs ------------------
/// Uses Wrap so long labels naturally move to the next line on tight widths.
class _Tabs extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const tabs = ['Product Details', 'Rating & Reviews', 'FAQs'];

    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: List.generate(tabs.length, (i) {
        final active = i == current;
        return InkWell(
          onTap: () => onChanged(i),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.black : const Color(0xFF8C8C8C),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: active ? 28 : 0,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// --------------- Header row ----------------
/// Responsive: on narrow widths it AUTOMATICALLY moves the action chips
/// below the "All Reviews" text (no overflow).
class _HeaderRow extends StatelessWidget {
  final String countLabel;
  final VoidCallback? onWrite;
  const _HeaderRow({required this.countLabel, this.onWrite});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 420; // tweak threshold if needed

        final left = Text(
          countLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SortChip(),
            _WriteButton(onWrite: onWrite),
          ],
        );

        if (isNarrow) {
          // Stack vertically to avoid overflow.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              const SizedBox(height: 10),
              actions,
            ],
          );
        }

        // Wide: keep a single row with space between.
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: left),
            actions,
          ],
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE6E6E6)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune, size: 16),
          SizedBox(width: 6),
          Text('Latest', style: TextStyle(fontSize: 12)),
          SizedBox(width: 2),
          Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }
}

class _WriteButton extends StatelessWidget {
  final VoidCallback? onWrite;
  const _WriteButton({this.onWrite});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      onPressed: onWrite,
      child: const Text('Write a Review', style: TextStyle(fontSize: 12)),
    );
  }
}

/// --------------- Review card ----------------
class _ReviewCard extends StatelessWidget {
  final Review item;
  const _ReviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stars(rating: item.rating),
              const Spacer(),
              const Icon(Icons.more_horiz, size: 18),
            ],
          ),
          const SizedBox(height: 8),

          // Name + verified
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              if (item.verified)
                const Icon(Icons.verified, size: 16, color: Colors.green),
            ],
          ),
          const SizedBox(height: 8),

          // Review body
          Text(
            '“${item.content}”',
            style: const TextStyle(color: Color(0xFF6B6B6B), height: 1.35),
          ),
          const SizedBox(height: 12),

          // Date
          Text('Posted on ${item.date}',
              style:
              const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
        ],
      ),
    );
  }
}

/// --------------- Product details placeholder ---------------
class _ProductDetailsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Text("Product details content…",
          style: TextStyle(height: 1.4)),
    );
  }
}

/// --------------- FAQs placeholder ---------------
class _FaqsPlaceholder extends StatelessWidget {
  final double titleSize;
  const _FaqsPlaceholder({required this.titleSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text("FAQs will be displayed here…",
          style: TextStyle(fontSize: titleSize)),
    );
  }
}

/// --------------- Stars widget (supports halves) ---------------
class _Stars extends StatelessWidget {
  final double rating; // 0..5
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star, size: 18, color: Colors.amber);
        } else if (i == full && half) {
          return const Icon(Icons.star_half, size: 18, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 18, color: Colors.amber);
        }
      }),
    );
  }
}

/// --------------- Model ---------------
class Review {
  final String name;
  final String content;
  final String date; // formatted string
  final double rating; // 0..5 (supports halves)
  final bool verified;

  const Review({
    required this.name,
    required this.content,
    required this.date,
    required this.rating,
    this.verified = false,
  });
}

/// --- helpers ---
double _clamp(double v, double min, double max) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}
