// Asset path (make sure pubspec.yaml has this registered)
import 'package:flutter/material.dart';

const String kGemsAsset = 'assets/gems.png';

class GemsCard extends StatelessWidget {
  final VoidCallback? onBuyMore;
  final String balanceText; // e.g., "9.3k"
  final double height;

  const GemsCard({
    super.key,
    this.onBuyMore,
    this.balanceText = "9.3k",
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final bool wide = w >= 280;
      final double pad = wide ? 16 : 14;
      final double radius = 18;

      double clamp(double v, double min, double max) => v.clamp(min, max).toDouble();

      final double titleSize = clamp(w * 0.06, 16, 20);
      final double numberSize = clamp(w * 0.08, 20, 28);
      final double btnSize = clamp(w * 0.035, 12, 14);

      return SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF93C2), Color(0xFFFF5E9C)], // pinks
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: wide
                ? Row(
                    children: [
                      Expanded(
                        child: _LeftBlock(
                          titleSize: titleSize,
                          numberSize: numberSize,
                          btnSize: btnSize,
                          balanceText: balanceText,
                          onBuyMore: onBuyMore,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _GemThumb(imageAssetPath: kGemsAsset),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LeftBlock(
                        titleSize: titleSize,
                        numberSize: numberSize,
                        btnSize: btnSize,
                        balanceText: balanceText,
                        onBuyMore: onBuyMore,
                      ),
                      const Spacer(),
                      const Flexible(child: _GemThumb(imageAssetPath: kGemsAsset)),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}

class _LeftBlock extends StatelessWidget {
  final double titleSize;
  final double numberSize;
  final double btnSize;
  final String balanceText;
  final VoidCallback? onBuyMore;

  const _LeftBlock({
    required this.titleSize,
    required this.numberSize,
    required this.btnSize,
    required this.balanceText,
    this.onBuyMore,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gems',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            balanceText,
            style: TextStyle(
              fontSize: numberSize,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          _BuyMorePill(fontSize: btnSize, onTap: onBuyMore),
        ],
      ),
    );
  }
}

class _BuyMorePill extends StatefulWidget {
  final double fontSize;
  final VoidCallback? onTap;
  const _BuyMorePill({required this.fontSize, this.onTap});

  @override
  State<_BuyMorePill> createState() => _BuyMorePillState();
}

class _BuyMorePillState extends State<_BuyMorePill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap ?? () => debugPrint('Buy More Gems tapped'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: widget.fontSize * 1.8,
            vertical: widget.fontSize * 0.6,
          ),
          decoration: BoxDecoration(
            color: _hover ? Colors.black.withOpacity(0.85) : Colors.black,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              if (_hover)
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Text(
            'Buy More Gems',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: widget.fontSize,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _GemThumb extends StatelessWidget {
  final String imageAssetPath;

  const _GemThumb({required this.imageAssetPath});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.7,
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.asset(
            imageAssetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32),
          ),
        ),
      ),
    );
  }
}
