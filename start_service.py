#!/usr/bin/env python3
import os
import sys
import subprocess

# Imposta le variabili d'ambiente necessarie
os.environ['LIGHTRAG_WORKING_DIR'] = '/app/data'
os.environ['LIGHTRAG_LOG_DIR'] = '/app/logs'

# Crea le directory necessarie
os.makedirs('/app/data', exist_ok=True)
os.makedirs('/app/logs', exist_ok=True)

# Verifica se la chiave OpenAI è configurata
if not os.environ.get('OPENAI_API_KEY'):
    print("⚠️  ATTENZIONE: OPENAI_API_KEY non configurata!")
    print("Aggiungi la variabile OPENAI_API_KEY nelle impostazioni Railway")
    print("Il server partirà comunque ma le query non funzioneranno senza la chiave API")
    print("-" * 50)

# Avvia il server LightRAG nativo
print("=" * 50)
print("🚀 Avvio LightRAG Server Nativo")
print("=" * 50)
print(f"📁 Working Directory: /app/data")
print(f"📝 Log Directory: /app/logs")
print(f"🌐 Server in ascolto su porta 9621")
print("=" * 50)

# Cambia directory a lightrag
os.chdir('/app/lightrag')

# Avvia il server usando subprocess (metodo più affidabile)
subprocess.run([
    sys.executable, '-m', 'lightrag.api.lightrag_server',
    '--host', '0.0.0.0',
    '--port', '9621',
    '--llm-binding', 'openai',
    '--llm-model', 'gpt-4o-mini',
    '--embedding-binding', 'openai',
    '--embedding-model', 'text-embedding-3-small',
    '--working-dir', '/app/data',
    '--input-dir', '/app/data/inputs'
])
