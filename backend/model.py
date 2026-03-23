import cv2
import numpy as np
import torch
from PIL import Image
from backend.utils import detector, encoder, load_models
from backend.config import DEVICE

def process_attendance(group_img, database, threshold):

    load_models()

    img_rgb = cv2.cvtColor(group_img, cv2.COLOR_BGR2RGB)
    img_pil = Image.fromarray(img_rgb)

    boxes, _ = detector.detect(img_pil)
    faces = detector(img_pil)

    if faces is None or boxes is None:
        return group_img, []

    faces = faces.to(DEVICE)

    with torch.no_grad():
        embeddings = encoder(faces).cpu().numpy()

    embeddings = embeddings / np.linalg.norm(embeddings, axis=1, keepdims=True)

    present_ids = []

    for i, g_emb in enumerate(embeddings):

        best_id = "Unknown"
        max_sim = -1

        for sid, ref_emb in database.items():
            sim = np.dot(g_emb, ref_emb)

            if sim > max_sim:
                max_sim = sim
                best_id = sid

        if max_sim >= threshold:
            present_ids.append(best_id)

    return group_img, present_ids