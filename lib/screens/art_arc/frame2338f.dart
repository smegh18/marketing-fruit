import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2339.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2338f extends StatefulWidget {
  const Frame2338f({super.key});

  @override
  State<Frame2338f> createState() => _Frame2338fState();
}

class _Frame2338fState extends State<Frame2338f> {
  final List<String> messages = [
    "The last visitor has left. The door clicks shut behind them, and for the first time in weeks, there’s silence.The kind that hangs in the air like thick paint.",
    "You lean against the wall, your back brushing a canvas that still smells faintly of varnish. The lights inside the maze slowly dim on their timer, casting the space in warm shadows. The buzz of people, the whirl of QR code scanners, the chorus of “Wow!”s and camera shutters—all of it has finally faded.",
    "Your team has already left. Empty water bottles and sticker peels litter the front desk. A few folded feedback forms sit untouched in a tray marked “Post-Launch Survey.” The studio, just hours ago alive with movement, is resting now. And in this stillness, it finally hits you: your art studio exists. And people came.",
    "The marketing campaign is over. The influencer posts ran their course, the ad budget burned clean, the press release got picked up by three small blogs and one very unexpected design newsletter. School groups started DMing you for field trip slots. Your first week didn’t just meet projections—it exceeded them.",
    "For now, it feels like a quiet victory.You exhale and sit on the edge of the reception stool, rubbing your palms together. It’s that rare moment every entrepreneur chases: not peace, but pause.",
    "You open your laptop—not to work, just to look. Maybe scroll through a few tagged posts. Maybe glance at the analytics one more time. Maybe allow yourself a tiny bit of pride.But then, you see it.",
    "An unread message. An unusual subject line. A push notification. A link someone’s forwarded twice.Something you didn’t plan for.You click. You read. You pause again.And just like that, the pause is over. Something has shifted.Something new is coming.",
    "You wake up to 200 unread notifications. An edgy local reviewer—famous for snark—has posted a 90‑second reel titled “Over‑priced Selfie Trap?” They complain about long queues, “gimmicky” art, and call your ticket price “daylight robbery.”",
    "Within hours the reel hits 100 k views. Comments split in two camps: defenders who loved the experience, and skeptics who now vow never to visit."
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2339()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/AA1.png',
              fit: BoxFit.cover,
            ),
          ),

          // Text Bubble
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message: messages[currentIndex],
            ),
          ),

          // Next Button
          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: _handleNext,
            ),
          ),
        ],
      ),
    );
  }
}
