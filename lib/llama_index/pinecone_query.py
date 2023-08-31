# https://gpt-index.readthedocs.io/en/v0.6.27/how_to/customization/custom_prompts.html#full-example
# https://github.com/jerryjliu/llama_index/blob/1f6566812863d6cdca8fa272abb6592173e80b30/llama_index/prompts/default_prompts.py#L99-L108
# https://gpt-index.readthedocs.io/en/stable/examples/vector_stores/ZepIndexDemo.html#querying-with-metadata-filters
import pinecone
import os
import sys
import openai
import pdb
from llama_index import PromptTemplate, VectorStoreIndex
from llama_index.vector_stores import PineconeVectorStore
from llama_index.vector_stores.types import ExactMatchFilter, MetadataFilters
from llama_index.query_engine import RetryQueryEngine
from llama_index.evaluation import QueryResponseEvaluator
from dotenv import load_dotenv
import logging

# logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
# logging.getLogger().addHandler(logging.StreamHandler(stream=sys.stdout))

load_dotenv()

os.environ["OPENAI_API_KEY"] = os.getenv('OPENAI_API_KEY')
openai.api_key = os.environ["OPENAI_API_KEY"]
PINECONE_API_KEY = os.getenv('PINECONE_API_KEY')
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
PINECONE_ENV = os.getenv('PINECONE_ENVIRONMENT')
index_name = os.getenv('PINECONE_INDEX_NAME')
pinecone_namespace = os.getenv('PINECONE_NAMESPACE')

TEMPLATE_STR = (
    "Context information is below.\n"
    "---------------------\n"
    "{context_str}\n"
    "---------------------\n"
    "Given the context information and not prior knowledge\n"
    "Answer should be always used the same language with question\n"
    "Answer should use wordings and terms from documents as possible instead of words or terms from questions\n"
    "Answer should always base on context information, don't make up your own answer\n"
    "The Answer need to be text format with proper linkbreak to make it readable\n"
    "And do not provide reference url in answer.\n"
    "If you don't know the answer, always reply in English with 'NO CONTEXT'\n"
    "If you find multiple questions at once, just reply 'AIが正しくお返事できるように、ご質問は１つずつ送信してください。'\n"
    "answer the query.\n"
    "Query: {query_str}\n"
    "Answer: "
)
class LlamaIndexPineconeQuery:
    @classmethod
    def perform(cls, user_id, question, prompt=None):
        pinecone.init(api_key=PINECONE_API_KEY, environment=PINECONE_ENV)
        vector_store = PineconeVectorStore(pinecone.Index(index_name), namespace=pinecone_namespace)
        index = VectorStoreIndex.from_vector_store(vector_store=vector_store)

        filters = MetadataFilters(filters=[ExactMatchFilter(key="user_id", value=user_id)])
        base_query_engine = index.as_query_engine(filters=filters, text_qa_template=PromptTemplate(prompt or TEMPLATE_STR))
        query_response_evaluator = QueryResponseEvaluator()
        query_engine = RetryQueryEngine(base_query_engine, query_response_evaluator)

        return query_engine.query(question)
