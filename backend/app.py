from flask import Flask, request, jsonify
import cv2
import numpy as np
import requests
import firebase_admin
from firebase_admin import credentials, firestore

import os
import json

from utils import get_embedding
from model import process_attendance
from config import MATCH_THRESHOLD

app = Flask(__name__)

# =========================
# HOME ROUTE
# =========================
@app.route("/")
def home():
    return "AI Attendance Backend Running"


# =========================
# FIREBASE INITIALIZATION (UPDATED)
# =========================
if not firebase_admin._apps:
    firebase_json = os.environ.get("FIREBASE_KEY")

    if firebase_json:
        cred = credentials.Certificate(json.loads(firebase_json))
    else:
        # fallback for local
        cred = credentials.Certificate("firebase_key.json")

    firebase_admin.initialize_app(cred)

db = firestore.client()


# =========================
# GLOBAL STUDENT DATABASE
# =========================
student_db = {}
student_names = {}


# =========================
# SAFE IMAGE DOWNLOAD
# =========================
def download_image(url):
    try:
        print("Downloading:", url)

        response = requests.get(url)

        if response.status_code != 200:
            print("Failed to download image")
            return None

        img_array = np.asarray(bytearray(response.content), dtype=np.uint8)

        if img_array.size == 0:
            print("Empty image data")
            return None

        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        if img is None:
            print("OpenCV failed to decode image")
            return None

        return img

    except Exception as e:
        print("Image download error:", e)
        return None


# =========================
# LOAD STUDENTS (ONLY ONCE)
# =========================
def load_students():
    global student_db
    global student_names

    print("Loading students from Firebase...")

    students = db.collection("students").stream()

    for student in students:
        sid = student.id
        student_data = student.to_dict()

        name = student_data.get("name", sid)
        student_names[sid] = name

        faces = db.collection("students").document(sid).collection("faces").stream()

        embeddings = []

        for face in faces:
            face_data = face.to_dict()
            url = face_data["url"]

            img = download_image(url)
            if img is None:
                continue

            emb = get_embedding(img)
            if emb is not None:
                embeddings.append(emb)

        if len(embeddings) > 0:
            avg_emb = np.mean(embeddings, axis=0)
            student_db[sid] = avg_emb

    print("Total students loaded:", len(student_db))


# LOAD ONLY ONCE
if len(student_db) == 0:
    load_students()


# =========================
# ATTENDANCE API
# =========================
@app.route("/process_attendance", methods=["POST"])
def process():
    data = request.json

    image_urls = data["image_urls"]
    date = data["date"]

    print("Received images:", image_urls)

    present_ids = set()

    # PROCESS MULTIPLE IMAGES
    for url in image_urls:
        group_img = download_image(url)

        if group_img is None:
            print("Skipping invalid image")
            continue

        print("Running face recognition...")

        result_img, detected_ids = process_attendance(
            group_img,
            student_db,
            MATCH_THRESHOLD
        )

        for sid in detected_ids:
            present_ids.add(sid)

    present_ids = list(present_ids)

    print("Final Present Students:", present_ids)

    # SAVE ATTENDANCE
    attendance_ref = db.collection("attendance").document(date).collection("students")

    for sid in student_db.keys():
        status = "Present" if sid in present_ids else "Absent"

        student_name = student_names.get(sid, sid)

        attendance_ref.document(sid).set({
            "name": student_name,
            "status": status
        })

    print("Attendance saved to Firebase")

    return jsonify({
        "present_students": present_ids
    })


# =========================
# RUN SERVER
# =========================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)