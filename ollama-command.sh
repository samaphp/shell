#!/bin/bash
# Code reviewer bash script

ENDPOINT="http://0.0.0.0:11434/v1/chat/completions"
PROMPT=$(<prompt.txt)
ESCAPED_PROMPT=$(echo "$PROMPT" | jq -Rs .)
DIFF=$(<diff2.txt)
ESCAPED_DIFF=$(echo "$DIFF" | jq -Rs .)

DATA="{
    \"model\": \"mistral\",
    \"messages\": [
        {
            \"role\": \"system\",
            \"content\": $ESCAPED_PROMPT
        },
        {
            \"role\": \"user\",
            \"content\": $ESCAPED_DIFF
        }
    ]
}"

echo "$DATA"
response=$(curl -s -X POST "$ENDPOINT" -d "$DATA" -H "Content-Type: application/json")
#echo "$response"
#echo "$response" | jq -r '.choices[0].message.content'
#echo "$response" | jq -r '.choices[0].message.content' | sed 's/<think>.*<\/think>//g'
echo "$response" | jq -r '.choices[0].message.content' | perl -0777 -pe 's/<think>.*?<\/think>//sg'
