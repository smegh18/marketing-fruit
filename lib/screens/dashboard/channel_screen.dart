import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/channel_list.dart';
import 'package:Marketing_Fruit/components/channel_search.dart';

class ChannelScreen extends StatelessWidget {
  final void Function() onChannelCreated;

  /// allow deep-jump by passing {messageId}
  final void Function(String id, {String? messageId}) onChannelTap;

  final String userRole;
  final String? school; // new: pass school from Firebase if present

  const ChannelScreen({
    super.key,
    required this.onChannelCreated,
    required this.onChannelTap,
    required this.userRole,
    this.school,
  });

  bool get _canSearch {
    final r = userRole.trim().toLowerCase();
    final hasSchool = (school != null && school!.trim().isNotEmpty);
    return hasSchool || r == 'brand' || r == 'admin' || r == 'school';
  }

  @override
  Widget build(BuildContext context) {
    print(_canSearch);
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_canSearch) ChannelSearchSection(onChannelCreated: onChannelCreated),
            if (_canSearch) const SizedBox(height: 16),

            // ChannelsPage already knows how to pass messageId when a
            // message search hit is tapped.
            ChannelsPage(onChannelTap: onChannelTap, userRole: userRole),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
