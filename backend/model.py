import cv2
import numpy as np
import torch
from PIL import Image

# ✅ SAFE IMPORT (IMPORTANT)
try:
    from utils import detector, encoder
    from config import DEVICE
except:
    from backend.utils import detector, encoder
    from backend.config import DEVICE


def process_attendance(group_img, database, threshold):

    img_rgb = cv2.cvtColor(group_img, cv2.COLOR_BGR2RGB)
    img_pil = Image.fromarray(img_rgb)

    boxes, _ = detector.detect(img_pil)
    faces = detector(img_pil)

    present_ids = []

    # ✅ FIX: handle no face case
    if faces is None or boxes is None:
        print("No faces detected")
        return group_img, []

    faces = faces.to(DEVICE)

    with torch.no_grad():
        embeddings = encoder(faces).cpu().numpy()

    # Normalize embeddings
    embeddings = embeddings / np.linalg.norm(embeddings, axis=1, keepdims=True)

    for i, g_emb in enumerate(embeddings):

        best_id = "Unknown"
        max_sim = -1

        for sid, ref_emb in database.items():
            sim = np.dot(g_emb, ref_emb)

            if sim > max_sim:
                max_sim = sim
                best_id = sid

        print("Matched Student:", best_id, "| Similarity:", max_sim)

        if max_sim >= threshold:
            present_ids.append(best_id)

        # ✅ SAFE BOX DRAW
        if i < len(boxes):
            box = boxes[i].astype(int)

            color = (0, 255, 0) if max_sim >= threshold else (0, 0, 255)

            cv2.rectangle(
                group_img,
                (box[0], box[1]),
                (box[2], box[3]),
                color,
                2
            )

            cv2.putText(
                group_img,
                best_id,
                (box[0], box[1] - 10),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                color,
                2
            )

    return group_img, present_ids