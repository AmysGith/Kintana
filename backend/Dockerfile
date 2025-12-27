# Utilise Python 3.12 slim (plus récent)
FROM python:3.12-slim

# Installer Tesseract et Poppler pour l'OCR
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-fra \
    tesseract-ocr-eng \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier uniquement les fichiers nécessaires
COPY backend.py requirements.txt doc.pdf ./

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Exposer le port attendu par Flask
EXPOSE 5000

# Lancer le backend Flask
CMD ["python", "backend.py"]
