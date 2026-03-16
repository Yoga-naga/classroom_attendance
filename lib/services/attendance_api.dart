import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendAttendance(List<String> imageUrls) async {
  var url =
      Uri.parse("https://your-render-url.onrender.com/process_attendance");

  var response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"image_urls": imageUrls}),
  );

  if (response.statusCode == 200) {
    print("Attendance processed successfully");
    print(response.body);
  } else {
    print("Error processing attendance");
  }
}
