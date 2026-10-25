import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistorySection extends StatefulWidget {
  const TransactionHistorySection({super.key, required double width});

  @override
  State<TransactionHistorySection> createState() =>
      _TransactionHistorySectionState();
}

class _TransactionHistorySectionState extends State<TransactionHistorySection> {
  late DateTime _cursor;

  @override
  void initState() {
    super.initState();
    _cursor = DateTime.now();
  }

  void _shiftMonth(int delta) {
    final newMonth = DateTime(_cursor.year, _cursor.month + delta, 1);
    setState(() => _cursor = newMonth);
  }

  void _shiftYear(int delta) {
    final newYear = DateTime(_cursor.year + delta, _cursor.month, 1);
    setState(() => _cursor = newYear);
  }

  String get monthTitle => DateFormat('MMMM yyyy').format(_cursor);

  // Demo rows; replace with real data. Positive -> green, negative -> red.
  List<_TxRow> get rows => const [
        _TxRow('Pro Pack Purchase', '15/09/2025, 16:45:00', -399),
        _TxRow('Sold Item on Marketplace', '10/09/2025, 14:30:00', 300),
        _TxRow('Purchased Starter Pack', '05/09/2025, 11:00:00', -99),
        
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final hint = theme.hintColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, c) {
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Transaction History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hint,
                      ),
                    ),
                    Text(
                      monthTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hint,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Top navigation chips row (left: year/month back, right: month/year forward)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NavChip(
                    label: 'Year',
                    iconLeft: Icons.keyboard_double_arrow_left_rounded,
                    onTap: () => _shiftYear(-1),
                  ),
                  const SizedBox(width: 8),
                  _NavChip(
                    label: 'Month',
                    iconLeft: Icons.keyboard_arrow_left_rounded,
                    onTap: () => _shiftMonth(-1),
                  ),
                  const SizedBox(width: 16),
                  _NavChip(
                    label: 'Month',
                    iconRight: Icons.keyboard_arrow_right_rounded,
                    onTap: () => _shiftMonth(1),
                  ),
                  const SizedBox(width: 8),
                  _NavChip(
                    label: 'Year',
                    iconRight: Icons.keyboard_double_arrow_right_rounded,
                    onTap: () => _shiftYear(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Table header
            _TableHeader(
              cols: const ['TRANSACTION', 'DATE', 'AMOUNT'],
            ),
            const Divider(height: 1),

            // Table rows
            ...rows.map((r) => _TxRowWidget(row: r)),

            // Bottom rounded spacing hint (like screenshot visual)
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final IconData? iconLeft;
  final IconData? iconRight;
  final VoidCallback onTap;

  const _NavChip({
    required this.label,
    required this.onTap,
    this.iconLeft,
    this.iconRight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.canvasColor.withOpacity(0.5);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconLeft != null)
              Icon(iconLeft, size: 18, color: theme.hintColor),
            if (iconLeft != null) const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.hintColor,
              ),
            ),
            if (iconRight != null) const SizedBox(width: 6),
            if (iconRight != null)
              Icon(iconRight, size: 18, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> cols;
  const _TableHeader({required this.cols});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.hintColor,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(cols[0], style: style),
          ),
          Expanded(
            flex: 3,
            child: Text(cols[1], style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(cols[2], style: style),
          ),
        ],
      ),
    );
  }
}

class _TxRow {
  final String title;
  final String date;
  final int amount; // in coins; negative/positive
  const _TxRow(this.title, this.date, this.amount);
}

class _TxRowWidget extends StatelessWidget {
  final _TxRow row;
  const _TxRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = const Color(0xFF22AA52);
    final red = const Color(0xFFDC3A3A);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  row.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  row.date,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor.withOpacity(0.9),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatAmount(row.amount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: row.amount >= 0 ? green : red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  String _formatAmount(int coins) {
    final sign = coins >= 0 ? '+' : '';
    return '$sign$coins coins';
  }
}
