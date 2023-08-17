import pinecone
import os
import sys
import openai
import pdb
from llama_index import Prompt, VectorStoreIndex
from llama_index.vector_stores import PineconeVectorStore
from llama_index.vector_stores.types import ExactMatchFilter, MetadataFilters
from dotenv import load_dotenv
import logging

logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
logging.getLogger().addHandler(logging.StreamHandler(stream=sys.stdout))

load_dotenv()

os.environ["OPENAI_API_KEY"] = os.getenv('OPENAI_API_KEY')
openai.api_key = os.environ["OPENAI_API_KEY"]
PINECONE_API_KEY = os.getenv('PINECONE_API_KEY')
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
PINECONE_ENV = "asia-southeast1-gcp-free"

# https://gpt-index.readthedocs.io/en/v0.6.27/how_to/customization/custom_prompts.html#full-example
# https://github.com/jerryjliu/llama_index/blob/1f6566812863d6cdca8fa272abb6592173e80b30/llama_index/prompts/default_prompts.py#L99-L108
TEMPLATE_STR = (
    "Context information is below.\n"
    "---------------------\n"
    "{context_str}\n"
    "---------------------\n"
    "Given the context information and not prior knowledge\n"
    "Answer should be always used the same language with question\n"
    "But if you don't know the answer, always reply in English with 'NO CONTEXT'"
    "answer the query.\n"
    "Query: {query_str}\n"
    "Answer: "
)
QA_TEMPLATE = Prompt(TEMPLATE_STR)
class WebDataReadPinecone:
    @classmethod
    def query(cls, question):
        index_name = "toruya-dev"
        user_id = 'toruya-admin'

        pinecone.init(api_key=PINECONE_API_KEY, environment=PINECONE_ENV)
        vector_store = PineconeVectorStore(pinecone.Index(index_name), namespace="staging")
        index = VectorStoreIndex.from_vector_store(vector_store=vector_store)

        # https://gpt-index.readthedocs.io/en/stable/examples/vector_stores/ZepIndexDemo.html#querying-with-metadata-filters
        filters = MetadataFilters(filters=[ExactMatchFilter(key="user_id", value=user_id)])

        return query_engine.query(question)

print(WebDataReadPinecone.query("認証コードSMSが受け取れませ"))
# print(WebDataReadPinecone.query("ふくらむ集客経費"))
