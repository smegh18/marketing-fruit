import 'package:Marketing_Fruit/ecommerce/itemmarketplace.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

/// Convert ipfs://.. to https gateway
String _resolveGraphic(String? graphic) {
  if (graphic == null || graphic.isEmpty) return '';
  if (graphic.startsWith('ipfs://')) {
    final hash = graphic.substring(7);
    return 'https://gateway.pinata.cloud/ipfs/$hash';
  }
  return graphic;
}

enum _SortOrder { newestFirst, oldestFirst }

/// Vertical scrollable "NFT & Crypto" section showing 5 cards per row,
/// with a top-right filter: sort (newest↔oldest) and type filter as tabs below header,
/// and an optional `below` widget rendered under the grid.
class NftAndCryptoSection extends StatefulWidget {
  final double width;
  final void Function(Map<String, dynamic> nft)? onNftTap;

  /// Anything you want to render directly below this section (e.g., another screen).
  /// Example:
  ///   below: const YourExistingScreen(),

  final Widget? below;

  const NftAndCryptoSection({
    super.key,
    required this.width,
    this.onNftTap,
    this.below,
  });

  @override
  State<NftAndCryptoSection> createState() => _NftAndCryptoSectionState();
}

class _NftAndCryptoSectionState extends State<NftAndCryptoSection>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _nfts = [];
  List<Map<String, dynamic>> _visible = [];

  // Filters
  _SortOrder _sortOrder = _SortOrder.newestFirst;
  String _selectedType = 'All';

  late final TabController _tabController;

  final List<String> _tabLabels = ['All', 'Brands', 'Game', 'Sponsor'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = _tabLabels[_tabController.index];
          _applyFilters();
        });
      }
    });
    _fetchNfts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNfts() async {
    try {
      final snap = await FirebaseDatabase.instance.ref('nft').get();
      final list = <Map<String, dynamic>>[];

      if (snap.exists && snap.value is Map) {
        final raw = Map<Object?, Object?>.from(snap.value as Map);
        raw.forEach((key, val) {
          if (val is Map) {
            final m = Map<Object?, Object?>.from(val);

            DateTime? createdAt;
            final ca = m['createdAt'];
            if (ca is int) {
              createdAt = DateTime.fromMillisecondsSinceEpoch(ca, isUtc: false);
            } else if (ca is double) {
              createdAt =
                  DateTime.fromMillisecondsSinceEpoch(ca.toInt(), isUtc: false);
            }

            final typeStr = (m['type'] ?? '').toString();
            list.add({
              'key': key.toString(),
              'name': (m['name'] ?? '').toString(),
              'category': (m['category'] ?? '').toString(),
              'price': m['price'],
              'graphic': _resolveGraphic(m['graphic']?.toString()),
              'type': typeStr,
              'brand': (m['brand'] ?? '').toString(),
              'description': (m['description'] ?? '').toString(),
              'createdAt': createdAt, // may be null
            });
          }
        });
      }

      setState(() {
        _nfts = list;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _nfts = [];
        _visible = [];
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> out = List.of(_nfts);

    // Type filter
    if (_selectedType != 'All') {
      if (_selectedType == 'Brands') {
        // Filter NFTs that have a non-empty brand string
        out = out.where((n) => (n['brand'] ?? '').toString().trim().isNotEmpty).toList();
      } else {
        out = out.where((n) => (n['type'] ?? '') == _selectedType).toList();
      }
    }

    // Sort by createdAt (desc/asc). Fallback to key compare.
    int cmp(Map<String, dynamic> a, Map<String, dynamic> b) {
      final da = a['createdAt'];
      final db = b['createdAt'];
      int result;
      if (da is DateTime && db is DateTime) {
        result = da.compareTo(db);
      } else {
        result = (a['key'] ?? '').toString().compareTo((b['key'] ?? '').toString());
      }
      return _sortOrder == _SortOrder.newestFirst ? -result : result;
    }

    out.sort(cmp);
    _visible = out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and sort dropdown
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "My NFT & Crypto",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.hintColor,
                      ),
                    ),
                    const Spacer(),
                    _SortDropdown(
                      value: _sortOrder,
                      onChanged: (v) {
                        setState(() {
                          _sortOrder = v;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tab bar for type filter below header
                TabBar(
  controller: _tabController,
  labelColor: Color(0xFF4B006E),            // Selected tab text color (dark purple)
  unselectedLabelColor: theme.hintColor.withOpacity(0.6), // Unselected tab color
  indicatorColor: Color(0xFF4B006E),        // (Optional) Indicator color to match
  tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
),

                const SizedBox(height: 16),

                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "No NFTs found",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: theme.hintColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // let page scroll
                    itemCount: _visible.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // exactly 5 cards per row
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 3 / 4, // adjust card shape
                    ),
                    itemBuilder: (_, i) => _nftCard(theme, _visible[i]),
                  ),
              ],
            ),
          ),

          // ---- BELOW SECTION (your other screen) ----
          const SizedBox(height: 24),
          const MarketplaceSection(width: 1600),
        ],
      ),
    );
  }

  Widget _nftCard(ThemeData theme, Map<String, dynamic> nft) {
    final imageUrl = (nft['graphic'] ?? '') as String;
    final name = (nft['name'] ?? '') as String;
    final rawCategory = (nft['category'] ?? '') as String;
    final category =
        rawCategory.isNotEmpty ? rawCategory : (nft['type'] ?? '') as String;
    final price = nft['price'];

    return InkWell(
      onTap: widget.onNftTap == null ? null : () => widget.onNftTap!(nft),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: imageUrl.isEmpty
                    ? Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Untitled NFT' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.isEmpty ? '—' : category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          price == null ? "—" : "$price Pol",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact dropdown for sort order (top-right).
class _SortDropdown extends StatelessWidget {
  final _SortOrder value;
  final ValueChanged<_SortOrder> onChanged;

  const _SortDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: DropdownButton<_SortOrder>(
        value: value,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: const Icon(Icons.unfold_more),
        items: const [
          DropdownMenuItem(
            value: _SortOrder.newestFirst,
            child: Text('Newest to Oldest'),
          ),
          DropdownMenuItem(
            value: _SortOrder.oldestFirst,
            child: Text('Oldest to Newest'),
          ),
        ],
      ),
    );
  }
}
