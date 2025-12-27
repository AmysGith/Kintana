from flask import Flask, request, jsonify
from flask_cors import CORS
import pytesseract
from pdf2image import convert_from_path
import os
import requests
import re
from dotenv import load_dotenv

# Firebase Admin
from firebase_admin import credentials, auth, initialize_app

# =====================
# INITIALISATION
# =====================

load_dotenv()

app = Flask(__name__)
CORS(app)

# =====================
# CONFIG GEMINI
# =====================

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise RuntimeError("❌ GEMINI_API_KEY manquante")

GEMINI_API_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    f"gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}"
)

# =====================
# FIREBASE ADMIN
# =====================

firebase_app = None

try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_app = initialize_app(cred)
    print("✅ Firebase Admin SDK initialisé")
except Exception as e:
    print(f"❌ Firebase Admin indisponible: {e}")
    firebase_app = None

# =====================
# OCR / PDF
# =====================

PDF_PATH = "doc.pdf"
PDF_TEXT = None  # lazy-load

def read_pdf_ocr(pdf_path: str) -> str:
    print("📖 OCR du PDF en cours...")
    pages_text = []

    pages = convert_from_path(pdf_path)

    for i, page in enumerate(pages):
        print(f"🔍 OCR page {i + 1}")
        text = pytesseract.image_to_string(page, lang="eng+fra")
        pages_text.append(text)

    full_text = "\n\n=== PAGE BREAK ===\n\n".join(pages_text)
    print(f"✅ OCR terminé ({len(full_text)} caractères)")
    return full_text


def get_pdf_text() -> str:
    global PDF_TEXT
    if PDF_TEXT is None:
        PDF_TEXT = read_pdf_ocr(PDF_PATH)
    return PDF_TEXT


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
# ROUTES
# =====================

@app.route("/debug-pdf", methods=["GET"])
def debug_pdf():
    text = get_pdf_text()
    return jsonify({
        "pdf_length": len(text),
        "preview": text[:2000]
    })


@app.route("/ask", methods=["POST"])
def ask():
    data = request.get_json()
    question = data.get("question", "").strip()

    if not question:
        return jsonify({"error": "Question vide"}), 400

    if contains_personal_info(question):
        return jsonify({
            "answer": "Attention, ne partage pas d'informations personnelles."
        })

    if contains_alert_keywords(question):
        return jsonify({
            "answer": "Parle-en à un adulte de confiance. Je ne peux pas aider sur ce sujet."
        })

    pdf_text = get_pdf_text()
    max_chars = 400_000
    context = pdf_text[:max_chars]

    body = {
        "contents": [
            {
                "parts": [
                    {
                        "text": f"""
You are a medical assistant.
Answer ONLY using the provided PDF content.
If the answer is not in the PDF, say:
"Je ne peux pas répondre à ce genre de questions."

PDF CONTENT:
{context}

QUESTION:
{question}

ANSWER:
"""
                    }
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 1000
        }
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
        "status": "ok"
    })
