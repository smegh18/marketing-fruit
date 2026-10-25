import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Resolve ipfs://… to https gateway for display
String _resolveGraphic(String? graphic) {
  if (graphic == null || graphic.isEmpty) return '';
  if (graphic.startsWith('ipfs://')) {
    final hash = graphic.substring(7);
    return 'https://gateway.pinata.cloud/ipfs/$hash';
  }
  return graphic;
}

class MarketplaceSection extends StatelessWidget {
  final double width;
  const MarketplaceSection({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dpi = MediaQuery.of(context).devicePixelRatio;

    double scale = 1.0;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.4;
    } else if (dpi >= 2.0) {
      scale = 0.9;
    }

    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    final height = isMacOS
        ? MediaQuery.of(context).size.height * 0.55 * scale
        : MediaQuery.of(context).size.height * 0.5 * scale;

    final user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: width * 0.97,
          height: height * 0.97,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                child: Row(
                  children: [
                    Text(
                      'Your Items on Marketplace',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.hintColor,
                      ),
                    ),
                    const Spacer(),
                    // Optional: add global "Sell NFT" button if you want
                    // _buildSellButton(context),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Your items (dynamic) + trailing "Sell NFT" card
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<DatabaseEvent>(
                        stream: uid == null
                            ? null
                            : FirebaseDatabase.instance
                                .ref('marketplace/items/$uid')
                                .onValue,
                        builder: (context, snapshot) {
                          if (uid == null) {
                            return _emptyState(
                              context,
                              title: 'Not signed in',
                              subtitle: 'Sign in to see your marketplace items.',
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final data = snapshot.data?.snapshot.value;
                          if (data == null || (data is Map && data.isEmpty)) {
                            // No items yet — show only Sell card centered
                            return ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              children: [
                                _buildSellCard(context),
                              ],
                            );
                          }

                          final items = <Map<String, dynamic>>[];
                          if (data is Map) {
                            data.forEach((key, value) {
                              if (value is Map) {
                                final m = Map<Object?, Object?>.from(value);
                                items.add({
                                  'key': key,
                                  'name': m['name']?.toString() ?? '',
                                  'price': m['price']?.toString() ?? '',
                                  'graphic': m['graphic']?.toString() ?? '',
                                  'category': m['category']?.toString() ?? '',
                                });
                              }
                            });
                          }

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: items.length + 1, // +1 for Sell card at end
                            itemBuilder: (ctx, i) {
                              if (i == items.length) {
                                return _buildSellCard(context);
                              }
                              final item = items[i];
                              final itemKey = (item['key'] ?? '').toString();

                              return _buildItemCard(
                                ctx,
                                title: item['name'] ?? '',
                                number: '#${i + 1}',
                                description: 'Listed NFT • Tap to view',
                                price: item['price'] ?? '',
                                graphic: item['graphic'] ?? '',
                                isMac: isMacOS,
                                scale: scale,
                                uid: uid,
                                itemKey: itemKey,
                              );
                            },
                          );
                        },
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

  // ---------- UI bits ----------

  Widget _emptyState(BuildContext context, {required String title, required String subtitle}) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 48, color: theme.hintColor.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: theme.hintColor)),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 14, color: theme.hintColor.withOpacity(0.8))),
          const SizedBox(height: 16),
          _buildSellButton(context),
        ],
      ),
    );
  }

  Widget _buildSellButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _openSellDialog(context),
      icon: const Icon(Icons.sell_outlined),
      label: const Text('Sell NFT'),
    );
  }

  Widget _buildSellCard(BuildContext context) {
    return Container(
      width: Theme.of(context).platform == TargetPlatform.macOS ? 200 : 260,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openSellDialog(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.sell_outlined, size: 30, color: Colors.blueGrey),
              SizedBox(height: 10),
              Text(
                "Sell NFT",
                style: TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context, {
    required String title,
    required String number,
    required String description,
    required String price,
    required String graphic,
    required bool isMac,
    required double scale,
    required String uid,
    required String itemKey,
  }) {
    final theme = Theme.of(context);
    final w = isMac ? 200.0 : 260.0;
    final h = isMac
        ? MediaQuery.of(context).size.height * 0.28 * scale
        : MediaQuery.of(context).size.height * 0.3 * scale;

    final imgUrl = _resolveGraphic(graphic);

    return Container(
      width: w,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area + delete icon overlay
          Stack(
            children: [
              Container(
                height: h * 0.45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF1F3F5),
                  image: imgUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(imgUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                alignment: Alignment.center,
                child: imgUrl.isEmpty ? const Icon(Icons.image_not_supported_outlined) : null,
              ),
              // DELETE ICON (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _confirmAndDelete(context, uid, itemKey, title),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Item $number", style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.4),
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 8),
          Text('Price: $price', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------- Delete helpers ----------

  Future<void> _confirmAndDelete(
    BuildContext context,
    String uid,
    String itemKey,
    String title,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline),
            const SizedBox(width: 8),
            const Text('Remove listing?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$title" from your marketplace listings?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseDatabase.instance
          .ref('marketplace/items/$uid/$itemKey')
          .remove();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing removed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  // ---------- Sell Dialog ----------

  Future<void> _openSellDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      // Not signed in
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign in required'),
          content: const Text('Please sign in to list an NFT for sale.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    Map<String, dynamic>? selectedNft;
    final TextEditingController priceCtrl = TextEditingController(text: '');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: theme.cardColor,
              contentPadding: EdgeInsets.zero,
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              title: Row(
                children: [
                  Text('Sell NFT', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: 760,
                height: 420,
                child: Row(
                  children: [
                    // LEFT: NFT list
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.dialogBackgroundColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Choose NFT', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: StreamBuilder<DatabaseEvent>(
                                stream: FirebaseDatabase.instance.ref('nft').onValue,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final data = snapshot.data?.snapshot.value;
                                  final list = <Map<String, dynamic>>[];

                                  if (data is Map) {
                                    data.forEach((key, value) {
                                      if (value is Map) {
                                        final m = Map<Object?, Object?>.from(value);
                                        list.add({
                                          'key': key,
                                          'name': m['name']?.toString() ?? '',
                                          'graphic': m['graphic']?.toString() ?? '',
                                          'category': m['category']?.toString() ?? '',
                                          'price': m['price']?.toString() ?? '', // old price from collection
                                        });
                                      }
                                    });
                                  }

                                  if (list.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No NFTs found.',
                                        style: GoogleFonts.poppins(color: theme.hintColor),
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    itemCount: list.length,
                                    separatorBuilder: (_, __) => Divider(color: theme.dividerColor.withOpacity(0.4)),
                                    itemBuilder: (c, i) {
                                      final nft = list[i];
                                      final imgUrl = _resolveGraphic(nft['graphic']);
                                      final isSelected = selectedNft != null && selectedNft!['key'] == nft['key'];

                                      return ListTile(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        selected: isSelected,
                                        selectedTileColor: theme.highlightColor.withOpacity(0.12),
                                        onTap: () {
                                          setState(() {
                                            selectedNft = nft;
                                            // Prefill with collection price if available
                                            final old = (nft['price'] ?? '').toString();
                                            priceCtrl.text = old;
                                          });
                                        },
                                        leading: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: const Color(0xFFF1F3F5),
                                            image: imgUrl.isEmpty
                                                ? null
                                                : DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
                                          ),
                                          alignment: Alignment.center,
                                          child: imgUrl.isEmpty ? const Icon(Icons.image_not_supported_outlined) : null,
                                        ),
                                        title: Text(nft['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                        subtitle: Text(
                                          nft['category']?.toString().isEmpty ?? true
                                              ? (nft['price']?.toString().isEmpty ?? true ? '' : 'Old price: ${nft['price']}')
                                              : '${nft['category']} • ${nft['price']?.toString().isEmpty ?? true ? '—' : 'Old price: ${nft['price']}'}',
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // RIGHT: Selected NFT + price
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.dialogBackgroundColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
                        ),
                        child: selectedNft == null
                            ? Center(
                                child: Text('Select an NFT to list', style: GoogleFonts.poppins(color: theme.hintColor)),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Selected NFT', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  _SelectedPreview(
                                    nft: selectedNft!,
                                    oldPrice: (selectedNft!['price'] ?? '').toString(), // show old price here
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Set Sale Price', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: priceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 19.99',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () async {
                                        final price = priceCtrl.text.trim();
                                        if (price.isEmpty) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            const SnackBar(content: Text('Please enter a price')),
                                          );
                                          return;
                                        }
                                        await _sellSelectedNft(uid, selectedNft!, price);
                                        if (ctx.mounted) Navigator.pop(ctx); // close dialog
                                      },
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Sell'),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sellSelectedNft(String uid, Map<String, dynamic> nft, String price) async {
    final ref = FirebaseDatabase.instance.ref('marketplace/items/$uid/${nft['key']}');
    await ref.set({
      'name': nft['name'] ?? '',
      'graphic': nft['graphic'] ?? '',
      'category': nft['category'] ?? '',
      'price': price,
      'sellerUid': uid,
      'listedAt': ServerValue.timestamp,
      // Optional: keep reference to collection price / original price
      'originalPrice': (nft['price'] ?? '').toString(),
      // 'status': 'active',
    });
  }
}

class _SelectedPreview extends StatelessWidget {
  final Map<String, dynamic> nft;
  final String? oldPrice; // optional old price from collection
  const _SelectedPreview({required this.nft, this.oldPrice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final img = _resolveGraphic(nft['graphic']?.toString());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF1F3F5),
            image: img.isEmpty ? null : DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
          ),
          alignment: Alignment.center,
          child: img.isEmpty ? const Icon(Icons.image_not_supported_outlined) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nft['name'] ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700, color: theme.hintColor)),
              const SizedBox(height: 4),
              Text(nft['category'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 12, color: theme.hintColor.withOpacity(0.8))),
              if ((oldPrice ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Old price: $oldPrice',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
