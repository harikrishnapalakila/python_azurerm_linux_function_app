import os
from openai import AzureOpenAI
from pymongo import MongoClient

# 1. CONFIGURATION (Use Environment Variables for Security)
AOAI_ENDPOINT = "https://your-resource.openai.azure.com"
AOAI_KEY = "your-azure-openai-key"
AOAI_DEPLOYMENT = "text-embedding-3-small" # The 'Deployment Name' from AI Studio

MONGO_CONN_STR = "mongodb+srv://adminuser:Password@://cosmos-vcore-rag.mongocluster.azure.com..."
DB_NAME = "RAGMongoDatabase"
COLLECTION_NAME = "ChatHistory"

# 2. INITIALIZE CLIENTS
ai_client = AzureOpenAI(
    azure_endpoint=AOAI_ENDPOINT,
    api_key=AOAI_KEY,
    api_version="2024-12-01-preview"
)

mongo_client = MongoClient(MONGO_CONN_STR)
db = mongo_client[DB_NAME]
collection = db[COLLECTION_NAME]

def get_embedding(text):
    """Generates a vector embedding for the input text."""
    text = text.replace("\n", " ")
    response = ai_client.embeddings.create(input=[text], model=AOAI_DEPLOYMENT)
    return response.data[0].embedding

def vector_search(query_text, limit=3):
    """Converts text to vector and searches MongoDB vCore."""
    # Step A: Generate the vector for the user's question
    query_vector = get_embedding(query_text)

    # Step B: Execute the $search aggregation pipeline
    pipeline = [
        {
            "$search": {
                "cosmosSearch": {
                    "vector": query_vector,
                    "path": "contentVector", # Field name in your documents
                    "k": limit               # Number of matches
                },
                "returnStoredSource": True
            }
        },
        {
            "$project": {
                "score": { "$meta": "searchScore" },
                "content": 1,
                "metadata": 1,
                "_id": 0
            }
        }
    ]

    return list(collection.aggregate(pipeline))

# 3. EXECUTION
if __name__ == "__main__":
    user_input = "How do I secure my Azure Cosmos DB?"
    
    print(f"Searching for: {user_input}...")
    results = vector_search(user_input)

    for i, doc in enumerate(results):
        print(f"\nResult {i+1} (Score: {doc['score']:.4f}):")
        print(f"Content: {doc.get('content', 'No content field found')[:200]}...")


#Important Notes for Success
#Field Names: Ensure your documents in MongoDB have a field exactly named contentVector (or update the path in the script).
#Dimensions: text-embedding-3-small creates 1536 dimensions. Your MongoDB cosmosSearch index must be configured for 1536 dimensions or the search will fail with a size mismatch.
#Deployment Name: In the get_embedding function, model=AOAI_DEPLOYMENT refers to the Deployment Name you gave the model in Azure AI Studio, not the base model name.