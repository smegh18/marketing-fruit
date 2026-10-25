import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/event_attending.dart';
import 'package:Marketing_Fruit/components/event_calender.dart';
import 'package:Marketing_Fruit/components/event_list.dart';

class UserEventScreen extends StatelessWidget {
  final String userRole;
  final void Function() onEventCreated;
  final void Function(String, {String? eventName}) onEventTap;
  const UserEventScreen({super.key, required this.onEventCreated, required this.onEventTap, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1000 ? screenWidth * 0.05 : 16.0;
    print("UserEventScreen: onEventTap passed is $onEventTap.hashCode");


    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventAttendingSection(onEventTap: onEventTap,),
            const SizedBox(height: 16),
            EventCalendarFrontendSection(onEventCreated: onEventCreated,onEventTap: onEventTap,userRole: userRole,),
            const SizedBox(height: 16),
            EventListPage(onEventTap: onEventTap,),
          ],
        ),
      ),

    );
  }
}
