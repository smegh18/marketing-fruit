import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame12.dart';
import 'package:Marketing_Fruit/components/text_bubble.dart';

class Frame11 extends StatefulWidget {
  const Frame11({super.key});

  @override
  State<Frame11> createState() => _Frame11State();
}

class _Frame11State extends State<Frame11> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame11', null);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final playerDetails = PlayerDetails();

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/EA1.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.05,
            child: Image.asset(
              'assets/explaining.gif',
              height: screenHeight * 0.80,
            ),
          ),

          // Hardcoded, auto-sizing message bubble
          Positioned(
            bottom: screenHeight * 0.55,
            left: screenWidth * 0.35,
            child: MessageBubbleWithImage(
              imageAsset: 'assets/messagebubble.png',
              text: "You will be presented with four different types of content that you can choose from. Each content will have its own business implications. So make sure to select the content you are most comfortable with \n All The Best!!",
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
              maxWidth: screenWidth * 0.3, // You can adjust maxWidth
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),

          // Existing Text Bubble (remove if not needed)
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
                  "Now before diving straight into the business, it is important to choose the type of content we want to go ahead with. Meanwhile let me setup your studio.",
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame12(),
                  ),
                );
              },
            ),
          ),

          // Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}

/// A custom widget for a non-editable, auto-sizing message bubble with an image background.
class MessageBubbleWithImage extends StatelessWidget {
  final String imageAsset;
  final String text;
  final TextStyle textStyle;
  final double maxWidth;
  final EdgeInsets padding;

  const MessageBubbleWithImage({
    super.key,
    required this.imageAsset,
    required this.text,
    required this.textStyle,
    required this.maxWidth,
    this.padding = const EdgeInsets.all(18.0),
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        // Set a maxHeight if you want an upper limit
      ),
      child: Stack(
        children: [
          // Bubble background image
          Image.asset(
            imageAsset,
            fit: BoxFit.fill,
            width: double.infinity,
          ),
          // The text over the bubble
          Positioned.fill(
            child: Padding(
              padding: padding,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: textStyle,
                  softWrap: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

