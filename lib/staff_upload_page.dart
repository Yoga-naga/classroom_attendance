import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'attendance_result_page.dart';

class StaffUploadPage extends StatefulWidget {
  @override
  _StaffUploadPageState createState() => _StaffUploadPageState();
}

class _StaffUploadPageState extends State<StaffUploadPage> {
  List<File> images = [];
  final picker = ImagePicker();

  // CAMERA IMAGE
  Future pickCameraImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (picked != null) {
      if (images.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Maximum 5 images allowed")),
        );
        return;
      }

      setState(() {
        images.add(File(picked.path));
      });
    }
  }

  // GALLERY MULTIPLE IMAGES
  Future pickGalleryImage() async {
    final picked = await picker.pickMultiImage(
      imageQuality: 90,
    );

    if (picked.isNotEmpty) {
      if (images.length + picked.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Maximum 5 images allowed")),
        );
        return;
      }

      setState(() {
        images.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  // 🔥 PROCESS ATTENDANCE (UPLOAD + BACKEND CALL)
  Future processAttendance() async {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload classroom images first")),
      );
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Uploading Images...")));

    try {
      List<String> imageUrls = [];

      // 1️⃣ Upload images to Cloudinary
      for (File image in images) {
        var url =
            Uri.parse("https://api.cloudinary.com/v1_1/dzldowl1c/image/upload");

        var request = http.MultipartRequest("POST", url);
        request.fields['upload_preset'] = "classroom_images";
        request.files
            .add(await http.MultipartFile.fromPath('file', image.path));

        var response = await request.send();
        var res = await response.stream.bytesToString();
        var data = jsonDecode(res);

        imageUrls.add(data['secure_url']);
      }

      print("Uploaded URLs: $imageUrls");

      // 2️⃣ Call backend API AFTER getting Cloudinary URLs
      var api = Uri.parse(
          "https://ai-attendance-backend.onrender.com/process_attendance");

      var response = await http.post(
        api,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "images": imageUrls, // ✅ YOUR CLOUDINARY URLs
          "date": DateTime.now().toString().substring(0, 10)
        }),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);

        print("Backend result: $result");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Attendance Processed Successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // VIEW RESULT PAGE
  void viewResult() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceResultPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Classroom Photos"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Selected Images: ${images.length} / 5",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            images.isNotEmpty
                ? SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.all(5),
                          child: Image.file(images[index]),
                        );
                      },
                    ),
                  )
                : Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: Center(child: Text("No Images Selected")),
                  ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text("Take Photo"),
              onPressed: pickCameraImage,
            ),
            SizedBox(height: 15),
            ElevatedButton.icon(
              icon: Icon(Icons.photo),
              label: Text("Select From Gallery"),
              onPressed: pickGalleryImage,
            ),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: processAttendance, // ✅ PROCESS ATTENDANCE
              child: Text("Process Attendance"),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: viewResult,
              child: Text("View Result"),
            ),
          ],
        ),
      ),
    );
  }
}
