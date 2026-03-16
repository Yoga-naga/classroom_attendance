import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadFacePage extends StatefulWidget {
  @override
  State<UploadFacePage> createState() => _UploadFacePageState();
}

class _UploadFacePageState extends State<UploadFacePage> {
  File? image;
  int uploadCount = 0;

  final picker = ImagePicker();

  final cloudName = "dzldowl1c";
  final uploadPreset = "student_faces";

  User? user;

  @override
  void initState() {
    super.initState();

    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      getUploadedImages();
    }
  }

  // Get already uploaded images
  Future getUploadedImages() async {
    var snapshot = await FirebaseFirestore.instance
        .collection("students")
        .doc(user!.uid)
        .collection("faces")
        .get();

    setState(() {
      uploadCount = snapshot.docs.length;
    });
  }

  // Pick image
  Future pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  // Upload image
  Future uploadImage() async {
    if (user == null) {
      showMessage("User not logged in");
      return;
    }

    if (image == null) {
      showMessage("Select image first");
      return;
    }

    if (uploadCount >= 5) {
      showMessage("Maximum 5 images allowed");
      return;
    }

    var url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(await http.MultipartFile.fromPath('file', image!.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      String imageUrl = data['secure_url'];

      // Save in Firestore
      await FirebaseFirestore.instance
          .collection("students")
          .doc(user!.uid)
          .collection("faces")
          .add({"url": imageUrl, "time": Timestamp.now()});

      uploadCount++;

      setState(() {
        image = null;
      });

      showMessage("Image $uploadCount Uploaded");

      if (uploadCount == 5) {
        showMessage("All 5 Images Uploaded Successfully");
      }
    } else {
      showMessage("Upload Failed");
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Face Images"),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Uploaded: $uploadCount / 5",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            image != null
                ? Image.file(image!, height: 200)
                : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: Text("No Image Selected"),
                    ),
                  ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                    icon: Icon(Icons.camera),
                    label: Text("Camera"),
                    onPressed: () {
                      pickImage(ImageSource.camera);
                    }),
                ElevatedButton.icon(
                    icon: Icon(Icons.photo),
                    label: Text("Gallery"),
                    onPressed: () {
                      pickImage(ImageSource.gallery);
                    })
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: uploadImage, child: Text("Upload Image"))
          ],
        ),
      ),
    );
  }
}
