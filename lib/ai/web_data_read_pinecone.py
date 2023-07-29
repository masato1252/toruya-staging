import pinecone
import os
import openai
import pdb
from llama_index import VectorStoreIndex
from llama_index.vector_stores import PineconeVectorStore

os.environ["OPENAI_API_KEY"] = "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"
openai.api_key = os.environ["OPENAI_API_KEY"]
PINECONE_API_KEY = "2539cb4c-90a3-4a13-96e6-6722605e13f3"
os.environ["PINECONE_API_KEY"] = "2539cb4c-90a3-4a13-96e6-6722605e13f3"
PINECONE_ENV = "asia-southeast1-gcp-free"

class WebDataReadPinecone:
    @classmethod
    def query(cls, question):

        pinecone.init(api_key=PINECONE_API_KEY, environment=PINECONE_ENV)
        vector_store = PineconeVectorStore(pinecone.Index("toruya-dev"))
        index = VectorStoreIndex.from_vector_store(vector_store=vector_store)

        # query_engine = index.as_query_engine()
        filters = MetadataFilters(filters=[ExactMatchFilter(key="user_id", value=1)])
        query_engine = index.as_query_engine(filters=filters)

        return query_engine.query(question)
