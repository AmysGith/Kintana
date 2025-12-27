# backend.py
import os
import json
import base64
import re
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
from firebase_admin import credentials, auth, initialize_app, firestore
import urllib.request
from pdf2image import convert_from_path
import pytesseract

# =====================
# INITIALISATION
# =====================
app = Flask(__name__)
CORS(app)

# =====================
# FIREBASE ADMIN via variable d'environnement
# =====================
firebase_app = None
try:
    firebase_b64 = os.environ.get("FIREBASE_CREDENTIALS_B64")
    if firebase_b64:
        cred_dict = json.loads(base64.b64decode(firebase_b64).decode("utf-8"))
        cred = credentials.Certificate(cred_dict)
        firebase_app = initialize_app(cred)
        db = firestore.client()
        print("✅ Firebase Admin SDK initialisé")
    else:
        print("❌ FIREBASE_CREDENTIALS_B64 manquante")
except Exception as e:
    print(f"❌ Erreur Firebase Admin: {e}")

# =====================
# GEMINI API
# =====================
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise RuntimeError("❌ GEMINI_API_KEY manquante")

GEMINI_API_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    f"gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}"
)

# =====================
# PDF CONFIG
# =====================
PDF_PATH = "doc.pdf"
PDF_URL = "https://drive.google.com/uc?export=download&id=1DqplBzVyymKAcwWpIiS9B1gqhdVIQrrp"

# =====================
# FILTRES DE SÉCURITÉ
# =====================
def contains_personal_info(text: str) -> bool:
    patterns = [
        r"je m'?appelle\s+\w+",
        r"j'ai\s+\d+\s*ans",
        r"(mon adresse|j'habite à)",
        r"(mon email|mon e-?mail)",
        r"(mon numéro|mon téléphone|tél)",
    ]
    return any(re.search(p, text, re.IGNORECASE) for p in patterns)

def contains_alert_keywords(text: str) -> bool:
    patterns = [
        r"suicid",
        r"idées?\s+suicidaires?",
        r"automutil",
        r"dépression",
        r"je veux me tuer",
        r"je n'en peux plus",
        r"idées noires",
    ]
    return any(re.search(p, text, re.IGNORECASE) for p in patterns)

# =====================
# ENDPOINT /init
# =====================
def ocr_and_store():
    # Télécharger le PDF si absent
    if not os.path.exists(PDF_PATH):
        try:
            print("📥 Téléchargement du PDF depuis Drive...")
            urllib.request.urlretrieve(PDF_URL, PDF_PATH)
            print("✅ PDF téléchargé")
        except Exception as e:
            print(f"❌ Erreur téléchargement PDF: {e}")
            return None

    # OCR PDF
    try:
        pages = convert_from_path(PDF_PATH)
        text = "\n\n=== PAGE BREAK ===\n\n".join(
            [pytesseract.image_to_string(p, lang="eng+fra") for p in pages]
        )
        # Stocker dans Firestore
        db.collection("pdf_texts").document("medical_doc").set({"content": text})
        print("✅ Texte OCR stocké dans Firestore")
        return text
    except Exception as e:
        print(f"❌ Erreur OCR: {e}")
        return None

@app.route("/init", methods=["GET"])
def init():
    text = ocr_and_store()
    if text:
        return jsonify({"status": "ok", "length": len(text)})
    else:
        return jsonify({"status": "error"}), 500

# =====================
# GET PDF TEXT FROM FIRESTORE
# =====================
def get_pdf_text():
    try:
        doc_ref = db.collection("pdf_texts").document("medical_doc")
        doc = doc_ref.get()
        if doc.exists:
            return doc.to_dict().get("content", "")
        else:
            return "Document médical non disponible."
    except Exception as e:
        print(f"❌ Erreur récupération PDF Firestore: {e}")
        return "Document médical non disponible."

# =====================
# ROUTES
# =====================
@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "ok",
        "message": "KINTANA Backend API",
        "endpoints": ["/ask", "/init", "/admin/health"]
    })

@app.route("/ask", methods=["POST"])
def ask():
    data = request.get_json()
    question = data.get("question", "").strip()
    if not question:
        return jsonify({"error": "Question vide"}), 400
    if contains_personal_info(question):
        return jsonify({"answer": "Attention, ne partage pas d'informations personnelles."})
    if contains_alert_keywords(question):
        return jsonify({"answer": "Parle-en à un adulte de confiance. Je ne peux pas aider sur ce sujet."})

    pdf_text = get_pdf_text()
    context = pdf_text[:400_000]

    body = {
        "contents": [{"parts":[{"text": f"""
You are a medical assistant.
Answer ONLY using the provided PDF content.
If the answer is not in the PDF, say:
"Je ne peux pas répondre à ce genre de questions."

PDF CONTENT:
{context}

QUESTION:
{question}

ANSWER:
"""}]}],
        "generationConfig": {"temperature":0.1, "maxOutputTokens":1000}
    }

    try:
        response = requests.post(GEMINI_API_URL, json=body, timeout=60)
        response.raise_for_status()
        result = response.json()
        answer = result["candidates"][0]["content"]["parts"][0]["text"]
    except Exception as e:
        print(f"❌ Gemini error: {e}")
        answer = "Erreur lors de la génération de la réponse."

    return jsonify({"answer": answer})

# =====================
# ROUTES ADMIN
# =====================
@app.route("/admin/delete_student", methods=["POST"])
def delete_student():
    if not firebase_app:
        return jsonify({"error": "Firebase Admin indisponible"}), 500
    uid = request.json.get("uid")
    if not uid:
        return jsonify({"error": "UID manquant"}), 400
    try:
        auth.delete_user(uid)
        return jsonify({"success": True})
    except auth.UserNotFoundError:
        return jsonify({"error": "Utilisateur introuvable"}), 404

@app.route("/admin/reset_password", methods=["POST"])
def reset_password():
    if not firebase_app:
        return jsonify({"error": "Firebase Admin indisponible"}), 500
    data = request.json
    uid = data.get("uid")
    password = data.get("password")
    if not uid or not password:
        return jsonify({"error": "UID ou mot de passe manquant"}), 400
    try:
        auth.update_user(uid, password=password)
        return jsonify({"success": True})
    except auth.UserNotFoundError:
        return jsonify({"error": "Utilisateur introuvable"}), 404

@app.route("/admin/health", methods=["GET"])
def admin_health():
    return jsonify({
        "firebase_admin": firebase_app is not None, 
        "pdf_exists": os.path.exists(PDF_PATH),
        "status": "ok"
    })

# =====================
# LANCEMENT
# =====================
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"🚀 Backend démarré sur http://0.0.0.0:{port}")
    app.run(host="0.0.0.0", port=port, debug=False)
