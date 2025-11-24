from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings

VECTORSTORE_PATH = "./vectorstore"
embedding_model = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

def search_documents(query):
    vectorstore = FAISS.load_local(VECTORSTORE_PATH, embedding_model, allow_dangerous_deserialization=True)
    retriever = vectorstore.as_retriever(search_type="similarity", search_kwargs={"k": 3})
    results = retriever.invoke(query)  
    parsed = []
    for doc in results:
        parsed.append({
            "source": doc.metadata.get("source", "unknown"),
            "chunk": doc.metadata.get("chunk", -1),
            "text": doc.page_content
        })
    return parsed

if __name__ == "__main__":
    user_query = input("Ask something: ")
    chunks = search_documents(user_query)
    if not chunks:
        print("No relevant chunks found.")
    else:
        print("\nTop Relevant Chunks:\n")
        for c in chunks:
            print(f"From: {c['source']} [chunk #{c['chunk']}]")
            print("-" * 50)
            print(c['text'])
            print()