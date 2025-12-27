FROM python:3.12-slim

# Installer Poppler et Tesseract
RUN apt-get update && apt-get install -y \
    poppler-utils \
    tesseract-ocr \
    tesseract-ocr-fra \
    tesseract-ocr-eng \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copier ton code
WORKDIR /app
COPY . /app

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Démarrer l'application
CMD ["gunicorn", "backend:app", "-b", "0.0.0.0:5000"]
