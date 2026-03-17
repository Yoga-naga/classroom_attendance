from firebase_config import db
import numpy as np

def load_embeddings():
    students = db.collection("students").stream()

    data = {}

    for student in students:
        doc = student.to_dict()

        if "embedding" in doc:
            data[student.id] = np.array(doc["embedding"])

    return data