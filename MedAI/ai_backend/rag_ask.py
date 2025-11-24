import subprocess
import threading
import time
import sys
from query import search_documents

# === Step 1: Generate the RAG Prompt ===
def generate_prompt(query):
    results = search_documents(query)
    if not results:
        return None

    context = "\n\n".join([r["text"].strip().replace("\n", " ") for r in results])

    prompt = f"""You are a medical assistant.
Based on the following *simulated* patient information, answer this question. This is for educational purpose only.

### Patient Information:
{context}

### Question:
{query}

### Answer:"""

    return prompt

# === Step 2: Send Prompt to MedAlpaca using llama-run.exe ===
def ask_medalpaca(prompt, n_predict=64, show_spinner=True):
    llama_path = "C:/Users/ASUS/Documents/CLARA/MedAI/ai_backend/llama.cpp/build/bin/Release/llama-run.exe"
    model_path = "C:/Users/ASUS/Documents/CLARA/MedAI/ai_backend/models/medalpaca.gguf"

    # Build command using file:// for llama-run compatibility
    command = [
        llama_path,
        f"file://{model_path}", 
        "--temp","0.7",
        "-t","4",
        "--n-predict", "64",
        "--ngl","20",
        "--",
        prompt
    ]

    print("\n Sending to MedAlpaca...")
    print(" Running command:")
    print(" ".join(f'"{arg}"' if " " in arg else arg for arg in command))

    # Only show spinner if requested (CLI mode)
    done = False
    spin_thread = None
    
    if show_spinner:
        def spinner():
            while not done:
                for char in "|/-\\":
                    print(f"\r Thinking... {char}", end="", flush=True)
                    time.sleep(0.1)

        # Start spinner thread
        spin_thread = threading.Thread(target=spinner)
        spin_thread.start()

    # Run the model
    result = subprocess.run(command, capture_output=True, text=True)

    # Stop spinner if it was started
    if show_spinner and spin_thread:
        done = True
        spin_thread.join()
        print("\rDone generating response!          ")

    return result.stdout

# Function for API use
def query_rag(query, n_predict=64):
    """Function to be called from FastAPI endpoints"""
    prompt = generate_prompt(query)
    if prompt:
        return ask_medalpaca(prompt, n_predict, show_spinner=False)
    else:
        return "No relevant information found in the documents."

# === Step 3: Main CLI Loop ===
if __name__ == "__main__":
    # Check if arguments were passed
    if len(sys.argv) > 1:
        query = sys.argv[1]
        n_predict = int(sys.argv[2]) if len(sys.argv) > 2 else 64
    else:
        query = input(" Ask MedAI: ")
        n_predict = 64
        
    prompt = generate_prompt(query)

    if prompt:
        answer = ask_medalpaca(prompt, n_predict)
        print("\n MedAlpaca Answer:\n")
        print(answer)
    else:
        print("No relevant chunks found.")