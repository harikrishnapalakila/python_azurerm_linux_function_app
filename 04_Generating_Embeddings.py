import os
from openai import AzureOpenAI

# 1. Initialize the Azure OpenAI Client
client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),  
    api_version="2024-12-01-preview",
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
)

def get_embedding(text, model="text-embedding-3-small"):
    """
    Converts a text string into a vector embedding.
    """
    # Clean the text (remove newlines as per best practices)
    text = text.replace("\n", " ")
    
    response = client.embeddings.create(
        input=[text], 
        model=model # This must match your Deployment Name in Azure AI Studio
    )
    
    return response.data[0].embedding

# 2. Integrate with your Search
user_query = "How do I set up a RAG system?"
query_vector = get_embedding(user_query)

# Now pass 'query_vector' into the MongoDB search function from before
# results = vector_search(query_vector)
