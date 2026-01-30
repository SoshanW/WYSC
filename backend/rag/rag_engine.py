import json
from langchain.vectorstores import FAISS
from langchain.embeddings.openai import OpenAIEmbeddings
from langchain.chains import RetrievalQA
from langchain.chat_models import ChatOpenAI

# Load dataset
with open("database.json") as f:
    dataset = json.load(f)

# Prepare documents
from langchain.schema import Document

documents = [Document(page_content=json.dumps(item)) for item in dataset]

# Create embeddings
embeddings = OpenAIEmbeddings()  # Make sure OPENAI_API_KEY is set
vectorstore = FAISS.from_documents(documents, embeddings)

# Create retrieval chain
retriever = vectorstore.as_retriever(search_kwargs={"k": 2})
llm = ChatOpenAI(temperature=0)
rag_chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    chain_type="stuff",  # simple for hackathon
    return_source_documents=False
)
