from flask import Flask, request, jsonify
from model import recognize_faces
from firebase_config import db

app = Flask(__name__)

@app.route("/")
def home():
    return "AI Attendance Backend Running"

@app.route("/process_attendance", methods=["POST"])
def process_attendance():

    data = request.json
    image_urls = data.get("images", [])
    date = data.get("date")

    present_ids = recognize_faces(image_urls)

    # 🔥 Get all students
    students = db.collection("students").stream()

    all_students = []
    for s in students:
        all_students.append(s.id)

    # 🔥 Mark attendance
    for student_id in all_students:

        status = "Present" if student_id in present_ids else "Absent"

        db.collection("attendance") \
          .document(date) \
          .collection("students") \
          .document(student_id) \
          .set({
              "status": status
          })

    return jsonify({
        "present": present_ids,
        "total": len(all_students)
    })

if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)