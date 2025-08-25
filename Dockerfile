# Base image con Python
FROM python:3.10-slim

# Imposta directory di lavoro
WORKDIR /app

# Installa git e dipendenze di sistema
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Clona LightRAG
RUN git clone https://github.com/HKUDS/LightRAG.git /app/lightrag

# Clona RAG-Anything
RUN git clone https://github.com/HKUDS/RAG-Anything.git /app/rag-anything

# Installa dipendenze LightRAG
WORKDIR /app/lightrag
RUN pip install --no-cache-dir -r requirements.txt

# Installa dipendenze RAG-Anything
WORKDIR /app/rag-anything
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir transformers sentence-transformers
RUN pip install --no-cache-dir opencv-python-headless pillow numpy pandas

# Crea script di integrazione
WORKDIR /app
RUN echo '#!/usr/bin/env python3\n\
import sys\n\
import os\n\
sys.path.append("/app/lightrag")\n\
sys.path.append("/app/rag-anything")\n\
\n\
# Importa i moduli\n\
from lightrag import LightRAG, QueryParam\n\
from lightrag.llm import gpt_4o_mini_complete, gpt_4o_complete\n\
\n\
# Configurazione\n\
WORKING_DIR = "/app/data"\n\
\n\
if not os.path.exists(WORKING_DIR):\n\
    os.makedirs(WORKING_DIR)\n\
\n\
# Inizializza LightRAG\n\
rag = LightRAG(\n\
    working_dir=WORKING_DIR,\n\
    llm_model_func=gpt_4o_mini_complete\n\
)\n\
\n\
print("LightRAG + RAG-Anything inizializzato con successo!")\n\
print("Sistema pronto su porta 9621")\n\
\n\
# Mantieni il servizio attivo\n\
from flask import Flask, jsonify, request\n\
app = Flask(__name__)\n\
\n\
@app.route("/", methods=["GET"])\n\
def home():\n\
    return jsonify({"status": "LightRAG + RAG-Anything attivo", "version": "1.0"})\n\
\n\
@app.route("/query", methods=["POST"])\n\
def query():\n\
    data = request.json\n\
    query_text = data.get("query", "")\n\
    mode = data.get("mode", "hybrid")\n\
    \n\
    param = QueryParam(mode=mode)\n\
    result = rag.query(query_text, param=param)\n\
    \n\
    return jsonify({"result": result})\n\
\n\
@app.route("/insert", methods=["POST"])\n\
def insert():\n\
    data = request.json\n\
    text = data.get("text", "")\n\
    \n\
    rag.insert(text)\n\
    \n\
    return jsonify({"status": "success", "message": "Testo inserito"})\n\
\n\
if __name__ == "__main__":\n\
    app.run(host="0.0.0.0", port=9621)\n\
' > /app/start_service.py

# Installa Flask per l'API
RUN pip install flask

# Crea directory per i dati
RUN mkdir -p /app/data /app/models

# Imposta variabili d'ambiente
ENV PYTHONPATH="/app/lightrag:/app/rag-anything"
ENV LIGHTRAG_DIR="/app/lightrag"
ENV RAG_ANYTHING_DIR="/app/rag-anything"

# Esponi la porta
EXPOSE 9621

# Comando di avvio
CMD ["python", "/app/start_service.py"]
