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

# Installa dipendenze LightRAG
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

# Copia lo script di avvio dal repository
COPY start_service.py /app/start_service.py

# Rendi eseguibile lo script
RUN chmod +x /app/start_service.py

# Crea directory per i dati
RUN mkdir -p /app/data /app/models

# Imposta variabili d'ambiente
ENV PYTHONPATH="/app/lightrag:/app/rag-anything"
ENV PYTHONUNBUFFERED=1

# Esponi la porta
EXPOSE 9621

# Comando di avvio
CMD ["python", "/app/start_service.py"]
