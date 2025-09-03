import os
import requests
import json

def chatgptquery(query):
    # Load API key from environment variable
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("❌ OPENAI_API_KEY not found in environment variables.")

    # Set up the API endpoint and headers
    url = "https://api.openai.com/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    # Compose the request payload
    payload = {
        "model": "gpt-3.5-turbo",  # or "gpt-4" if available
        "messages": [
            {"role": "user", "content": query}
        ],
        "temperature": 0.7
    }

    # Make the API call
    response = requests.post(url, headers=headers, json=payload)

    # Parse and extract the response
    if response.status_code == 200:
        result = response.json()
        message = result['choices'][0]['message']['content']
        print(message)
        
        # Save to file
        with open("SkillImprovementPlan.txt", "w") as out_file:
            out_file.write(message)
        
        return message
    else:
        raise RuntimeError(f"❌ Error {response.status_code}: {response.text}")
