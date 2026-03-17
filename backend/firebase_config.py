import firebase_admin
from firebase_admin import credentials, firestore
import os, json

key = json.loads(os.environ["FIREBASE_KEY"])

cred = credentials.Certificate(key)
firebase_admin.initialize_app(cred)

db = firestore.client()