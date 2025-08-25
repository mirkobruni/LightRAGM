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

# Aggiorna pip
RUN pip install --upgrade pip

# Clona LightRAG
RUN git clone https://github.com/HKUDS/LightRAG.git /app/lightrag

# Clona RAG-Anything
RUN git clone https://github.com/HKUDS/RAG-Anything.git /app/rag-anything

# Installa dipendenze LightRAG direttamente (senza requirements.txt)
RUN pip install --no-cache-dir \
    nano-vectordb \
    networkx \
    graspologic-native \
    tenacity \
    pydantic \
    xxhash \
    tiktoken \
    scipy \
    fastapi \
    uvicorn \
    openai \
    python-dotenv \
    numpy

# Installa dipendenze RAG-Anything
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir \
    transformers \
    sentence-transformers \
    opencv-python-headless \
    pillow \
    pandas

# Installa Flask per l'API
RUN pip install flask

# Crea script di integrazione
WORKDIR /app
RUN cat > /app/start_service.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import json
from flask import Flask, jsonify, request

# Aggiungi i percorsi
sys.path.append("/app/lightrag")
sys.path.append("/app/rag-anything")

# Configurazione directory
WORKING_DIR = "/app/data"
if not os.path.exists(WORKING_DIR):
    os.makedirs(WORKING_DIR)

# Inizializza Flask
app = Flask(__name__)

# Variabile globale per LightRAG (inizializzata on-demand)
rag = None

def init_lightrag():
    global rag
    if rag is None:
        try:
            from lightrag import LightRAG
            from lightrag.llm import gpt_4o_mini_complete
            
            rag = LightRAG(
                working_dir=WORKING_DIR,
                llm_model_func=gpt_4o_mini_complete
            )
            print("LightRAG inizializzato con successo!")
            return True
        except Exception as e:
            print(f"Errore inizializzazione LightRAG: {e}")
            return False
    return True

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "LightRAG + RAG-Anything Server Attivo",
        "version": "1.0",
        "endpoints": {
            "/": "Status del server",
            "/query": "POST - Esegui query",
            "/insert": "POST - Inserisci testo",
            "/health": "GET - Health check"
        }
    })

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/query", methods=["POST"])
def query():
    if not init_lightrag():
        return jsonify({"error": "LightRAG non inizializzato"}), 500
    
    try:
        data = request.json
        query_text = data.get("query", "")
        mode = data.get("mode", "hybrid")
        
        from lightrag import QueryParam
        param = QueryParam(mode=mode)
        result = rag.query(query_text, param=param)
        
        return jsonify({"result": result, "status": "success"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/insert", methods=["POST"])
def insert():
    if not init_lightrag():
        return jsonify({"error": "LightRAG non inizializzato"}), 500
    
    try:
        data = request.json
        text = data.get("text", "")
        
        if not text:
            return jsonify({"error": "Nessun testo fornito"}), 400
        
        rag.insert(text)
        return jsonify({"status": "success", "message": "Testo inserito correttamente"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print("=" * 50)
    print("LightRAG + RAG-Anything Server")
    print("=" * 50)
    print(f"Working directory: {WORKING_DIR}")
    print(f"Avvio server su porta 9621...")
    print("=" * 50)
    
    # Avvia il server Flask
    app.run(host="0.0.0.0", port=9621, debug=False)
EOF

# Rendi eseguibile lo script
RUN chmod +x /app/start_service.py

# Crea directory per i dati
RUN mkdir -p /app/data /app/models

# Imposta variabili d'ambiente
ENV PYTHONPATH="/app/lightrag:/app/rag-anything"
ENV LIGHTRAG_DIR="/app/lightrag"
ENV RAG_ANYTHING_DIR="/app/rag-anything"
ENV PYTHONUNBUFFERED=1

# Esponi la porta
EXPOSE 9621

# Comando di avvio
CMD ["python", "/app/start_service.py"]
