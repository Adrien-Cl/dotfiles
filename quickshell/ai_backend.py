#!/usr/bin/env python3
import json
import os
import subprocess
from pathlib import Path

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from pydantic import BaseModel

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


def _get_api_key() -> str:
    key = os.environ.get("GROQ_API_KEY", "")
    if key:
        return key
    config_path = Path.home() / ".config/quickshell/ai_config.json"
    if config_path.exists():
        data = json.loads(config_path.read_text())
        return data.get("groq_api_key", "")
    return ""


def _get_model() -> str:
    config_path = Path.home() / ".config/quickshell/ai_config.json"
    if config_path.exists():
        data = json.loads(config_path.read_text())
        return data.get("model", "llama-3.3-70b-versatile")
    return "llama-3.3-70b-versatile"


# Full conversation history (OpenAI format, system message excluded)
conversation_history: list[dict] = []

SYSTEM_PROMPT = """Tu es un assistant IA intégré à la barre de bureau Quickshell de l'utilisateur.
Environnement : Arch Linux, Hyprland, Quickshell.
Config principale : ~/.config/quickshell/

Tu peux lire/écrire des fichiers et exécuter des commandes shell pour aider l'utilisateur.
Réponds en français. Sois concis et pratique."""

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Lit le contenu d'un fichier. Supporte ~ pour le home.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Chemin du fichier (absolu ou ~)"}
                },
                "required": ["path"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "write_file",
            "description": "Écrit du contenu dans un fichier. Crée les répertoires parents si nécessaire.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path":    {"type": "string", "description": "Chemin du fichier"},
                    "content": {"type": "string", "description": "Contenu à écrire"}
                },
                "required": ["path", "content"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_directory",
            "description": "Liste les fichiers et dossiers d'un répertoire.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Chemin du répertoire"}
                },
                "required": ["path"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "execute_command",
            "description": "Exécute une commande shell et retourne stdout + stderr. Timeout 30s.",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {"type": "string", "description": "Commande shell à exécuter"}
                },
                "required": ["command"]
            }
        }
    }
]


def _process_tool(name: str, args: dict) -> str:
    try:
        if name == "read_file":
            p = Path(os.path.expanduser(args["path"]))
            return p.read_text(errors="replace")
        elif name == "write_file":
            p = Path(os.path.expanduser(args["path"]))
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(args["content"])
            return f"Fichier écrit : {p}"
        elif name == "list_directory":
            p = Path(os.path.expanduser(args["path"]))
            entries = sorted(p.iterdir(), key=lambda x: (x.is_file(), x.name))
            return "\n".join(("📁 " if e.is_dir() else "📄 ") + e.name for e in entries)
        elif name == "execute_command":
            result = subprocess.run(
                args["command"], shell=True,
                capture_output=True, text=True, timeout=30
            )
            out = result.stdout + result.stderr
            return out if out else "(pas de sortie)"
    except Exception as e:
        return f"Erreur : {e}"
    return "Outil inconnu"


class ChatRequest(BaseModel):
    message: str


@app.post("/chat")
async def chat(req: ChatRequest):
    api_key = _get_api_key()
    if not api_key:
        return {
            "response": "Erreur : GROQ_API_KEY non définie. Ajoute-la dans ~/.zshenv ou dans ~/.config/quickshell/ai_config.json (champ groq_api_key).",
            "tools_used": []
        }

    client = Groq(api_key=api_key)
    model  = _get_model()

    conversation_history.append({"role": "user", "content": req.message})

    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + conversation_history

    response_text = ""
    tools_used: list[str] = []

    while True:
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=TOOLS,
            tool_choice="auto",
            max_tokens=4096,
        )

        choice = response.choices[0]

        if choice.finish_reason == "tool_calls":
            tool_calls = choice.message.tool_calls

            # Store assistant turn with tool calls
            assistant_msg = {
                "role": "assistant",
                "content": choice.message.content,
                "tool_calls": [
                    {"id": tc.id, "type": "function", "function": {"name": tc.function.name, "arguments": tc.function.arguments}}
                    for tc in tool_calls
                ]
            }
            messages.append(assistant_msg)
            conversation_history.append(assistant_msg)

            # Execute each tool and append results
            for tc in tool_calls:
                label = f"{tc.function.name}({tc.function.arguments[:60]})"
                tools_used.append(label)
                args   = json.loads(tc.function.arguments)
                result = _process_tool(tc.function.name, args)
                tool_msg = {"role": "tool", "tool_call_id": tc.id, "content": result}
                messages.append(tool_msg)
                conversation_history.append(tool_msg)

        else:
            response_text = choice.message.content or ""
            conversation_history.append({"role": "assistant", "content": response_text})
            break

    return {"response": response_text, "tools_used": tools_used}


@app.delete("/history")
async def clear_history():
    conversation_history.clear()
    return {"status": "cleared"}


@app.get("/health")
async def health():
    return {"status": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=7878, log_level="warning")
