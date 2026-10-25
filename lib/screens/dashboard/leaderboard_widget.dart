import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardWidget extends StatelessWidget {
  final bool disabled;
  final double width;

  const LeaderboardWidget({
    super.key,
    this.disabled = false,
    required this.width,
  });

  final List<Map<String, dynamic>> players = const [
    {
      'name': 'Michael John',
      'image': 'assets/avatars/avatar.png',
      'industry': 'Entertainment Arc',
      'isGoingUp': true,
    },
    {
      'name': 'Alexa Liras',
      'image': 'assets/avatars/avatar1.png',
      'industry': 'Entertainment Arc',
      'isGoingUp': false,
    },
    {
      'name': 'Laure Perrier',
      'image': 'assets/avatars/avatar2.png',
      'industry': 'Entertainment Arc',
      'isGoingUp': true,
    },
    {
      'name': 'Miriam Eric',
      'image': 'assets/avatars/avatar3.png',
      'industry': 'Entertainment Arc',
      'isGoingUp': true,
    },
    {
      'name': 'Richard Gran',
      'image': 'assets/avatars/avatar4.png',
      'industry': 'Entertainment Arc',
      'isGoingUp': false,
    },
    {
      'name': 'John Levi',
      'image': 'assets/avatars/avatar5.png',
      'industry': 'Entertainment Arc',
      'isGoingUp': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    double t = ((pixelRatio - 1.0) / 1.0).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.85, t)!;

    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(
        opacity: disabled ? 0.85 : 1.0,
        child: Container(
          width: width,
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
          padding: EdgeInsets.all(20 * scaleFactor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Leaderboard",
                style: GoogleFonts.poppins(
                  color: theme.hintColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22 * scaleFactor,
                ),
              ),
              SizedBox(height: 20 * scaleFactor),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3), // Player info
                  1: FlexColumnWidth(2), // Industry
                  2: FlexColumnWidth(1.2), // Status
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "PLAYERS",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13 * scaleFactor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "INDUSTRY",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13 * scaleFactor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "STATUS",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13 * scaleFactor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(thickness: 1),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1.2),
                },
                children: players.map((player) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20 * scaleFactor,
                              backgroundImage: AssetImage(player['image']),
                            ),
                            SizedBox(width: 12 * scaleFactor),
                            Text(
                              player['name'],
                              style: TextStyle(
                                fontSize: 14.5 * scaleFactor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
                        child: Text(
                          player['industry'],
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13.5 * scaleFactor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            player['isGoingUp']
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: player['isGoingUp'] ? Colors.green : Colors.red,
                            size: 34 * scaleFactor,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
