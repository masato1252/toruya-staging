require 'pycall'
require 'pycall/import'
include PyCall::Import

if !Rails.env.test?
  pyimport :sys
  lib_directory = Rails.root.join('lib', 'llama_index')
  sys.path.append(lib_directory.to_s)
  llama_index_pinecone_build = PyCall.import_module("pinecone_build")
  llama_index_pinecone_query = PyCall.import_module("pinecone_query")

  AI_BUILD = llama_index_pinecone_build.LlamaIndexPineconeBuild
  AI_QUERY = llama_index_pinecone_query.LlamaIndexPineconeQuery
end
