import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as quill_delta;
import 'package:Marketing_Fruit/components/glasspopup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show GoogleMap, Marker, CameraPosition, LatLng, MapType, MarkerId, InfoWindow;
import 'package:firebase_database/firebase_database.dart';

class EventOverviewSection extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final void Function(Map<String, dynamic> nftData)? onNFTCardTap;

  const EventOverviewSection({
    super.key,
    required this.eventData,
    this.onNFTCardTap,
  });

  @override
  State<EventOverviewSection> createState() => _EventOverviewSectionState();
}

class _EventOverviewSectionState extends State<EventOverviewSection> {
  late Future<List<Map<String, dynamic>>> _futureEventNFTs;

  @override
  void initState() {
    super.initState();
    _futureEventNFTs = _fetchEventNFTs();
  }

  Future<List<Map<String, dynamic>>> _fetchEventNFTs() async {
    final ref = FirebaseDatabase.instance.ref('nft');
    final snap = await ref.get();
    if (!snap.exists || snap.value is! Map) return [];
    final organizer = (widget.eventData['organizer']?.toString() ?? '').trim().toLowerCase();
    final Map raw = snap.value as Map;
    final List<Map<String, dynamic>> nfts = [];
    raw.forEach((key, value) {
      if (value is Map) {
        final nft = Map<String, dynamic>.from(value);
        final brand = nft['brand']?.toString().trim().toLowerCase() ?? '';
        if (brand.isNotEmpty && brand == organizer) {
          nft['id'] = key; // include id for navigation
          nfts.add(nft);
        }
      }
    });
    return nfts;
  }

  @override
  Widget build(BuildContext context) {
    final eventData = widget.eventData;
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.hintColor;
    final subtitleColor = theme.hintColor.withOpacity(0.7);

    // Build attendees (LinkedIn or email)
    final attendees = (eventData['vipList'] is List)
        ? (eventData['vipList'] as List)
            .whereType<Map>()
            .map((e) => e['linkedin']?.toString() ?? e['email']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

    // Date & time from ms epoch
    String dateStr = '';
    if (eventData['start'] != null) {
      final ms = (eventData['start'] is int)
          ? eventData['start'] as int
          : int.tryParse(eventData['start'].toString()) ?? 0;
      if (ms > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ms);
        dateStr =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
            "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
    }

    final String place =
        eventData['placeFields']?['Venue Name'] ?? eventData['location'] ?? '';
    final String locationLink = eventData['mapsLink'] ?? '';
    final String shareLink = eventData['shareLink'] ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cardCountPerRow = (w < 600)
            ? 1
            : (w < 900)
                ? 2
                : (w < 1200)
                    ? 3
                    : 4;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event Overview',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (dateStr.isNotEmpty) _buildIconChip(context, Icons.calendar_today, dateStr),
                  if (place.isNotEmpty) _buildIconChip(context, Icons.location_on, place),
                ],
              ),
              const SizedBox(height: 24),

              if (eventData['eventDescription'] != null || eventData['description'] != null) ...[
                Text('About the Event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: textColor)),
                const SizedBox(height: 8),
                _buildDescriptionWidget(context, eventData['eventDescription'] ?? eventData['description']),
                const SizedBox(height: 24),
              ],

              if (eventData['targetAudiences'] is List && (eventData['targetAudiences'] as List).isNotEmpty) ...[
                Text('Target Audience', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (eventData['targetAudiences'] as List).map((a) {
                    final text = a is Map ? "${a['category'] ?? ''} - ${a['audience'] ?? ''}" : a.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.withOpacity(0.5)),
                      ),
                      child: Text(text, style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              _locationRow(context, locationLink),

              if (attendees.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Attendees:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
                ),
                const SizedBox(height: 8),
                ...attendees.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: _buildLinkedInLink(link),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _infoRow(context, 'Share (event link)', shareLink),

              const Divider(height: 30, thickness: 1),
              const SizedBox(height: 8),
              Text(
                'Event NFT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5, color: textColor),
              ),
              const SizedBox(height: 16),

              // NFTs
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureEventNFTs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text("Error loading NFTs", style: TextStyle(color: Colors.red));
                  }
                  final eventNFTs = snapshot.data ?? [];
                  if (eventNFTs.isEmpty) {
                    return Text(
                      "No branded NFTs found for this event.",
                      style: TextStyle(color: Colors.grey[600]),
                    );
                  }
                  return _buildNFTGrid(
                    eventNFTs,
                    cardCountPerRow,
                    constraints.maxWidth,
                    context,
                    widget.onNFTCardTap,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.purpleAccent),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.9), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: theme.hintColor)),
          const SizedBox(height: 4),
          SelectableText(value, style: TextStyle(fontSize: 15, color: theme.hintColor.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _infoRowWidget(BuildContext context, String label, Widget child) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: theme.hintColor)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _locationRow(BuildContext context, String mapsLink) {
    if (mapsLink.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: OutlinedButton.icon(
        onPressed: () {
          final latLng = _extractLatLngFromMapsLink(mapsLink);
          if (latLng != null) {
            _openMapGlassDialog(
              lat: latLng.latitude,
              lng: latLng.longitude,
              mapsUrl: mapsLink,
            );
          } else {
            final uri = Uri.tryParse(mapsLink);
            if (uri != null) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        icon: const Icon(Icons.map, size: 18),
        label: const Text('View on Map'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blueAccent,
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLinkedInLink(String link) {
    if (link.isEmpty) return const SizedBox.shrink();
    String url = link.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('linkedin.com')) url = "https://$url";
    }
    final isUrl = url.startsWith('http');
    return isUrl
        ? GestureDetector(
            onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            child: Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 15),
            ),
          )
        : Text(link, style: const TextStyle(color: Colors.blue, fontSize: 15));
  }

  /// Quill description renderer with safe sizing & read-only
  Widget _buildDescriptionWidget(BuildContext context, dynamic desc) {
    if (desc == null) return const SizedBox.shrink();

    quill_delta.Delta? delta;

    try {
      if (desc is String) {
        final decoded = jsonDecode(desc);
        if (decoded is Map && decoded['ops'] is List) {
          delta = quill_delta.Delta.fromJson(decoded['ops']);
        } else if (decoded is List) {
          delta = quill_delta.Delta.fromJson(decoded);
        }
      } else if (desc is List) {
        delta = quill_delta.Delta.fromJson(desc);
      } else if (desc is Map && desc['ops'] is List) {
        delta = quill_delta.Delta.fromJson(desc['ops']);
      }
    } catch (_) {
      // fall through to plain text
    }

    if (delta == null) {
      return Text(desc.toString(), style: TextStyle(fontSize: 15, color: Theme.of(context).hintColor.withOpacity(0.7)));
    }

    final controller = quill.QuillController(
      document: quill.Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Constrain editor height so it doesn't overflow layout
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: quill.QuillEditor.basic(
        controller: controller,
        // readOnly: true,
      ),
    );
  }

  static LatLng? _extractLatLngFromMapsLink(String url) {
    try {
      final queryReg = RegExp(r'query=([\-0-9.]+),([\-0-9.]+)');
      final atReg = RegExp(r'/@([\-0-9.]+),([\-0-9.]+)');
      if (queryReg.hasMatch(url)) {
        final m = queryReg.firstMatch(url)!;
        return LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!));
      } else if (atReg.hasMatch(url)) {
        final m = atReg.firstMatch(url)!;
        return LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!));
      }
    } catch (_) {}
    return null;
  }

  Widget _buildNFTGrid(
    List<Map<String, dynamic>> eventNFTs,
    int cardCountPerRow,
    double maxWidth,
    BuildContext context,
    void Function(Map<String, dynamic>)? onNFTCardTap,
  ) {
    // Calculate responsive card width from given maxWidth
    final totalPadding = 48.0; // parent container horizontal padding (24 * 2)
    final gap = 16.0;
    final columns = cardCountPerRow.clamp(1, 6);
    final available = (maxWidth - totalPadding) - (gap * (columns - 1));
    final cardW = (available / columns).clamp(220.0, 520.0);

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: List.generate(eventNFTs.length, (index) {
        final nft = eventNFTs[index];
        return SizedBox(
          width: columns > 1 ? cardW : double.infinity,
          child: _NFTCard(
            nft,
            onTap: () => onNFTCardTap?.call(nft),
          ),
        );
      }),
    );
  }

  // ========= GLASS MAP POPUP =========
  Future<void> _openMapGlassDialog({
    required double lat,
    required double lng,
    required String mapsUrl,
  }) async {
    final marker = Marker(
      markerId: const MarkerId("event-location"),
      position: LatLng(lat, lng),
      infoWindow: const InfoWindow(title: "Event Location"),
    );

    await showGlassPopup<void>(
      context: context,
      title: 'Event Location',
      dismissible: true,
      child: LayoutBuilder(
        builder: (ctx, c) {
          // Responsive map size inside popup
          final mapW = c.maxWidth.clamp(300.0, 520.0);
          final mapH = (mapW * 0.6).clamp(220.0, 360.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: mapW,
                height: mapH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
                    markers: {marker},
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.7)),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => launchUrl(Uri.parse(mapsUrl), mode: LaunchMode.externalApplication),
                      child: const Text('Open in Google Maps', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NFTCard extends StatefulWidget {
  final Map nft;
  final VoidCallback? onTap;
  const _NFTCard(this.nft, {this.onTap});
  @override
  State<_NFTCard> createState() => _NFTCardState();
}

class _NFTCardState extends State<_NFTCard> {
  bool _hovering = false;

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
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.hintColor;
    final subtitleColor = theme.hintColor.withOpacity(0.7);

    final nft = widget.nft;
    final name = (nft['name'] ?? '').toString();
    final desc = (nft['description'] ?? '').toString();
    final type = (nft['type'] ?? '').toString();
    final category = (nft['category'] ?? '').toString();
    final brand = (nft['brand'] ?? '').toString();
    final benefit = (nft['benefit'] ?? '').toString();
    final value = nft['value']?.toString() ?? '';
    final graphic = (nft['graphic'] ?? '').toString();
    final price = nft['price']?.toString() ?? '';
    final quantity = nft['quantity']?.toString() ?? '';
    final validity = (nft['validity'] is int) ? _validityString(nft['validity']) : '';
    final tokenId = nft['tokenId']?.toString() ?? '';
    final active = nft['active'] == true ? 'Active' : 'Inactive';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Transform.scale(
        scale: _hovering ? 1.03 : 1.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap ?? () {},
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: _hovering ? 8 : 3,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: _hovering
                    ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
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
                            graphic.startsWith('http') ? graphic : '',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image, color: Colors.white54),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                        ),
                      ),
                      Text('ID: $tokenId', style: TextStyle(color: subtitleColor, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(desc, style: TextStyle(fontSize: 15, color: textColor)),
                  if (brand.isNotEmpty || category.isNotEmpty || type.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Type: $type${category.isNotEmpty ? " | $category" : ""}${brand.isNotEmpty ? " | $brand" : ""}',
                        style: TextStyle(color: subtitleColor),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Benefit: $benefit', style: TextStyle(fontSize: 13, color: subtitleColor)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Value: $value | Amount: $quantity | Price: $price',
                        style: TextStyle(fontSize: 13, color: subtitleColor)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child:
                        Text('Validity: $validity | Status: $active', style: TextStyle(fontSize: 12, color: subtitleColor)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
