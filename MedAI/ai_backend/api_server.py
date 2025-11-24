# api_server.py

import os
import time
import shutil
import subprocess
import mimetypes
import datetime
import uuid
from typing import Optional, List

import fitz  # PyMuPDF
from pymongo import MongoClient, ASCENDING, DESCENDING
from fastapi import FastAPI, HTTPException, UploadFile, File, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from ocr_services import process_image_file
from ingest import embed_and_store_text
from query import search_documents

# ------------------------------------------------------------------------------
# FastAPI app
# ------------------------------------------------------------------------------
app = FastAPI(title="Clara Medical AI API")

# ------------------------------------------------------------------------------
# MongoDB (Atlas)
# ------------------------------------------------------------------------------
MONGO_URI = os.getenv(
    "MONGO_URI",
    "mongodb+srv://clarathiirez:articmonkeys@clara.qmss4jf.mongodb.net/?retryWrites=true&w=majority&appName=clara",
)
client = MongoClient(MONGO_URI)
db = client["clara_db"]
chats_collection = db["chat_history"]
uploads_collection = db["uploads_meta"]

# Helpful indexes (idempotent)
chats_collection.create_index([("user_id", ASCENDING)])
chats_collection.create_index([("session_id", ASCENDING)])
chats_collection.create_index([("timestamp", DESCENDING)])

# ------------------------------------------------------------------------------
# CORS (open for dev)
# ------------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------------------------
# Models
# ------------------------------------------------------------------------------
class AskRequest(BaseModel):
    query: str
    user_id: str = "default"
    session_id: Optional[str] = None  # if none, server will create one

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
def save_upload_to_temp(file: UploadFile) -> str:
    temp_dir = "temp_uploads"
    os.makedirs(temp_dir, exist_ok=True)
    filename = f"{int(time.time())}_{file.filename.replace(' ', '_')}"
    file_path = os.path.join(temp_dir, filename)
    with open(file_path, "wb") as out:
        shutil.copyfileobj(file.file, out)
    return file_path

def extract_text_from_pdf(pdf_path: str) -> str:
    try:
        doc = fitz.open(pdf_path)
        full_text = "".join(page.get_text() for page in doc)
        doc.close()
        return full_text
    except Exception as e:
        print("PDF extraction error:", e)
        return ""

def get_recent_messages(user_id: str, session_id: str, limit: int = 4) -> List[dict]:
    # last N turns (message + response)
    msgs = list(
        chats_collection.find(
            {"user_id": user_id, "session_id": session_id}
        ).sort("timestamp", DESCENDING).limit(limit)
    )
    msgs.reverse()  # chronological
    return msgs

def generate_prompt(query: str, user_id: str, session_id: str) -> Optional[str]:
    # RAG context
    rag_results = search_documents(query)
    if not rag_results:
        return None
    context = "\n\n".join(
        f"- {r['text'].strip().replace(chr(10), ' ')}" for r in rag_results
    )

    # Conversation memory (last N)
    history = get_recent_messages(user_id, session_id, limit=4)
    hist_text = ""
    if history:
        parts = []
        for h in history:
            parts.append(f"User: {h.get('message','')}")
            parts.append(f"Assistant: {h.get('response','')}")
        hist_text = "\n".join(parts)

    prompt = (
        "You are a helpful medical AI. Treat the following as simulated/educational data.\n"
        "Use the context and the recent conversation to answer clearly and concisely.\n\n"
        f"### Conversation (recent):\n{hist_text if hist_text else '(none)'}\n\n"
        "### Patient Data (context from documents):\n"
        f"{context}\n\n"
        "### Question:\n"
        f"{query}\n\n"
        "### Answer:"
    )
    return prompt

def ask_medalpaca(prompt: str) -> Optional[str]:
    llama_exec = r"C:\Users\ASUS\Documents\CLARA\MedAI\ai_backend\llama.cpp\build\bin\Release\llama-run.exe"
    model_path = r"C:\Users\ASUS\Documents\CLARA\MedAI\ai_backend\models\medalpaca.gguf"
    cmd = [
        llama_exec,
        f"file://{model_path}",
        "--temp", "0.7",
        "-t", "4",
        "--n-predict", "16",   # keep small for speed
        "--ngl", "20",
        "--", prompt,
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        print("LLAMA STDOUT:", proc.stdout)
        print("LLAMA STDERR:", proc.stderr)
        if proc.returncode != 0:
            return None
        return proc.stdout.strip()
    except Exception as e:
        print("Error calling MedAlpaca:", e)
        return None

# ------------------------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------------------------

@app.post("/api/chat")
async def chat(request: AskRequest):
    # ensure session_id
    session_id = request.session_id or str(uuid.uuid4())

    prompt = generate_prompt(request.query, request.user_id, session_id)
    if prompt is None:
        raise HTTPException(status_code=400, detail="No relevant data found.")

    answer = ask_medalpaca(prompt)
    if answer is None:
        raise HTTPException(status_code=500, detail="Model generation failed.")

    # Save turn to MongoDB
    chats_collection.insert_one(
        {
            "user_id": request.user_id,
            "session_id": session_id,
            "message": request.query,
            "response": answer,
            "timestamp": datetime.datetime.utcnow(),
        }
    )

    return {"answer": answer, "session_id": session_id}

@app.get("/api/history")
def get_history(
    user_id: Optional[str] = Query(default=None),
    session_id: Optional[str] = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
):
    q = {}
    if user_id:
        q["user_id"] = user_id
    if session_id:
        q["session_id"] = session_id

    chats = list(chats_collection.find(q).sort("timestamp", DESCENDING).limit(limit))
    for chat in chats:
        chat["_id"] = str(chat["_id"])
        chat["timestamp"] = chat["timestamp"].isoformat()
    return chats

@app.get("/api/sessions")
def list_sessions(user_id: str):
    # return distinct session_ids for a user with last timestamp and last message
    session_ids = chats_collection.distinct("session_id", {"user_id": user_id})
    out = []
    for sid in session_ids:
        last = chats_collection.find({"user_id": user_id, "session_id": sid}).sort("timestamp", DESCENDING).limit(1)
        last = list(last)
        if last:
            item = last[0]
            out.append(
                {
                    "session_id": sid,
                    "last_message": item.get("message", ""),
                    "last_response": item.get("response", ""),
                    "timestamp": item["timestamp"].isoformat(),
                }
            )
    # newest first
    out.sort(key=lambda x: x["timestamp"], reverse=True)
    return out

@app.post("/api/ocr")
async def process_ocr(file: UploadFile = File(...)):
    # Save uploaded image temporarily
    file_path = save_upload_to_temp(file)

    # OCR
    ocr_res = process_image_file(file_path, save_to=file_path + ".txt")
    cleaned = ocr_res.get("cleaned_text", "")
    fields = ocr_res.get("fields", {})

    # Cleanup
    try:
        os.remove(file_path)
    except OSError:
        pass

    # Update FAISS with OCR text
    if cleaned:
        embed_and_store_text(cleaned, source="ocr")

    return {"status": "success", "type": "image", "cleaned_text": cleaned, "fields": fields}

@app.post("/api/upload")
async def upload_file(file: UploadFile = File(...), user_id: str = Query(default="default")):
    """
    Accepts a PDF or image file.
    - If PDF: extracts text, chunks, embeds, stores in FAISS.
    - If image: runs OCR, cleans, chunks, embeds, stores in FAISS.
    Also stores simple upload metadata in MongoDB.
    """
    file_path = save_upload_to_temp(file)

    # Detect file type
    mime_type, _ = mimetypes.guess_type(file_path)
    result = {}

    if mime_type and mime_type.startswith("image"):
        # Image: OCR
        ocr_res = process_image_file(file_path, save_to=file_path + ".txt")
        cleaned = ocr_res.get("cleaned_text", "")
        if cleaned:
            embed_and_store_text(cleaned, source="ocr")
        result = {
            "status": "success",
            "type": "image",
            "cleaned_text": cleaned,
            "fields": ocr_res.get("fields", {}),
        }
        meta = {
            "user_id": user_id,
            "filename": file.filename,
            "type": "image",
            "text_length": len(cleaned),
            "uploaded_at": datetime.datetime.utcnow(),
        }
        uploads_collection.insert_one(meta)

    elif mime_type == "application/pdf" or file.filename.lower().endswith(".pdf"):
        # PDF
        text = extract_text_from_pdf(file_path)
        if text.strip():
            embed_and_store_text(text, source="pdf")
            result = {"status": "success", "type": "pdf", "text_length": len(text)}
            meta = {
                "user_id": user_id,
                "filename": file.filename,
                "type": "pdf",
                "text_length": len(text),
                "uploaded_at": datetime.datetime.utcnow(),
            }
            uploads_collection.insert_one(meta)
        else:
            result = {"status": "error", "message": "No extractable text found in PDF."}
    else:
        result = {"status": "error", "message": "Unsupported file type."}

    # Cleanup
    try:
        os.remove(file_path)
    except OSError:
        pass

    return result

@app.get("/")
def root():
    return {"message": "Clara API is live!"}