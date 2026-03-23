import cv2
import numpy as np
import torch
from PIL import Image

# ✅ FIXED IMPORT
from backend.config import DEVICE

from facenet_pytorch import MTCNN, InceptionResnetV1


# DETECTOR
detector = MTCNN(
    image_size=160,
    margin=20,
    keep_all=True,
    device=DEVICE
)

# ENCODER
encoder = InceptionResnetV1(
    pretrained='vggface2'
).eval().to(DEVICE)


def get_embedding(img):

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_pil = Image.fromarray(img_rgb)

    face = detector(img_pil)

    if face is None:
        return None

    if len(face.shape) == 4:
        face = face[0]

    face = face.unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        emb = encoder(face)

    emb = emb.cpu().numpy()[0]
    emb = emb / np.linalg.norm(emb)

    return emb