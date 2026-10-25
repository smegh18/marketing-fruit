import 'package:flutter/material.dart';

class PublishSection extends StatelessWidget {
  final VoidCallback onPublish;
  final String? pendingEventId;
  final List<Map<String, dynamic>> Function()? nftListGetter;

  const PublishSection({
    super.key,
    required this.onPublish,
    this.pendingEventId,
    this.nftListGetter,
  });

  @override
  Widget build(BuildContext context) {
    final nftList = nftListGetter != null ? nftListGetter!() : [];

    // If no event pending, show info
    if (pendingEventId == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text("No pending event to publish.")),
      );
    }

    // NOTE: You may want to also display event data here.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Publish Event', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "Review all details before publishing. Once published, your event will be visible to all users.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // ========= NFT PREVIEW SECTION ===========
            const Text('Minted NFTs:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            nftList.isEmpty
                ? Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('No NFTs minted for this event.', style: TextStyle(color: Colors.grey[600])),
            )
                : Column(
              children: nftList.map((nft) => _NFTPreviewCard(nft)).toList(),
            ),

            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onPublish,
                icon: const Icon(Icons.publish),
                label: const Text('Publish Event'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== NFT PREVIEW CARD ===========
class _NFTPreviewCard extends StatelessWidget {
  final Map<String, dynamic> nft;
  const _NFTPreviewCard(this.nft);

  String _validityString(int? validitySec) {
    if (validitySec == null || validitySec == 0) return 'Unlimited';
    try {
      final expiry = DateTime.fromMillisecondsSinceEpoch(validitySec * 1000);
      return '${expiry.day.toString().padLeft(2, '0')}-${expiry.month.toString().padLeft(2, '0')}-${expiry.year}';
    } catch (_) {
      return validitySec.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = nft['name'] ?? '';
    final desc = nft['description'] ?? '';
    final type = nft['type'] ?? '';
    final category = nft['category'] ?? '';
    final brand = nft['brand'] ?? '';
    final benefit = nft['benefit'] ?? '';
    final value = nft['value']?.toString() ?? '';
    final graphic = nft['graphic'] ?? '';
    final price = nft['price']?.toString() ?? '';
    final quantity = nft['quantity']?.toString() ?? '';
    final validity = nft['validity'] is int ? _validityString(nft['validity']) : '';
    final tokenId = nft['tokenId']?.toString() ?? '';
    final active = nft['active'] == true ? 'Active' : 'Inactive';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (graphic.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      graphic,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Text('ID: $tokenId', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 5),
            Text(desc, style: const TextStyle(fontSize: 15)),
            if (brand.isNotEmpty || category.isNotEmpty || type.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Type: $type${category.isNotEmpty ? " | $category" : ""}${brand.isNotEmpty ? " | $brand" : ""}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Benefit: $benefit', style: const TextStyle(fontSize: 13)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Value: $value  |  Amount: $quantity  |  Price: $price', style: const TextStyle(fontSize: 13)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Validity: $validity  |  Status: $active', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
