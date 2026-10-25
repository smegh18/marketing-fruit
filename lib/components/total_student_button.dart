import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


class StudentCountButton extends StatefulWidget {
  final bool disabled;
  final VoidCallback? onViewAll;

  const StudentCountButton({
    super.key,
    this.disabled = false,
    this.onViewAll,
  });

  @override
  State<StudentCountButton> createState() => _StudentCountButtonState();
}

class _StudentCountButtonState extends State<StudentCountButton> {
  final playerDetails = PlayerDetails(); // Assuming you'll fetch student count similarly
  String? studentCount;

  @override
  void initState() {
    super.initState();
    _loadStudentCount();
  }

  Future<void> _loadStudentCount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final dbRef = FirebaseDatabase.instance.ref().child("users");

    // Step 1: Get current user's data
    final currentUserSnapshot = await dbRef.child(currentUser.uid).get();
    if (!currentUserSnapshot.exists) return;

    final currentUserData = Map<String, dynamic>.from(currentUserSnapshot.value as Map);
    final currentUserSchool = currentUserData['school'].toString().toLowerCase();

    // Step 2: Get all users and count students with the same school field
    final allUsersSnapshot = await dbRef.get();
    int count = 0;

    for (final user in allUsersSnapshot.children) {
      final data = Map<String, dynamic>.from(user.value as Map);
      final studentSchool = data['school'].toString().toLowerCase();
      if (data['role'] == 'Student' && studentSchool == currentUserSchool) {
        count++;
      }
    }

    setState(() {
      studentCount = count.toString();
    });
  }



  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;

    if (pixelRatio > baselinePixelRatio) {
      double ratio = baselinePixelRatio / pixelRatio;
      if ((pixelRatio - 1.0).abs() < 0.3) {
        scaleFactor = ratio * 1.05;
        sfg = ratio * 1.1;
      } else {
        scaleFactor = ratio * 1.1;
        sfg = ratio * 1.5;
      }
    }

    if (studentCount == null || studentCount == "null" || studentCount!.isEmpty) {
      return const CircularProgressIndicator();
    }

    return IgnorePointer(
      ignoring: widget.disabled,
      child: Opacity(
        opacity: widget.disabled ? 0.85 : 1.0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.35 * sfg,
          height: MediaQuery.of(context).size.height * 0.3 * sfg,
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
              // Decorative background lines
              Positioned(
                top: 15 * scaleFactor,
                left: 0,
                right: 80 * scaleFactor,
                child: Container(
                  height: 6 * scaleFactor,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned(
                top: 35 * scaleFactor,
                left: 0,
                right: 100 * scaleFactor,
                child: Container(
                  height: 6 * scaleFactor,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Students Registered',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20 * scaleFactor,
                    ),
                  ),
                  SizedBox(height: 20 * scaleFactor),
                  Text(
                    '$studentCount Students',
                    style: TextStyle(
                      fontSize: 40 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: widget.onViewAll,
                    child: Text(
                      'View All Students',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        decoration: TextDecoration.underline,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              // No play button here
            ],
          ),
        ),
      ),
    );
  }
}
