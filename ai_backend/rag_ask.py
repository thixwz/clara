import subprocess
from query import search_documents

# === Step 1: Generate the RAG Prompt ===
def generate_prompt(query):
    results = search_documents(query)
    if not results:
        return None

    context = "\n\n".join([r["text"].strip().replace("\n", " ") for r in results])

    prompt = f"""You are a medical assistant.
Based on the following patient information, answer this question:

### Patient Information:
{context}

### Question:
{query}

### Answer:"""

    return prompt

# === Step 2: Send Prompt to MedAlpaca using llama-run.exe ===
def ask_medalpaca(prompt):
    llama_path = "C:/Users/ASUS/Documents/MedAI/ai_backend/llama.cpp/build/bin/Release/llama-run.exe"
    model_path = "C:/Users/ASUS/Documents/MedAI/ai_backend/models/medalpaca.gguf"

    # Build command using file:// for llama-run compatibility
    command = [
        llama_path,
        f"file://{model_path}", 
        "--temp","0.7",
        "-t","4",
        "--n-predict","256",
          # ✅ key fix here
        prompt
    ]

    print("\n Sending to MedAlpaca...")
    print(" Running command:")
    print(" ".join(f'"{arg}"' if " " in arg else arg for arg in command))

    # Run command and return output
    result = subprocess.run(command, capture_output=True, text=True)
    return result.stdout

# === Step 3: Main CLI Loop ===
if __name__ == "__main__":
    query = input(" Ask MedAI: ")
    prompt = generate_prompt(query)

    if prompt:
        answer = ask_medalpaca(prompt)
        print("\n MedAlpaca Answer:\n")
        print(answer)
    else:
        print("No relevant chunks found.")
