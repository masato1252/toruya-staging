# https://docs.pinecone.io/docs/namespaces
# https://support.pinecone.io/hc/en-us/articles/7884238411165-Using-namespaces-vs-metadata-filtering
# https://support.pinecone.io/hc/en-us/articles/7985415079453-How-do-I-keep-my-customer-data-separate-in-Pinecone-
# https://github.com/jerryjliu/llama_index/blob/32fc54410d6f73ccb47ab5ed6c2244719ee4ccdb/llama_index/vector_stores/pinecone.py#L128
# https://gpt-index.readthedocs.io/en/latest/core_modules/data_modules/index/vector_store_guide.html
# https://gpt-index.readthedocs.io/en/stable/examples/vector_stores/PineconeIndexDemo.html
# https://www.youtube.com/watch?v=WKvAWub8VCU
# https://docs.pinecone.io/docs/insert-data
# https://stackoverflow.com/a/76466198/609365
# https://betterprogramming.pub/refreshing-private-data-sources-with-llamaindex-document-management-1d1f1529f5eb
# https://gpt-index.readthedocs.io/en/latest/core_modules/data_modules/index/document_management.html#refresh
from llama_index import VectorStoreIndex, GPTVectorStoreIndex, StorageContext, ServiceContext, download_loader
from llama_hub.web.sitemap.base import SitemapReader
from llama_index.vector_stores import PineconeVectorStore
from llama_index.embeddings.openai import OpenAIEmbedding
import sys
import os
import openai
import pinecone
import pdb
from dotenv import load_dotenv
import logging
import re
from hashlib import sha256

# logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
# logging.getLogger().addHandler(logging.StreamHandler(stream=sys.stdout))

load_dotenv()

os.environ["OPENAI_API_KEY"] = os.getenv('OPENAI_API_KEY')
openai.api_key = os.environ["OPENAI_API_KEY"]

PINECONE_API_KEY = os.getenv('PINECONE_API_KEY')
PINECONE_ENV = os.getenv('PINECONE_ENVIRONMENT')
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
os.environ["PINECONE_ENVIRONMENT"] = PINECONE_ENV

index_name = os.getenv('PINECONE_INDEX_NAME')
pinecone_namespace = os.getenv('PINECONE_NAMESPACE')

class LlamaIndexPineconeBuild:
    @classmethod
    def perform(cls, user_id, url):
        pinecone.init(api_key = PINECONE_API_KEY, environment = PINECONE_ENV)

        if index_name not in pinecone.list_indexes():
            pinecone.create_index(index_name, dimension=1536, metric='cosine')

        pinecone_index = pinecone.Index(index_name)
        vector_store = PineconeVectorStore(pinecone_index=pinecone_index, namespace=pinecone_namespace)

        BeautifulSoupWebReader = download_loader("BeautifulSoupWebReader")
        web_loader = BeautifulSoupWebReader()
        documents = web_loader.load_data(urls=[url])

        for document in documents:
            document.id_ = document.metadata['URL']
            document.metadata['user_id'] = user_id

        # https://www.theinternet.io/articles/ask-ai/why-does-openai-use-1536-dimensions-for-embeddings-specifically-the-text-embedding-ada-002-model/
        embed_model = OpenAIEmbedding(model='text-embedding-ada-002')
        service_context = ServiceContext.from_defaults(embed_model=embed_model, chunk_size=512)
        storage_context = StorageContext.from_defaults(vector_store = vector_store)

        try:
            index = VectorStoreIndex.from_vector_store(vector_store=vector_store)
            refresh_ref_docs = index.refresh_ref_docs(documents, update_kwargs={"delete_kwargs": {'delete_from_docstore': True}})
        except:
            index = GPTVectorStoreIndex.from_documents(documents, storage_context = storage_context, service_context = service_context)

        return index
