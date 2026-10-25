// customer_screen_mobile.dart
import 'package:flutter/material.dart';

class CustomerScreenMobile extends StatefulWidget {
  /// Optionally pass your own reviews. If null, defaults are used.
  final List<CustomerReview>? reviews;
  const CustomerScreenMobile({super.key, this.reviews});

  @override
  State<CustomerScreenMobile> createState() => _CustomerScreenMobileState();
}

class _CustomerScreenMobileState extends State<CustomerScreenMobile> {
  late final PageController _pageCtrl;
  int _index = 0;

  List<CustomerReview> get _items =>
      widget.reviews ??
      const [
        CustomerReview(
          name: 'Sarah M.',
          review:
              "I'm blown away by the quality and style of the clothes I received from Shop.co. "
              "From casual wear to elegant dresses, every piece I've bought has exceeded my expectations.",
          rating: 5,
          verified: true,
        ),
        CustomerReview(
          name: 'Alex K.',
          review:
              "Finding clothes that align with my personal style used to be a challenge until I discovered Shop.co. "
              "The range of options they offer is truly remarkable.",
          rating: 5,
          verified: true,
        ),
        CustomerReview(
          name: 'James L.',
          review:
              "As someone who's always on the lookout for unique fashion pieces, I'm thrilled to have stumbled upon Shop.co. "
              "The selection is diverse and on-point with the latest trends.",
          rating: 5,
          verified: true,
        ),
        CustomerReview(
          name: 'Mona R.',
          review:
              "Absolutely in love with Shop.co! Their quality, delivery, and designs are just top-notch. "
              "Will definitely shop again.",
          rating: 5,
          verified: true,
        ),
        CustomerReview(
          name: 'Liam P.',
          review:
              "Was skeptical at first, but Shop.co delivered on every front. Great experience!",
          rating: 5,
          verified: true,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, _items.length - 1);
    if (next == _index) return;
    _pageCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final pad = w * 0.06;
    final headlineSize = _clamp(w * 0.09, 22, 28);

    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + arrows
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'OUR HAPPY\nCUSTOMERS',
                    style: TextStyle(
                      fontSize: headlineSize,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _ArrowButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => _go(-1),
                      enabled: _index > 0,
                    ),
                    const SizedBox(width: 6),
                    _ArrowButton(
                      icon: Icons.arrow_forward_ios,
                      onTap: () => _go(1),
                      enabled: _index < _items.length - 1,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Carousel
            SizedBox(
              height: 210, // good mobile height; adjust if needed
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _ReviewCard(item: _items[i]),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Dots indicator
            Center(
              child: Wrap(
                spacing: 6,
                children: List.generate(
                  _items.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 6,
                    width: i == _index ? 18 : 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Colors.black
                          : Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

class _ReviewCard extends StatelessWidget {
  final CustomerReview item;
  const _ReviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quoteStyle = theme.textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF6B6B6B),
      height: 1.35,
    );

    return Container
    (
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars row
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < item.rating ? Icons.star : Icons.star_border,
                size: 18,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name + verified
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (item.verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 16, color: Colors.green),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Review (quoted feel)
          Expanded(
            child: Text(
              '“${item.review}”',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: quoteStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Icon(icon, size: 16, color: Colors.black),
        ),
      ),
    );
  }
}

/// Simple model for a review item.
class CustomerReview {
  final String name;
  final String review;
  final int rating; // 1..5
  final bool verified;

  const CustomerReview({
    required this.name,
    required this.review,
    this.rating = 5,
    this.verified = false,
  });
}
