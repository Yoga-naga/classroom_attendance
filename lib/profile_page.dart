import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Profile"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection("students")
            .doc(user!.uid)
            .get(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data;

          return Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name : ${data['name']}",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  "Roll No : ${data['rollno']}",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  "Attendance : ${data['attendance']} %",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 30),
                Text(
                  "Uploaded Faces",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("students")
                        .doc(user!.uid)
                        .collection("faces")
                        .snapshots(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var faces = snapshot.data.docs;

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemCount: faces.length,
                        itemBuilder: (context, index) {
                          var url = faces[index]['url'];

                          return Padding(
                            padding: EdgeInsets.all(5),
                            child: Image.network(url),
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
