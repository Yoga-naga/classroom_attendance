import 'package:flutter/material.dart';
import 'staff_upload_page.dart';

class StaffProjectPage extends StatelessWidget {
  final String course;

  StaffProjectPage({required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: Text("Classroom Image Preview"),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              child: Text("Upload Classroom Photo"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StaffUploadPage(),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("Process Attendance"),
              onPressed: () {
                // Python AI processing
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("View Attendance Result"),
              onPressed: () {
                // Open result page
              },
            )
          ],
        ),
      ),
    );
  }
}
