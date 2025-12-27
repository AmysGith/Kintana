from flask import Flask, request, jsonify
import pytesseract
from pdf2image import convert_from_path
import os
import requests
from flask_cors import CORS
import re
from dotenv import load_dotenv

load_dotenv()
load_dotenv()


app = Flask(__name__)
CORS(app)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}"

# 🧪 Test (à supprimer après)
print(f"✅ Clé chargée : {GEMINI_API_KEY[:10]}..." if GEMINI_API_KEY else "❌ Clé non trouvée !")
# Chemins
PDF_PATH = "doc.pdf"
POPLER_PATH = r"C:\Users\NOMENAHITANTSOA\Downloads\Release-25.07.0-0\poppler-25.07.0\Library\bin"
TESSERACT_CMD = r"C:\Users\NOMENAHITANTSOA\AppData\Local\Programs\Tesseract-OCR\tesseract.exe"


pytesseract.pytesseract.tesseract_cmd = TESSERACT_CMD

def contains_personal_info(text):
    patterns = [
        r"je m'?appelle\s+\w+",       # "je m'appelle Alice"
        r"j'ai\s+\d+\s*ans",          # "j'ai 20 ans"
        r"j'ai\s+\d+\s*mois",         # "j'ai 8 mois"
        r"(mon adresse|j'habite à)\s+[\w\s\d]+",  # "mon adresse est 12 rue X"
        r"(mon email|mon e-?mail)\s+[\w\.\-]+@[\w\.\-]+\.\w+",  # email
        r"(mon numéro|mon téléphone|tél)\s+[\d\s]+",            # téléphone
    ]
    return any(re.search(pattern, text, re.IGNORECASE) for pattern in patterns)

def contains_alert_keywords(text):
    alert_patterns = [
        r"suicid",                   # couvre "suicide", "suicidaires", etc.
        r"idées?\s+suicidaires?",    # "idée suicidaire", "idées suicidaires"
        r"automutil",                # "automutilation", "automutilé", etc.
        r"dépression",               # "dépression"
        r"je veux me tuer",
        r"je n'en peux plus",
        r"je me fais du mal",
        r"en finir",                 # "en finir avec la vie"
        r"idées noires",
    ]
    return any(re.search(pattern, text, re.IGNORECASE) for pattern in alert_patterns)


def read_pdf_ocr(pdf_path):
    print("📖 Lecture du PDF...")
    pages_text = []


    print("🖼️ Conversion du PDF en images...")
    pages = convert_from_path(pdf_path, poppler_path=POPLER_PATH)
    print(f"✅ {len(pages)} page(s) convertie(s)")


    for i, page in enumerate(pages):
        print(f"🔍 Extraction texte page {i+1}...")
        # ✅ Essaie avec plusieurs langues si c'est un PDF français
        page_text = pytesseract.image_to_string(page, lang="eng+fra")  
        pages_text.append(page_text)
        print(f"   Caractères extraits: {len(page_text)}")


    full_text = "\n\n=== PAGE BREAK ===\n\n".join(pages_text)
    print(f"✅ Texte total extrait: {len(full_text)} caractères")
   
    # Affiche un aperçu
    print(f"📄 Aperçu du texte:\n{full_text[:500]}\n...")
   
    return full_text


# Lire le PDF au démarrage
PDF_TEXT = read_pdf_ocr(PDF_PATH)


@app.route("/debug-pdf", methods=["GET"])
def debug_pdf():
    """Affiche le texte extrait du PDF pour debug"""
    return jsonify({
        "pdf_length": len(PDF_TEXT),
        "pdf_preview": PDF_TEXT[:2000],
        "total_chars": len(PDF_TEXT),
        "contains_endometriosis": "endometriosis" in PDF_TEXT.lower()
    })


@app.route("/ask", methods=["POST"])
def ask():
    data = request.get_json()
    question = data.get("question", "").strip()
   
    if not question:
        return jsonify({"error": "Question vide"}), 400

    if contains_personal_info(question):
        return jsonify({"answer": "Attention, pour ta sécurité, ne diffuse pas d'informations personnelles te concernant"})

    # Mots sensibles
    if contains_alert_keywords(question):
        print(f"⚠️ ALERT: mot sensible détecté: {question}")
        return jsonify({"answer": "Si tu ne te sens pas bien, c'est toujours mieux d'en parler à un adulte de confiance qu'une machine! ;)"})
    # ✅ Tronquer le PDF si trop long
    max_chars = 400000
    pdf_content = PDF_TEXT if len(PDF_TEXT) <= max_chars else PDF_TEXT[:max_chars] + "\n\n[...TRUNCATED...]"
   
    print(f"📊 Longueur du contexte envoyé: {len(pdf_content)} caractères")

    # 🔹 Préparer la requête Gemini comme avant
    body = {
        "contents": [
            {
                "parts": [
                    {
                        "text": f"""You are a medical assistant that answers questions ONLY based on the provided PDF document about endometriosis.

INSTRUCTIONS:
- Answer the question using ONLY information from the PDF below.
- Give only a concise definition or short answer. Do NOT provide long explanations.
- If the PDF contains the answer, provide a short definition.
- If the information is not in the PDF, say: "Je ne peux pas répondre à ce genre de questions, restez dans le thème que l'instructeur a donné s'il vous plait"

PDF DOCUMENT CONTENT:
{pdf_content}

USER QUESTION: {question}

ANSWER:"""
                    }
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 1000,
            "topP": 0.95,
            "topK": 40
        }
    }

    try:
        print(f"📤 Envoi de la question à Gemini: {question}")
        response = requests.post(GEMINI_API_URL, json=body, timeout=60)
        response.raise_for_status()
        result = response.json()
       
        answer = result["candidates"][0]["content"]["parts"][0]["text"]
        print(f"✅ Réponse reçue ({len(answer)} chars): {answer[:200]}...")
       
    except requests.exceptions.HTTPError as e:
        print(f"❌ Erreur HTTP {response.status_code}: {e}")
        print(f"📄 Réponse API: {response.text}")
        answer = "Error: Unable to generate response."
    except KeyError as e:
        print(f"❌ Erreur de structure: {e}")
        print(f"📄 Réponse complète: {result}")
        answer = "Error: Unexpected API response format."
    except Exception as e:
        print(f"❌ Erreur: {e}")
        answer = f"Error: {str(e)}"

    return jsonify({"answer": answer})



if __name__ == "__main__":
    print("✅ Utilisation du modèle: gemini-2.5-flash")
    print("🚀 Backend démarré sur http://127.0.0.1:5000")
    app.run(host="0.0.0.0", port=5000, debug=True)



