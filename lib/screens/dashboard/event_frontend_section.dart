import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/components/mglasspopup.dart';

import '../../components/event_attendees_questions.dart';
import '../../components/event_attendees_section.dart';
import '../../components/your_details.dart';
import '../../login_screen.dart';

// ⬇️ Use the same glass helper you created earlier
// import 'glass_popup.dart';

class EventFrontendSection extends StatefulWidget {
  final String eventId;
  final String userRole;
  final bool jk;
  final Map<String, dynamic> eventData;
  final ValueChanged<bool>? onAttendFlowActive;

  const EventFrontendSection({
    super.key,
    required this.eventData,
    this.onAttendFlowActive,
    required this.userRole,
    required this.eventId, this.jk = false,
  });

  @override
  State<EventFrontendSection> createState() => _EventFrontendSectionState();
}

class _EventFrontendSectionState extends State<EventFrontendSection> {
  int currentStep = -1;
  Map<String, dynamic>? userDetails;
  bool userLoading = true;
  String? userId;
  bool userIsAttending = false;

  List<Map<String, dynamic>> answersData = [];
  Map<String, dynamic> userDetailsData = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserData();
    _checkUserAttending();
  }

  @override
  void initState() {
    super.initState();
    print(widget.jk);
  }

  Future<void> _fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        userDetails = null;
        userLoading = false;
        userId = null;
      });
      return;
    }
    final uid = currentUser.uid;
    userId = uid;
    final ref = FirebaseDatabase.instance.ref('users/$uid');
    final snap = await ref.get();
    if (snap.exists) {
      setState(() {
        userDetails = Map<String, dynamic>.from(snap.value as Map);
        userLoading = false;
      });
    } else {
      setState(() {
        userDetails = null;
        userLoading = false;
      });
    }
  }

  Future<void> _checkUserAttending() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        userIsAttending = false;
      });
      return;
    }
    final uid = currentUser.uid;
    final ref = FirebaseDatabase.instance.ref('events/${widget.eventId}/registeredUsers/$uid');
    final snap = await ref.get();
    setState(() {
      userIsAttending = snap.exists;
    });
  }

  void attendEventInit() async {
    if (userId == null) return;
    final ref = FirebaseDatabase.instance.ref('userRegisteringForEvent/$userId');
    await ref.set({
      'eventId': widget.eventId,
      'userId': userId,
      'answers': [],
      'userDetails': {},
    });
    _setStep(0);
  }

  void saveAnswersForEvent(List<Map<String, dynamic>> answers) async {
    answersData = answers;
    if (userId == null) return;
    final ref = FirebaseDatabase.instance.ref('userRegisteringForEvent/$userId');
    await ref.update({'answers': answers});
    nextStep();
  }

  void saveUserDetailsForEvent(Map<String, dynamic> details) async {
    userDetailsData = details;
    if (userId == null) return;
    final ref = FirebaseDatabase.instance.ref('userRegisteringForEvent/$userId');
    await ref.update({'userDetails': details});
    nextStep();
  }

  Future<void> confirmRegistrationTransfer() async {
    if (userId == null) return;
    final ref = FirebaseDatabase.instance.ref('userRegisteringForEvent/$userId');
    final regSnap = await ref.get();

    if (regSnap.exists) {
      final data = regSnap.value;
      final eventUsersRef =
          FirebaseDatabase.instance.ref('events/${widget.eventId}/registeredUsers/$userId');
      await eventUsersRef.set(data);
      await ref.remove();
    }

    setState(() {
      userIsAttending = true;
    });

    cancelSteps();
  }

  List<Widget> get steps {
    return [
      EventAttendeesQuestionSection(
        questions: widget.eventData['questions'] as List<dynamic>? ?? [],
        onSubmitted: saveAnswersForEvent,
      ),
      AttendiesSection(
        vipList: widget.eventData['vipList'] as List<dynamic>? ?? [],
      ),
      userLoading
          ? const Center(child: CircularProgressIndicator())
          : YourDetailsSection(
              userName: userDetails?['first_name'] ?? '',
              schoolName: userDetails?['school'] ?? '',
              contact: userDetails?['mobile'] ?? '',
              email: userDetails?['email'] ?? '',
              onSubmitDetails: saveUserDetailsForEvent,
              onRegisterClicked: () => _showConfirmRegistration(),
            ),
    ];
  }

  void _setStep(int step) {
    setState(() => currentStep = step);
    widget.onAttendFlowActive?.call(step >= 0);
  }

  void nextStep() {
    if (currentStep < steps.length - 1) {
      _setStep(currentStep + 1);
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      _setStep(currentStep - 1);
    }
  }

  void cancelSteps() {
    setState(() {
      currentStep = -1;
      answersData = [];
      userDetailsData = {};
    });
    widget.onAttendFlowActive?.call(false);
  }

  Future<void> _showConfirmRegistration() async {
    await showGlassPopup<void>(
      context: context,
      title: 'Confirm Registration',
      dismissible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Are you sure you want to register for this event?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.7)),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await confirmRegistrationTransfer();
                    _showRegistrationSuccess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Yes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showRegistrationSuccess() async {
    await showGlassPopup<void>(
      context: context,
      title: 'Registration Successful',
      dismissible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your entry has been registered.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoPreview(String imageUrl) async {
    await showGlassPopup<void>(
      context: context,
      title: 'Logo Preview',
      dismissible: true,
      // maxWidth: 640,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Container(
              height: 280,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: Colors.white70, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.hintColor;
    final subtitleColor = theme.hintColor.withOpacity(0.7);

    final bannerImage = widget.eventData['bannerUrl'] ?? '';
    final eventImage = widget.eventData['logoUrl'] ?? '';
    final eventName = widget.eventData['eventName']?.toString() ?? '';
    final organiser = widget.eventData['organizedBy']?.toString() ??
        widget.eventData['organizer']?.toString() ??
        'Marketing Fruit Team';

    return Column(
      children: [
        Center(
          child: Container(
            width: screenWidth * 0.95,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.black, Colors.transparent],
                        stops: const [0.0, 0.6, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: bannerImage.isNotEmpty
                        ? Image.network(
                            bannerImage,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              height: 160,
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image, color: Colors.white54),
                            ),
                          )
                        : Container(
                            height: 160,
                            color: Colors.grey[800],
                            child: const Icon(Icons.image, color: Colors.white54),
                          ),
                  ),
                ),
                // Info Row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: kIsWeb
                  // ---- Web Layout: as before ----
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Event logo (glass preview on tap)
                      if (eventImage.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showLogoPreview(eventImage),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(eventImage),
                          ),
                        )
                      else
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.event, size: 32, color: Colors.white),
                        ),
                      const SizedBox(width: 16),
                      // Name + Organizer text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              organiser,
                              style: TextStyle(color: subtitleColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Attend button or Attending text
                      if (widget.userRole != 'admin' || widget.jk) ...{
                        widget.jk
                            ? ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Register", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                            : userIsAttending
                              ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Attending",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        )
                            : ElevatedButton(
                          onPressed: attendEventInit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Attend Event", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      },
                      const SizedBox(width: 12),
                      // Talk to Organisers button
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Add talk functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Talk to Organisers", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                  // ---- Mobile (not web): logo/name row, organizer below, buttons below ----
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (eventImage.isNotEmpty)
                            GestureDetector(
                              onTap: () => _showLogoPreview(eventImage),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(eventImage),
                              ),
                            )
                          else
                            const CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.event, size: 32, color: Colors.white),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              eventName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 66.0), // align under event name
                        child: Text(
                          organiser,
                          style: TextStyle(color: subtitleColor, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (widget.userRole != 'admin')
                            userIsAttending
                                ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Attending",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            )
                                : ElevatedButton(
                              onPressed: attendEventInit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Attend Event", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          if (widget.userRole != 'admin') const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Add talk functionality
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Talk to Organisers", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        // Steps: show sub-sections inline if currentStep >= 0
        if (currentStep >= 0 && steps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: screenWidth * 0.95,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                steps[currentStep],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentStep == 0)
                      ElevatedButton(
                        onPressed: cancelSteps,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Cancel"),
                      )
                    else if (currentStep > 0)
                      ElevatedButton(
                        onPressed: previousStep,
                        child: const Text("Back"),
                      ),
                    if (currentStep < steps.length - 1)
                      ElevatedButton(
                        onPressed: nextStep,
                        child: const Text("Next"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }
}
