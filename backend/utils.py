import cv2
import numpy as np
import torch
from PIL import Image

# ✅ SAFE IMPORT
try:
    from config import DEVICE
except:
    from backend.config import DEVICE

from facenet_pytorch import MTCNN, InceptionResnetV1


# =========================
# FACE DETECTOR
# =========================
detector = MTCNN(
    image_size=160,
    margin=20,
    keep_all=True,
    device=DEVICE
)

# =========================
# FACE ENCODER
# =========================
encoder = InceptionResnetV1(
    pretrained='vggface2'
).eval().to(DEVICE)


# =========================
# GET EMBEDDING
# =========================
def get_embedding(img):

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_pil = Image.fromarray(img_rgb)

    face = detector(img_pil)

    # ✅ FIX: handle no face
    if face is None:
        return None

    # If multiple faces → take first
    if len(face.shape) == 4:
        face = face[0]

    face = face.unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        emb = encoder(face)

    emb = emb.cpu().numpy()[0]

    # Normalize
    emb = emb / np.linalg.norm(emb)

    return emb