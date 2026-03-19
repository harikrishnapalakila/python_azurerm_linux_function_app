#RAG system, you need a script that reads your text, generates embeddings for each chunk, and saves them to Cosmos DB MongoDB vCore.

import uuid

def upsert_documents(documents):
    """
    Takes a list of text strings, generates embeddings, and uploads to MongoDB.
    'documents' example: ["Azure AI Search is great.", "Cosmos DB vCore supports vectors."]
    """
    for text in documents:
        # 1. Generate the embedding for the chunk
        embedding = get_embedding(text) # Uses the function from the previous script
        
        # 2. Create the document structure
        document = {
            "id": str(uuid.uuid4()),      # Unique identifier
            "content": text,              # The raw text for the LLM context
            "contentVector": embedding,   # The 1536-dimension vector
            "metadata": {
                "source": "manual_upload",
                "category": "technical_docs"
            }
        }
        
        # 3. Upsert into MongoDB (Update if ID exists, otherwise Insert)
        collection.update_one(
            {"id": document["id"]}, 
            {"$set": document}, 
            upsert=True
        )
        
    print(f"Successfully upserted {len(documents)} documents.")

# Example Execution
sample_data = [
    "Azure Cosmos DB for MongoDB vCore is a fully managed database for AI apps.",
    "Vector search allows you to find documents based on semantic meaning rather than keywords.",
    "The text-embedding-3-small model from OpenAI produces 1536 dimensions."
]

upsert_documents(sample_data)




#Important Implementation Details
#Batching: If you have thousands of documents, don't upload them one by one. Use collection.insert_many() to improve performance significantly.
#Chunking: For large PDFs or files, ensure you split the text into smaller chunks (e.g., 500–1000 tokens) before generating embeddings. Large blocks of text reduce the accuracy of the vector search.
#Index Refresh: In MongoDB vCore, once you upsert documents, the cosmosSearch index updates automatically, but there may be a slight lag (seconds) before they are searchable.
#Error Handling: Wrap the get_embedding call in a try-except block to handle Rate Limits (429 errors) from Azure OpenAI.
#Final Configuration Check
#Ensure your MongoDB Index was created with these exact settings:
#Path: contentVector
#Dimensions: 1536 (if using text-embedding-3-small or ada-002)
#Similarity: COS (Cosine)


########### function to chunk large text files before upserting them ####################