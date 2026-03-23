from flask import Flask, request, jsonify
import cv2
import numpy as np
import requests
import firebase_admin
from firebase_admin import credentials, firestore
import os
import json

from backend.utils import get_embedding
from backend.model import process_attendance
from backend.config import MATCH_THRESHOLD

app = Flask(__name__)

# =========================
# FIREBASE INIT
# =========================
if not firebase_admin._apps:
    firebase_json = os.environ.get("FIREBASE_KEY")

    if firebase_json:
        cred = credentials.Certificate(json.loads(firebase_json))
    else:
        cred = credentials.Certificate("backend/firebase_key.json")

    firebase_admin.initialize_app(cred)

db = firestore.client()

# =========================
# GLOBAL DATA
# =========================
student_db = {}
student_names = {}
loaded = False

# =========================
# HOME
# =========================
@app.route("/")
def home():
    return "AI Attendance Backend Running"

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

        return cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    except:
        return None

# =========================
# LOAD STUDENTS (LAZY)
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

# =========================
# ATTENDANCE API
# =========================
@app.route("/process_attendance", methods=["POST"])
def process():
    global loaded

    # ✅ LOAD ONLY ON FIRST REQUEST
    if not loaded:
        load_students()
        loaded = True

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

    # SAVE TO FIREBASE
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
    port = int(os.environ.get("PORT", 5000))  # ✅ IMPORTANT FOR RENDER
    app.run(host="0.0.0.0", port=port)