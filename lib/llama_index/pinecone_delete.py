import pinecone
import os
from dotenv import load_dotenv
load_dotenv()

PINECONE_API_KEY = os.getenv('PINECONE_API_KEY')
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
PINECONE_ENV = "asia-southeast1-gcp-free"

class LlamaIndexPineconeDelete:
    @classmethod
    def perform(cls, namespace, index_name):

        pinecone.init(api_key=PINECONE_API_KEY, environment=PINECONE_ENV)
        index = pinecone.Index(index_name=index_name)

        delete_response = index.delete(namespace=namespace, delete_all=True)
