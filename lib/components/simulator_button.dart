import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import '../screens/entertainment_arc/frame1.dart' as entertainment_arc;
import '../screens/art_arc/frame1.dart' as art_arc;
import 'orientation_wrapper.dart';
import 'entertainment_frame_navigator.dart';



class SimulatorButton extends StatefulWidget {
  final bool disabled;
  const SimulatorButton({super.key, this.disabled = false});

  @override
  State<SimulatorButton> createState() => _SimulatorButtonState();
}

class _SimulatorButtonState extends State<SimulatorButton> {
  PlayerDetails? playerDetails;
  String? balance;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null && !widget.disabled) {
      playerDetails = PlayerDetails();
      _loadBalance();
    }
  }

  Future<void> _loadBalance() async {
    if (playerDetails == null) return;
    final name = await playerDetails!.fetchBalance();
    setState(() {
      balance = name;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (widget.disabled) {
      balance = "0";
    }
    if (balance == null || balance == "null" || balance!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    double balancek;
    try {
      balancek = int.parse(balance!) / 1000;
    } catch (e) {
      balancek = 0;
    }

    final dpi = MediaQueryData.fromView(WidgetsBinding.instance.window).devicePixelRatio;
    double scale = 1.0;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.16;
    } else if (dpi >= 2.0)
      scale = 1.3;
    else
      scale = 1.1;

    return IgnorePointer(
      ignoring: widget.disabled,
      child: Opacity(
        opacity: widget.disabled ? 0.85 : 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width * 0.5 * scale;
            return SizedBox(
              width: width,
              height: height,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1AF0C7),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 15,
                      left: 0,
                      right: 80,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 35,
                      left: 0,
                      right: 100,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter Simulator',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '\$${balancek.toStringAsFixed(1)}k',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _loadBalance,
                          child: const Text(
                            'Your Balance',
                            style: TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.underline,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 30,
                      child: _AnimatedPlayButton(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}



class _AnimatedPlayButton extends StatefulWidget {
  const _AnimatedPlayButton();

  @override
  State<_AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<_AnimatedPlayButton> {
  double _scale = 1.0;

  void _onEnter(PointerEvent details) {
    setState(() => _scale = 1.3);
  }

  void _onExit(PointerEvent details) {
    setState(() => _scale = 1.0);
  }

  Future<void> _onTap() async {
    final playerDetails = PlayerDetails();
    await playerDetails.fetchArc();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      pageBuilder: (_, __, ___) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
            Center(
              child: _BusinessPopup(
                onNext: () => _showIndustryPopup(context),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showIndustryPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      pageBuilder: (_, __, ___) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
            Center(child: _IndustryPopup(navigatorContext: context)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 100,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  radius: 0.9,
                  colors: [
                    Color(0xFF74E2FF),
                    Color(0xFF007BFF),
                    Color(0xFF005BEA),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    offset: Offset(4, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _BusinessPopup extends StatelessWidget {
  final VoidCallback onNext;

  const _BusinessPopup({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Use a fraction of screen size, but cap it so it never overflows
    final popupWidth = (screenWidth * 0.85).clamp(200.0, 400.0);
    final popupMaxHeight = screenHeight * 0.65;

    // Scale font sizes based on available height
    final titleFontSize = (popupMaxHeight * 0.06).clamp(16.0, 28.0);
    final bodyFontSize = (popupMaxHeight * 0.045).clamp(13.0, 20.0);

    return Container(
      width: popupWidth,
      constraints: BoxConstraints(maxHeight: popupMaxHeight),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        backgroundBlendMode: BlendMode.screen,
        gradient: const LinearGradient(
          colors: [Color(0xFFDED08B), Color(0xFF918D64)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "You are about to enter the business simulator",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "This simulator will recreate real world business scenario, challenges, and opportunities, allowing you to test and polish entrepreneur skills.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: bodyFontSize,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onNext,
                child: const Text(
                  'Next',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndustryPopup extends StatefulWidget {
  final BuildContext navigatorContext;
  
  const _IndustryPopup({required this.navigatorContext});
  
  @override
  State<_IndustryPopup> createState() => _IndustryPopupState();
}

class _IndustryPopupState extends State<_IndustryPopup> {
  String selectedIndustry = 'Entertainment';
  final List<String> industries = ['Entertainment', 'Art'];
  final playerDetails = PlayerDetails();

  Future<void> _handleSimulatorNavigation(BuildContext context, String selectedIndustry) async {
    try {
      Widget targetScreen;
      if (selectedIndustry == 'Entertainment') {
        try {
          // Check for saved progress with timeout
          final progress = await playerDetails.loadProgress().timeout(
            Duration(seconds: 5),
            onTimeout: () => null,
          );
          print('Progress: $progress');

          // Validate progress data
          if (progress != null &&
              progress.containsKey('currentFrame') &&
              progress['currentFrame'] != null &&
              progress['currentFrame'].toString().trim().isNotEmpty &&
              progress['currentFrame'] != 'frame1') { // Don't show resume for frame1

            print('Found valid progress, showing resume dialog');

            // Show resume dialog with timeout protection
            bool? shouldResume;
            try {
              shouldResume = await showDialog<bool>(
                context: context,
                barrierDismissible: true, // Allow dismissing
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Resume Progress?'),
                    content: Text(
                        'You have saved progress at ${progress['currentFrame']}. Would you like to resume from where you left off or start over?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Start Over'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Resume'),
                      ),
                    ],
                  );
                },
              ).timeout(
                Duration(seconds: 10),
                onTimeout: () => false, // Default to start over if dialog times out
              );
            } catch (dialogError) {
              print('Dialog error: $dialogError');
              shouldResume = false; // Default to start over on error
            }

            print('Should resume: $shouldResume');

            if (shouldResume == true) {
              // Try to resume from saved frame
              try {
                final frameWidget = EntertainmentFrameNavigator.createFrameWidget(
                    progress['currentFrame'].toString());
                print('Frame widget created: ${frameWidget != null}');
                if (frameWidget != null) {
                  targetScreen = OrientationWrapper(
                    orientations: [
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ],
                    child: frameWidget,
                  );
                } else {
                  // Frame not found, fallback to Frame1
                  print('Frame widget null, falling back to Frame1');
                  targetScreen = OrientationWrapper(
                    orientations: [
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ],
                    child: const entertainment_arc.Frame1(),
                  );
                }
              } catch (e) {
                // Frame creation failed, fallback to Frame1
                print('Frame creation error: $e');
                targetScreen = OrientationWrapper(
                  orientations: [
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ],
                  child: const entertainment_arc.Frame1(),
                );
              }
            } else {
              // User chose "Start Over" or dialog failed - clear progress and go to Frame1
              print('Starting over, clearing progress');
              try {
                playerDetails.clearProgress();
              } catch (e) {
                print('Clear progress error: $e');
                // Continue even if clear fails
              }
              targetScreen = OrientationWrapper(
                orientations: [
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ],
                child: const entertainment_arc.Frame1(),
              );
            }
          } else {
            // No valid saved progress - new user or frame1, start from Frame1
            print('No valid progress found, starting from Frame1');
            targetScreen = OrientationWrapper(
              orientations: [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ],
              child: const entertainment_arc.Frame1(),
            );
          }
        } catch (e) {
          // Progress loading failed, start from Frame1
          print('Progress loading error: $e');
          targetScreen = OrientationWrapper(
            orientations: [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            child: const entertainment_arc.Frame1(),
          );
        }
      } else {
        // Art arc
        targetScreen = OrientationWrapper(
          orientations: [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          child: const art_arc.Frame1(),
        );
      }

      // Navigate to target screen
      print('Navigating to target screen');
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
        print('Navigation completed successfully');
      } else {
        print('Context not mounted, navigation skipped');
      }
    } catch (e) {
      print('Navigation handler error: $e');
      // Final fallback: just navigate to Frame1 if context is still valid
      if (context.mounted) {
        final targetScreen = OrientationWrapper(
          orientations: [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          child: const entertainment_arc.Frame1(),
        );

        try {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetScreen),
          );
          print('Fallback navigation completed');
        } catch (navError) {
          // If navigation fails, there's nothing more we can do
          print('Fallback navigation failed: $navError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final popupWidth = (screenWidth * 0.85).clamp(250.0, 400.0);
    final popupMaxHeight = screenHeight * 0.50;
    final titleFontSize = (popupMaxHeight * 0.07).clamp(18.0, 28.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: popupWidth,
        constraints: BoxConstraints(maxHeight: popupMaxHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          backgroundBlendMode: BlendMode.screen,
          gradient: const LinearGradient(
            colors: [Color(0xFFDED08B), Color(0xFF918D64)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select Industry",
                  style: GoogleFonts.poppins(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: Text("Select Arc"),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.deepOrange),
                    value: selectedIndustry,
                    isExpanded: true,
                    style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                    items: industries.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedIndustry = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final BuildContext navigatorContext = widget.navigatorContext;
                    playerDetails.getArc(selectedIndustry);
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleSimulatorNavigation(navigatorContext, selectedIndustry);
                    });
                  },
                  child: const Text(
                    'Enter Simulator',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

