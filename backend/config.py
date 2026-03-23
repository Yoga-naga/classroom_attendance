import torch

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

MATCH_THRESHOLD = 0.40