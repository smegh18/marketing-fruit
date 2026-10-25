// Asset path (make sure pubspec.yaml has this registered)
import 'package:flutter/material.dart';

const String kCoinsAsset = 'assets/Coins.png';

class GameCurrencyCard extends StatelessWidget {
  final VoidCallback? onBuyNow;
  final String balanceText; // e.g., "$9.3k"
  final double height;

  const GameCurrencyCard({
    super.key,
    this.onBuyNow,
    this.balanceText = "\$9.3k",
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
              colors: [Color(0xFF22E2C6), Color(0xFF08D9B6)],
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
                          onBuyNow: onBuyNow,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _CoinThumb(imageAssetPath: kCoinsAsset),
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
                        onBuyNow: onBuyNow,
                      ),
                      const Spacer(),
                      const Flexible(child: _CoinThumb(imageAssetPath: kCoinsAsset)),
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
  final VoidCallback? onBuyNow;

  const _LeftBlock({
    required this.titleSize,
    required this.numberSize,
    required this.btnSize,
    required this.balanceText,
    this.onBuyNow,
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
            'Game Currency',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            balanceText,
            style: TextStyle(
              fontSize: numberSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _BuyNowPill(fontSize: btnSize, onTap: onBuyNow),
        ],
      ),
    );
  }
}

class _BuyNowPill extends StatefulWidget {
  final double fontSize;
  final VoidCallback? onTap;
  const _BuyNowPill({required this.fontSize, this.onTap});

  @override
  State<_BuyNowPill> createState() => _BuyNowPillState();
}

class _BuyNowPillState extends State<_BuyNowPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap ?? () => debugPrint('Buy Now tapped'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: widget.fontSize * 1.6,
            vertical: widget.fontSize * 0.55,
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
            'Buy Now',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: widget.fontSize,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinThumb extends StatelessWidget {
  final String imageAssetPath;

  const _CoinThumb({required this.imageAssetPath});

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
