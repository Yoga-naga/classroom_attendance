import requests
import numpy as np
import cv2
from PIL import Image
from io import BytesIO
from mtcnn import MTCNN
from keras_facenet import FaceNet

# Load embeddings function
from embedding_cache import load_embeddings

# Initialize models
detector = MTCNN()
embedder = FaceNet()

# 🔥 GLOBAL CACHE (IMPORTANT)
student_db = {}

def download_image(url):
    response = requests.get(url)
    img = Image.open(BytesIO(response.content)).convert("RGB")
    return np.array(img)

def get_embedding(face):
    face = cv2.resize(face, (160, 160))
    face = np.expand_dims(face, axis=0)
    embedding = embedder.embeddings(face)[0]
    return embedding

def recognize_faces(image_urls):
    global student_db

    # 🔥 Load only once (IMPORTANT FIX)
    if not student_db:
        print("Loading embeddings from Firebase...")
        student_db = load_embeddings()
        print("Total students loaded:", len(student_db))

    present_students = set()

    for url in image_urls:
        try:
            img = download_image(url)
            faces = detector.detect_faces(img)

            for face in faces:
                x, y, w, h = face['box']

                # Fix negative values
                x, y = max(0, x), max(0, y)

                face_img = img[y:y+h, x:x+w]

                if face_img.size == 0:
                    continue

                embedding = get_embedding(face_img)

                for student_id, db_embedding in student_db.items():
                    distance = np.linalg.norm(embedding - db_embedding)

                    if distance < 0.6:
                        present_students.add(student_id)

        except Exception as e:
            print("Error processing image:", e)

    return list(present_students)