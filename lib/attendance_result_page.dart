import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceResultPage extends StatelessWidget {
  String today = DateTime.now().toString().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Result"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("attendance")
            .doc(today)
            .collection("students")
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var students = snapshot.data!.docs;

          if (students.isEmpty) {
            return Center(child: Text("No Attendance Data"));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              var data = students[index];

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: Icon(
                    data['status'] == "Present"
                        ? Icons.check_circle
                        : Icons.cancel,
                    color:
                        data['status'] == "Present" ? Colors.green : Colors.red,
                  ),
                  title: Text(data['name']),
                  subtitle: Text("Status: ${data['status']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
