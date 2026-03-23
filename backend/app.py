from flask import Flask, request, jsonify
import cv2
import numpy as np
import requests
import firebase_admin
from firebase_admin import credentials, firestore
import os
import json

# ✅ FIXED IMPORTS
from backend.utils import get_embedding
from backend.model import process_attendance
from backend.config import MATCH_THRESHOLD

app = Flask(__name__)

# =========================
# HOME ROUTE
# =========================
@app.route("/")
def home():
    return "AI Attendance Backend Running"


# =========================
# FIREBASE INIT (FIXED)
# =========================
if not firebase_admin._apps:
    firebase_json = os.environ.get("FIREBASE_KEY")

    if firebase_json:
        cred = credentials.Certificate(json.loads(firebase_json))
    else:
        cred = credentials.Certificate("firebase_key.json")

    firebase_admin.initialize_app(cred)

db = firestore.client()


# =========================
# GLOBAL DB
# =========================
student_db = {}
student_names = {}


# =========================
# DOWNLOAD IMAGE
# =========================
def download_image(url):
    try:
        response = requests.get(url)

        if response.status_code != 200:
            return None

        img_array = np.asarray(bytearray(response.content), dtype=np.uint8)

        if img_array.size == 0:
            return None

        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        return img

    except:
        return None


# =========================
# LOAD STUDENTS
# =========================
def load_students():
    global student_db, student_names

    print("Loading students...")

    students = db.collection("students").stream()

    for student in students:
        sid = student.id
        data = student.to_dict()

        name = data.get("name", sid)
        student_names[sid] = name

        faces = db.collection("students").document(sid).collection("faces").stream()

        embeddings = []

        for face in faces:
            url = face.to_dict()["url"]

            img = download_image(url)
            if img is None:
                continue

            emb = get_embedding(img)
            if emb is not None:
                embeddings.append(emb)

        if len(embeddings) > 0:
            student_db[sid] = np.mean(embeddings, axis=0)

    print("Students loaded:", len(student_db))


# LOAD ONCE
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

    present_ids = set()

    for url in image_urls:
        img = download_image(url)

        if img is None:
            continue

        _, detected_ids = process_attendance(
            img,
            student_db,
            MATCH_THRESHOLD
        )

        for sid in detected_ids:
            present_ids.add(sid)

    present_ids = list(present_ids)

    # SAVE
    ref = db.collection("attendance").document(date).collection("students")

    for sid in student_db.keys():
        status = "Present" if sid in present_ids else "Absent"

        ref.document(sid).set({
            "name": student_names.get(sid, sid),
            "status": status
        })

    return jsonify({"present_students": present_ids})


# =========================
# RUN
# =========================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)