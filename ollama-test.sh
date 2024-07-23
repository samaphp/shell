#/bin/sh
# My Ollama setup script for test

curl -fsSL https://ollama.com/install.sh | sh
docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
ollama pull mistral
ollama pull openhermes

# Now the open web ui is accessible on http://127.0.0.1:8080/ 




# -------


## curl cli calls

## getting version (check connection)
#curl -D - -s http://0.0.0.0:11434/api/version
#curl http://0.0.0.0:11434/api/version

## send simple chat and get a response
#curl http://0.0.0.0:11434/v1/chat/completions -d '{
#    "model": "mistral",
#    "messages": [
#        {
#            "role": "system",
#            "content": "You are a helpful assistant."
#         },
#         {
#             "role": "user",
#             "content": "Who are you?"
#         }
#     ]
# }'
