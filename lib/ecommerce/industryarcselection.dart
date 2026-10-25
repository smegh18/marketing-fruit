import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndustryArcSection extends StatefulWidget {
  final double width;
  const IndustryArcSection({super.key, required this.width});

  @override
  State<IndustryArcSection> createState() => _IndustryArcSectionState();
}

class _IndustryArcSectionState extends State<IndustryArcSection> {
  String selectedArc = "abc arc";
  final List<String> arcOptions = [
    'abc arc',
    'marketing arc',
    'finance arc',
    'tech arc',
    'design arc',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 20);
    final borderRadius = BorderRadius.circular(18);

    // On mobile, use a compact card with sensible font sizes/layout
    return Center(
      child: Container(
        width: screenWidth * 0.94,
        margin: const EdgeInsets.only(bottom: 12, top: 8),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Industry Arc',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 24, thickness: 1),
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Selected Arc: ',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.hintColor,
                          ),
                        ),
                        TextSpan(
                          text: selectedArc,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showArcSelectionPopup(context, theme.hintColor),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showArcSelectionPopup(BuildContext context, Color textColor) {
    String tempSelected = selectedArc;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDED08B), Color(0xFF918D64)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select a New Arc",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setInnerState) {
                    return DropdownButton<String>(
                      value: tempSelected,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      isExpanded: true,
                      items: arcOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: GoogleFonts.poppins(fontSize: 17, color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setInnerState(() {
                          tempSelected = newValue!;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showConfirmationDialog(context, tempSelected);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String newArc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDED08B), Color(0xFF918D64)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Are you sure you want to continue?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Changing your arc will reset your current progress and start a new arc.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedArc = newArc;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Yes, Continue", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
