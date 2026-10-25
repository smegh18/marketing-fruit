import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class BuyGemsSection extends StatefulWidget {
  final double width;
  const BuyGemsSection({super.key, required this.width});

  @override
  State<BuyGemsSection> createState() => _BuyGemsSectionState();
}

class _BuyGemsSectionState extends State<BuyGemsSection> {
  double? gemsPerMatic; // how many gems per 1 MATIC (from Firebase)
  StreamSubscription<DatabaseEvent>? _financeSub;

  int? _customGems;
  int? _customPriceMatic;

  @override
  void initState() {
    super.initState();
    _listenRelationFromFirebase();
  }

  void _listenRelationFromFirebase() {
    final ref = FirebaseDatabase.instance.ref("game_finance/row2");
    _financeSub = ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null && data.containsKey("gems2") && data.containsKey("poly")) {
        final gems = (data["gems2"] as num).toDouble();
        final poly = (data["poly"] as num).toDouble();

        if (poly > 0) {
          setState(() {
            gemsPerMatic = gems / poly; // conversion rate
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _financeSub?.cancel();
    super.dispose();
  }

  int _calcGemsForMatic(int matic) {
    if (gemsPerMatic == null) return 0;
    final gems = (matic * gemsPerMatic!).ceil();
    return gems.clamp(1, 999999999);
  }

  String _relationLabel() {
    if (gemsPerMatic == null) return "Loading relation…";
    // Show up to 2 decimal places when needed, otherwise as int
    final value = (gemsPerMatic! % 1 == 0)
        ? gemsPerMatic!.toStringAsFixed(0)
        : gemsPerMatic!.toStringAsFixed(2);
    return "1 MATIC ≈ $value gems";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (gemsPerMatic == null) {
      return SizedBox(
        width: widget.width,
        height: 200,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    // Bundles: price = fixed MATIC, gems calculated dynamically
    final bundles = [
      {'icon': Icons.stars,             'label': 'Starter Pack', 'matic': 99},
      {'icon': Icons.bolt,              'label': 'Value Pack',   'matic': 199},
      {'icon': Icons.diamond,           'label': 'Pro Pack',     'matic': 399},
      {'icon': Icons.workspace_premium, 'label': 'Ultra Pack',   'matic': 799},
    ].map((b) {
      final matic = b['matic'] as int;
      return {
        ...b,
        'gems': _calcGemsForMatic(matic),
      };
    }).toList();

    // === Match BuyGameCurrencySection sizing ===
    final dpi = MediaQuery.of(context).devicePixelRatio;
    double scale = 1.0;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.2;
    } else if (dpi >= 2.0) {
      scale = 0.95;
    }
    final screenH = MediaQuery.of(context).size.height;
    final sectionH = (screenH * 0.42 * scale).clamp(330.0, 520.0);

    return Container(
      width: widget.width,
      height: sectionH,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.width * 0.95,
          height: sectionH * 0.96,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row: heading + live relation chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Buy Gems',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.shade700, width: 0.8),
                      ),
                      child: Text(
                        _relationLabel(),
                        style: GoogleFonts.workSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cards
              Expanded(
                child: widget.width < 800
                    ? ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...bundles.map((b) {
                            return SizedBox(
                              width: 150,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _BundleCardGems(
                                  iconData: b['icon'] as IconData,
                                  label: b['label'] as String,
                                  amountText: '${b['gems']} gems',
                                  priceText: '${b['matic']} MATIC',
                                  iconSize: 36,
                                  onTap: () {
                                    // TODO: purchase/top-up for fixed bundles
                                  },
                                ),
                              ),
                            );
                          }),

                          // Custom Pack
                          SizedBox(
                            width: 150,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _CustomPackCardGems(
                                gemsPerMatic: gemsPerMatic!,
                                initialMatic: _customPriceMatic ?? 0,
                                onApply: (matic) {
                                  final gems = _calcGemsForMatic(matic);
                                  setState(() {
                                    _customPriceMatic = matic;
                                    _customGems = gems;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...bundles.map((b) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _BundleCardGems(
                                  iconData: b['icon'] as IconData,
                                  label: b['label'] as String,
                                  amountText: '${b['gems']} gems',
                                  priceText: '${b['matic']} MATIC',
                                  iconSize: 36,
                                  onTap: () {
                                    // TODO: purchase/top-up for fixed bundles
                                  },
                                ),
                              ),
                            );
                          }),

                          // Custom Pack
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _CustomPackCardGems(
                                gemsPerMatic: gemsPerMatic!,
                                initialMatic: _customPriceMatic ?? 0,
                                onApply: (matic) {
                                  final gems = _calcGemsForMatic(matic);
                                  setState(() {
                                    _customPriceMatic = matic;
                                    _customGems = gems;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleCardGems extends StatelessWidget {
  final IconData iconData;
  final String label;
  final String amountText;
  final String priceText;
  final double iconSize;
  final bool highlight;
  final VoidCallback? onTap;

  const _BundleCardGems({
    required this.iconData,
    required this.label,
    required this.amountText,
    required this.priceText,
    this.iconSize = 28,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor = highlight ? Colors.purple.shade800 : Colors.purple.shade700;
    final chipBg     = highlight ? Colors.purple.shade200 : Colors.purple.shade100;
    final chipFg     = highlight ? Colors.purple.shade900 : Colors.purple.shade700;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
          ],
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple.shade200, width: 1),
              ),
              child: Icon(iconData, size: iconSize, color: borderColor),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amountText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.hintColor.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(8)),
              child: Text(
                priceText,
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: chipFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomPackCardGems extends StatefulWidget {
  final double gemsPerMatic;
  final int initialMatic;
  final void Function(int matic) onApply;

  const _CustomPackCardGems({
    required this.gemsPerMatic,
    required this.onApply,
    this.initialMatic = 0,
  });

  @override
  State<_CustomPackCardGems> createState() => _CustomPackCardGemsState();
}

class _CustomPackCardGemsState extends State<_CustomPackCardGems> {
  late final TextEditingController _maticCtrl;
  late final TextEditingController _gemsCtrl;
  String? _error;

  int get _matic => int.tryParse(_maticCtrl.text.trim()) ?? 0;
  int _calcGems(int matic) =>
      (matic * widget.gemsPerMatic).ceil().clamp(1, 999999999);

  @override
  void initState() {
    super.initState();
    _maticCtrl = TextEditingController(
      text: widget.initialMatic > 0 ? '${widget.initialMatic}' : '',
    );
    _gemsCtrl = TextEditingController(text: '');
    _recompute();
  }

  @override
  void dispose() {
    _maticCtrl.dispose();
    _gemsCtrl.dispose();
    super.dispose();
  }

  void _recompute() {
    final m = _matic;
    if (m <= 0) {
      _gemsCtrl.text = '';
      return;
    }
    _gemsCtrl.text = _calcGems(m).toString();
  }

  void _handleApply() {
    final m = _matic;
    if (m <= 0) {
      setState(() => _error = 'Enter a positive number.');
      return;
    }
    if (m > 99999999) {
      setState(() => _error = 'That is too large. Try a smaller amount.');
      return;
    }
    setState(() => _error = null);
    widget.onApply(m);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = Colors.purple.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.shade200, width: 1),
            ),
            child: Icon(Icons.tune, size: 24, color: borderColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Custom Pack',
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'MATIC',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.hintColor.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            controller: _maticCtrl,
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            placeholder: 'e.g., 100',
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
              setState(_recompute);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gems (≈)',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.hintColor.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            controller: _gemsCtrl,
            enabled: false,
            readOnly: true,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            placeholder: '—',
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final buttonHeight = (constraints.maxHeight * 0.14).clamp(28.0, 44.0);
                  return SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: CupertinoButton.filled(
                      padding: EdgeInsets.symmetric(vertical: buttonHeight * 0.22),
                      borderRadius: BorderRadius.circular(buttonHeight * 0.25),
                      onPressed: _handleApply,
                      child: Text(
                        "Apply",
                        style: TextStyle(
                          fontSize: buttonHeight * 0.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
