# query.py

import faiss
import pickle
from sentence_transformers import SentenceTransformer
import numpy as np

# === Load FAISS and metadata ===
INDEX_PATH = "./vectorstore/index.faiss"
METADATA_PATH = "./vectorstore/docs.pkl"

print("Loading index and metadata...")
index = faiss.read_index(INDEX_PATH)

with open(METADATA_PATH, "rb") as f:
    metadata = pickle.load(f)

# === Load embedding model ===
model = SentenceTransformer("all-MiniLM-L6-v2")

def search_documents(query, top_k=3):
    query_vector = model.encode([query])
    distances, indices = index.search(query_vector, top_k)

    results = []
    for i in indices[0]:
        if i < len(metadata):
            results.append({
                "text_id": i,
                "source": metadata[i]['source'],
                "chunk": metadata[i]['chunk'],
                "text": metadata[i]['text']

            })

    return results

# === Load original chunks from ingest.py (rebuild from embeddings)
# If needed later, we can save all chunks to a separate .pkl file

if __name__ == "__main__":
    user_query = input("Ask something: ")
    results = search_documents(user_query)

    if not results:
        print("No relevant chunks found.")
    else:
        print("\n Top Relevant Chunks:\n")
        for r in results:
            print(f"From: {r['source']} [chunk #{r['chunk']}]")
            print("-" * 50)
            print(r['text'])
            print()
