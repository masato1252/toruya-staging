from llama_index import VectorStoreIndex
from llama_index import SimpleDirectoryReader
from llama_index import SimpleWebPageReader
from llama_index import GPTVectorStoreIndex, StorageContext, ServiceContext
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
from hashlib import sha256

# logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
# logging.getLogger().addHandler(logging.StreamHandler(stream=sys.stdout))

load_dotenv()

# https://gpt-index.readthedocs.io/en/latest/core_modules/data_modules/index/vector_store_guide.html
# https://gpt-index.readthedocs.io/en/stable/examples/vector_stores/PineconeIndexDemo.html
# https://www.youtube.com/watch?v=WKvAWub8VCU
# https://docs.pinecone.io/docs/insert-data
# https://stackoverflow.com/a/76466198/609365
os.environ["OPENAI_API_KEY"] = os.getenv('OPENAI_API_KEY')
openai.api_key = os.environ["OPENAI_API_KEY"]

PINECONE_API_KEY = os.getenv('PINECONE_API_KEY')
PINECONE_ENV = "asia-southeast1-gcp-free"
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
os.environ["PINECONE_ENVIRONMENT"] = PINECONE_ENV

class WebDataPinecone:
    @classmethod
    def build(cls):
        pinecone.init(api_key = PINECONE_API_KEY, environment = PINECONE_ENV)
        index_name = "toruya-dev"
        user_id = 'toruya-admin'

        if index_name not in pinecone.list_indexes():
            pinecone.create_index(index_name, dimension=1536, metric='cosine')

        # connect to index
        pinecone_index = pinecone.Index(index_name)
        # https://docs.pinecone.io/docs/namespaces
        # https://support.pinecone.io/hc/en-us/articles/7884238411165-Using-namespaces-vs-metadata-filtering
        # https://support.pinecone.io/hc/en-us/articles/7985415079453-How-do-I-keep-my-customer-data-separate-in-Pinecone-
        # https://github.com/jerryjliu/llama_index/blob/32fc54410d6f73ccb47ab5ed6c2244719ee4ccdb/llama_index/vector_stores/pinecone.py#L128
        vector_store = PineconeVectorStore(pinecone_index = pinecone_index, namespace="staging")
        # vector_store = PineconeVectorStore(pinecone_index = pinecone_index)

        # https://toruya.com/wp-sitemap-posts-faq-1.xml
        # https://toruya.com/wp-sitemap-posts-post-1.xml
        loader = SitemapReader()
        documents = loader.load_data(sitemap_url='https://toruya.com/wp-sitemap-posts-faq-1.xml')
        documents += loader.load_data(sitemap_url='https://toruya.com/wp-sitemap-posts-post-1.xml')

        for document in documents:
            # https://betterprogramming.pub/refreshing-private-data-sources-with-llamaindex-document-management-1d1f1529f5eb
            # https://gpt-index.readthedocs.io/en/latest/core_modules/data_modules/index/document_management.html#refresh
            document.id_ = document.metadata['Source']
            document.metadata['user_id'] = user_id

        embed_model = OpenAIEmbedding(model='text-embedding-ada-002', embed_batch_size=100)
        service_context = ServiceContext.from_defaults(embed_model = embed_model)
        storage_context = StorageContext.from_defaults(vector_store = vector_store)

        try:
            index = VectorStoreIndex.from_vector_store(vector_store=vector_store)
            refresh_ref_docs = index.refresh_ref_docs(documents, update_kwargs={"delete_kwargs": {'delete_from_docstore': True}})
        except:
            index = GPTVectorStoreIndex.from_documents(documents, storage_context = storage_context, service_context = service_context)

        return index

WebDataPinecone.build()
