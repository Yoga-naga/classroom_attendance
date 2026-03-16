import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceHistory extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Attendance History"),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance History"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("students")
            .doc(user!.uid)
            .collection("history")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No attendance records found",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          var data = snapshot.data!.docs;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              var attendance = data[index];

              return Card(
                margin: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    attendance.id, // date
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    attendance['status'], // Present / Absent
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
