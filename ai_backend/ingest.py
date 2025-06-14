# ingest.py

import os
import fitz  # PyMuPDF
from langchain.text_splitter import RecursiveCharacterTextSplitter
from sentence_transformers import SentenceTransformer
import faiss
import pickle

# === Paths ===
PDF_FOLDER = "./data"
INDEX_FILE = "./vectorstore/index.faiss"
METADATA_FILE = "./vectorstore/docs.pkl"

# === Load embedding model ===
print("⏳ Loading embedding model...")
model = SentenceTransformer("all-MiniLM-L6-v2")

# === For storing text and metadata ===
texts = []
metadatas = []

# === PDF Reading & Chunking ===
print("Reading PDFs...")
for filename in os.listdir(PDF_FOLDER):
    if filename.endswith(".pdf"):
        path = os.path.join(PDF_FOLDER, filename)
        doc = fitz.open(path)
        full_text = ""
        for page in doc:
            full_text += page.get_text()
        doc.close()

        # Smart character-based chunking
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=500,
            chunk_overlap=50
        )
        chunks = text_splitter.split_text(full_text)

        for i, chunk in enumerate(chunks):
            clean_chunk = chunk.strip()
            if clean_chunk:
                texts.append(clean_chunk)
                metadatas.append({
                    "source": filename,
                    "chunk": i,
                    "text": clean_chunk  # ✅ Fixed line
                })

# === Generate Embeddings ===
print("🧠 Generating embeddings...")
if len(texts) == 0:
    print("No chunks found. Check if your PDF has extractable text.")
    exit()

embeddings = model.encode(texts)

# === Create & Save FAISS Index ===
print("Saving FAISS index and metadata...")
dimension = embeddings[0].shape[0]
index = faiss.IndexFlatL2(dimension)
index.add(embeddings)

# Ensure vectorstore directory exists
os.makedirs(os.path.dirname(INDEX_FILE), exist_ok=True)

faiss.write_index(index, INDEX_FILE)
with open(METADATA_FILE, "wb") as f:
    pickle.dump(metadatas, f)

print(f"Stored {len(texts)} chunks in FAISS index.")
