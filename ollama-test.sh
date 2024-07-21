#/bin/sh
# My Ollama setup script for test

curl -fsSL https://ollama.com/install.sh | sh
docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
ollama pull mistral
ollama pull openhermes

# Now the open web ui is accessible on http://127.0.0.1:8080/ 
