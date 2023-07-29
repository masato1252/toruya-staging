require 'pycall'
require 'pycall/import'
include PyCall::Import

pyimport :sys
lib_directory = Rails.root.join('lib', 'ai')
sys.path.append(lib_directory.to_s)
web_data_read_pinecone = PyCall.import_module("web_data_read_pinecone")
web_data_build_pinecone = PyCall.import_module("web_data_build_save_pinecone")

AI_QUERY = web_data_read_pinecone.WebDataReadPinecone
AI_BUILD = web_data_build_pinecone.WebDataPinecone

require "ai/query"
# AI_BUILD.build
