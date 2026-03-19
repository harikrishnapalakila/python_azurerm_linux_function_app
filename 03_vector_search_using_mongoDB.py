#Cosmos DB vCore (Vector Search) specific Terraform config, or is this RU-based Mongo setup sufficient for your RAG system?
#To perform a Vector Search on your MongoDB vCore cluster using Python, you use an aggregation pipeline with the $search stage. This is specifically for the vCore architecture you just deployed.

from pymongo import MongoClient

# 1. Setup Connection
# Use the 'vcore_connection_string' from your Terraform output
CONNECTION_STRING = "mongodb+srv://adminuser:ComplexPassword123!@cosmos-vcore-rag-001..."
client = MongoClient(CONNECTION_STRING)
db = client["RAGMongoDatabase"]
collection = db["ChatHistory"]

def vector_search(query_embedding, top_k=5):
    """
    Performs a vector similarity search using the 'cosmosSearch' index.
    """
    pipeline = [
        {
            "$search": {
                "cosmosSearch": {
                    "vector": query_embedding,
                    "path": "contentVector",    # The field containing your embeddings
                    "k": top_k                  # Number of neighbors to return
                },
                "returnStoredSource": True      # Returns the full document
            }
        },
        {
            # Optional: Add a projection to clean up the output
            "$project": {
                "similarity_score": { "$meta": "searchScore" },
                "text_content": 1,
                "metadata": 1,
                "_id": 0
            }
        }
    ]
    
    results = list(collection.aggregate(pipeline))
    return results

# Example Usage:
# results = vector_search(query_embedding=[0.1, -0.2, ...])



################ 
#Critical Configuration Steps
#Index Name: Ensure you have already created the index named vectorIndex (or similar) as shown in the previous step. The $search stage automatically looks for a cosmosSearch type index.
#Dimensions: Your query_embedding length must exactly match the dimensions (e.g., 1536 for text-embedding-3-small) defined during index creation.
#Authentication: If you get a connection error, verify that your Local IP is added to the azurerm_cosmosdb_mongo_cluster_firewall_rule in your Terraform.
#Integration with RAG
#In your Edwardjones_Enterprise_Azure_RAG_System.py workflow:
#Use Azure OpenAI to generate the query_embedding from user input.
#Pass that embedding into the vector_search function above.
#Feed the returned text_content into your LLM prompt as context.


#######################  generating the embeddings using the AzureOpenAI client before passing them to this search #########

#To generate embeddings using the Azure OpenAI Python SDK, you use the client.embeddings.create method. These embeddings can then be passed directly into your MongoDB vCore $search pipeline

