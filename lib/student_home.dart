import 'package:flutter/material.dart';
import 'upload_face.dart';
import 'attendance_history.dart';
import 'profile_page.dart';

class StudentHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text("Profile"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage()),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Mark Attendance"),
                onTap: () {
                  // Camera attendance later
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text("Attendance History"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AttendanceHistory()),
                  );
                  // History page later
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.face),
                title: Text("Upload Face"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UploadFacePage(),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
