import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'staff_project_page.dart';

class StaffHome extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Staff Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("staff_courses")
            .doc(user!.uid)
            .collection("courses")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // If no data in Firestore
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              children: [
                Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Project IV"),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffProjectPage(
                            course: "Project IV",
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          var courses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              String courseName = courses[index]['name'];

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    courseName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StaffProjectPage(
                          course: courseName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
