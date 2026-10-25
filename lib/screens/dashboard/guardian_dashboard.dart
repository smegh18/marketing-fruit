import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/children_section.dart';

class GuardianDashboardScreen extends StatelessWidget {
  final String guardianEmail;
  final bool redirect;
  final String name;
  final void Function(String studentName, String studentId)? onPreviewRequested;

  const GuardianDashboardScreen({super.key, this.onPreviewRequested, required this.guardianEmail, this.redirect = false, this.name = ''});

  @override
  Widget build(BuildContext context) {
    final email = guardianEmail == ''
        ? FirebaseAuth.instance.currentUser!.email!
        : guardianEmail;

    return !redirect
        ? LayoutBuilder(
      builder: (context, constraints) {
        return Material(         // <-- add this Material widget
          color: Colors.transparent, // keep transparent to avoid overlay
          child: ChildrenSection(
            guardianEmail: email,
            onChildSelected: (arc, name, studentId) {
              print('Dashboard received child tap: $name');
              print(onPreviewRequested);
              if (onPreviewRequested != null) {
                print('Calling onPreviewRequested');
                onPreviewRequested!(name, studentId);
              }
            },
            width: constraints.maxWidth,
          ),
        );
      },
    )
    : Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: "Back",
        ),
        title: Text(
          '$name\'s Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Material(         // <-- add this Material widget
            color: Colors.transparent, // keep transparent to avoid overlay
            child: ChildrenSection(
              guardianEmail: email,
              onChildSelected: (arc, name, studentId) {
                print('Dashboard received child tap: $name');
                if (onPreviewRequested != null) {
                  print('Calling onPreviewRequested');
                  onPreviewRequested!(name, studentId);
                }
              },
              width: constraints.maxWidth,
            ),
          );
        },
      )
    );
  }
}
