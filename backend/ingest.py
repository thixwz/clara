import os
import fitz  # PyMuPDF
from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document

PDF_FOLDER = "./data"
VECTORSTORE_DIR = "./vectorstore"

embedding_model = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)

def embed_and_store_text(new_text, source="ocr"):
    # Load or create vectorstore
    if os.path.exists(VECTORSTORE_DIR):
        vectorstore = FAISS.load_local(
            VECTORSTORE_DIR,
            embedding_model,
            allow_dangerous_deserialization=True  # <--- THIS FIXES THE ERROR
        )
    else:
        vectorstore = None

    # Split and embed new text
    chunks = text_splitter.split_text(new_text)
    docs = [Document(page_content=chunk, metadata={"source": source, "chunk": i}) for i, chunk in enumerate(chunks)]

    if vectorstore:
        vectorstore.add_documents(docs)
    else:
        vectorstore = FAISS.from_documents(docs, embedding_model)

    vectorstore.save_local(VECTORSTORE_DIR)

# --- Initial PDF ingest (run once to build base vectorstore) ---
if __name__ == "__main__":
    documents = []
    print("Reading PDFs from:", PDF_FOLDER)
    for filename in os.listdir(PDF_FOLDER):
        if filename.endswith(".pdf"):
            file_path = os.path.join(PDF_FOLDER, filename)
            print(f" → Processing {filename}")
            doc = fitz.open(file_path)
            full_text = ""
            for page in doc:
                full_text += page.get_text()
            doc.close()
            chunks = text_splitter.split_text(full_text)
            for i, chunk in enumerate(chunks):
                documents.append(Document(
                    page_content=chunk,
                    metadata={"source": filename, "chunk": i}
                ))
    if not documents:
        print("No extractable text found in PDFs.")
        exit()
    print("Generating FAISS index...")
    vectorstore = FAISS.from_documents(documents, embedding_model)
    os.makedirs(VECTORSTORE_DIR, exist_ok=True)
    vectorstore.save_local(VECTORSTORE_DIR)
    print(f"Stored {len(documents)} chunks in vectorstore: {VECTORSTORE_DIR}")