import 'package:flutter/material.dart';

class FinancialSummarySection extends StatelessWidget {
  final double cardHeight;
  final EdgeInsets padding;

  const FinancialSummarySection({
    super.key,
    this.cardHeight = 140,
    // no horizontal padding; full-bleed width
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 20), required double width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double innerWidth = w - padding.horizontal;

        const double gap = 12.0;
        late double cardWidth;
        late MainAxisAlignment rowAlign;

        if (w >= 900) {
          cardWidth = (innerWidth - (2 * gap)) / 3;
          rowAlign = MainAxisAlignment.start;
        } else if (w >= 600) {
          cardWidth = (innerWidth - gap) / 2;
          rowAlign = MainAxisAlignment.start;
        } else {
          cardWidth = innerWidth;
          rowAlign = MainAxisAlignment.start;
        }

        return Container(
          width: double.infinity,
          color: theme.cardColor,
          child: Padding(
            padding: padding, // no left/right padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title without side padding so it aligns with cards
                Text(
                  'Financial Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: cardHeight + 24,
                  width: double.infinity,
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior()
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const PageScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: w),
                        child: Row(
                          mainAxisAlignment: rowAlign,
                          children: [
                            // REMOVED the outer 20px side spacers for full-bleed
                            SizedBox(
                              width: cardWidth,
                              child: _CenteredSummaryTile(
                                label: 'Total Earned (Coins)',
                                valueText: '\$25,240',
                                valueColor: const Color(0xFF22AA52),
                                height: cardHeight,
                              ),
                            ),
                            SizedBox(width: gap),
                            SizedBox(
                              width: cardWidth,
                              child: _CenteredSummaryTile(
                                label: 'Total Spent (Coins)',
                                valueText: '2,693',
                                valueColor: const Color(0xFFDC3A3A),
                                height: cardHeight,
                              ),
                            ),
                            SizedBox(width: gap),
                            SizedBox(
                              width: cardWidth,
                              child: _CenteredSummaryTile(
                                label: 'Net Worth (Coins & Coins)',
                                valueText: '\$31.4k',
                                valueColor: const Color(0xFF2F6EEB),
                                height: cardHeight,
                              ),
                            ),
                            // no trailing spacer
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CenteredSummaryTile extends StatelessWidget {
  final String label;
  final String valueText;
  final Color valueColor;
  final double height;

  const _CenteredSummaryTile({
    required this.label,
    required this.valueText,
    required this.valueColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;

    final Color greySurface =
        dark ? const Color(0xFF2D2F33) : const Color(0xFFF1F3F6);
    final Color border =
        dark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05);

    final TextStyle labelStyle = theme.textTheme.bodyMedium?.copyWith(
          color: theme.hintColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ) ??
        const TextStyle();

    final TextStyle valueStyle = theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: valueColor,
          letterSpacing: 0.2,
        ) ??
        TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: valueColor,
        );

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: greySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: labelStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valueText,
                textAlign: TextAlign.center,
                style: valueStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
