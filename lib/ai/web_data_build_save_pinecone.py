from llama_index import VectorStoreIndex
from llama_index import SimpleDirectoryReader
from llama_index import SimpleWebPageReader
from llama_index import GPTVectorStoreIndex, StorageContext, ServiceContext
from llama_hub.web.sitemap.base import SitemapReader
from llama_index.vector_stores import PineconeVectorStore
from llama_index.embeddings.openai import OpenAIEmbedding
import os
import openai
import pinecone
import pdb

# https://gpt-index.readthedocs.io/en/latest/core_modules/data_modules/index/vector_store_guide.html
# https://gpt-index.readthedocs.io/en/stable/examples/vector_stores/PineconeIndexDemo.html
# https://www.youtube.com/watch?v=WKvAWub8VCU
# https://docs.pinecone.io/docs/insert-data
# https://stackoverflow.com/a/76466198/609365
OPENAI_ACCESS_TOKEN = "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"
os.environ["OPENAI_API_KEY"] = OPENAI_ACCESS_TOKEN
openai.api_key = OPENAI_ACCESS_TOKEN

PINECONE_API_KEY = "2539cb4c-90a3-4a13-96e6-6722605e13f3"
PINECONE_ENV = "asia-southeast1-gcp-free"
os.environ["PINECONE_API_KEY"] = PINECONE_API_KEY
os.environ["PINECONE_ENVIRONMENT"] = PINECONE_ENV


class WebDataPinecone:
    @classmethod
    def build(cls):
        pinecone.init(api_key = PINECONE_API_KEY, environment = PINECONE_ENV)
        index_name = "toruya-dev"
        if index_name not in pinecone.list_indexes():
            pinecone.create_index(
                    index_name,
                    dimension=1536,
                    metric='cosine'
                    )

        # connect to index
        pinecone_index = pinecone.Index(index_name)
        vector_store = PineconeVectorStore(pinecone_index = pinecone_index)

        # https://toruya.com/wp-sitemap-posts-faq-1.xml
        # https://toruya.com/wp-sitemap-posts-post-1.xml
        loader = SitemapReader()
        documents = loader.load_data(sitemap_url='https://toruya.com/wp-sitemap-posts-faq-1.xml')
        for document in documents:
            document.metadata['user_id'] = 1


        embed_model = OpenAIEmbedding(model='text-embedding-ada-002', embed_batch_size=100)
        service_context = ServiceContext.from_defaults(embed_model = embed_model)
        storage_context = StorageContext.from_defaults(vector_store = vector_store)

        index = GPTVectorStoreIndex.from_documents(documents, storage_context = storage_context, service_context = service_context)

        return documents


WebDataPinecone.build()
