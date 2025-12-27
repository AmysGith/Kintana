FROM python:3.12-slim

# Installer Tesseract et Poppler
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-fra \
    tesseract-ocr-eng \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier les dépendances
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code
COPY backend.py .

# Port dynamique Render
ENV PORT=5000
EXPOSE $PORT

# Lancer avec gunicorn
CMD gunicorn backend:app --bind 0.0.0.0:$PORT --workers 2 --timeout 120