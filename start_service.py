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

# Variabile globale per LightRAG
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
