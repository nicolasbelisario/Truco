#!/usr/bin/env python3
"""
Roblox Studio Log Watcher - MCP Server (Model Context Protocol)
Zero-dependency standalone MCP server over stdio for Roblox Studio logs.
Allows AI assistants to inspect runtime logs, errors and warnings in real-time.
"""

import sys
import os
import json
import glob
from typing import Dict, Any, List

SERVER_NAME = "roblox-studio-log-watcher"
SERVER_VERSION = "1.0.0"

def get_roblox_logs_dir() -> str:
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if not local_app_data:
        local_app_data = os.path.expanduser("~/AppData/Local")
    return os.path.join(local_app_data, "Roblox", "logs")

def get_latest_log_file() -> str:
    logs_dir = get_roblox_logs_dir()
    if not os.path.exists(logs_dir):
        return ""
    log_files = glob.glob(os.path.join(logs_dir, "*.log"))
    if not log_files:
        return ""
    # Retorna o arquivo mais recente
    return max(log_files, key=os.path.getmtime)

def tool_get_logs(lines: int = 50) -> Dict[str, Any]:
    latest_file = get_latest_log_file()
    if not latest_file:
        return {"text": f"Nenhum arquivo de log encontrado em {get_roblox_logs_dir()}"}

    try:
        with open(latest_file, "r", encoding="utf-8", errors="replace") as f:
            all_lines = f.readlines()
            selected = all_lines[-lines:] if lines > 0 else all_lines
            return {
                "text": f"--- Arquivo: {os.path.basename(latest_file)} (Últimas {len(selected)} linhas) ---\n" + "".join(selected)
            }
    except Exception as e:
        return {"text": f"Erro ao ler log {latest_file}: {str(e)}"}

def tool_get_errors(lines_context: int = 20) -> Dict[str, Any]:
    latest_file = get_latest_log_file()
    if not latest_file:
        return {"text": f"Nenhum arquivo de log encontrado em {get_roblox_logs_dir()}"}

    error_keywords = ["[error]", "script error", "warn", "stack begin", "stack end", "exception", "failed"]
    matched_lines = []

    try:
        with open(latest_file, "r", encoding="utf-8", errors="replace") as f:
            for idx, line in enumerate(f):
                line_lower = line.lower()
                if any(kw in line_lower for kw in error_keywords):
                    matched_lines.append(f"L{idx+1}: {line}")
            
            if not matched_lines:
                return {"text": f"Nenhum erro ou warn encontrado no log ativo ({os.path.basename(latest_file)})."}
            
            output = matched_lines[-lines_context:] if lines_context > 0 else matched_lines
            return {
                "text": f"--- Alertas/Erros no log {os.path.basename(latest_file)} ({len(output)} ocorrências) ---\n" + "".join(output)
            }
    except Exception as e:
        return {"text": f"Erro ao filtrar log: {str(e)}"}

def tool_get_session_info() -> Dict[str, Any]:
    latest_file = get_latest_log_file()
    if not latest_file:
        return {"text": "Nenhum arquivo de log disponível."}
    
    mtime = os.path.getmtime(latest_file)
    size = os.path.getsize(latest_file)
    import datetime
    dt = datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")

    info = {
        "file": os.path.basename(latest_file),
        "path": latest_file,
        "last_modified": dt,
        "size_bytes": size,
    }
    return {"text": json.dumps(info, indent=2)}

TOOLS = [
    {
        "name": "read_roblox_studio_output",
        "description": "Lê as últimas N linhas de log do Roblox Studio em tempo real.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "lines": {
                    "type": "integer",
                    "description": "Quantidade de linhas a serem lidas do final do arquivo.",
                    "default": 50
                }
            }
        }
    },
    {
        "name": "check_roblox_errors_and_warnings",
        "description": "Filtra e retorna apenas mensagens de erro, warnings e stack traces do log ativo.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "max_results": {
                    "type": "integer",
                    "description": "Número máximo de linhas de erro a retornar.",
                    "default": 30
                }
            }
        }
    },
    {
        "name": "get_roblox_log_session_info",
        "description": "Retorna o arquivo de log ativo, data/hora da última alteração e tamanho.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    }
]

def handle_rpc_message(msg: Dict[str, Any]) -> Dict[str, Any]:
    method = msg.get("method")
    msg_id = msg.get("id")

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {}
                },
                "serverInfo": {
                    "name": SERVER_NAME,
                    "version": SERVER_VERSION
                }
            }
        }
    
    elif method == "notifications/initialized":
        return None # Notificação não recebe resposta

    elif method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "tools": TOOLS
            }
        }

    elif method == "tools/call":
        params = msg.get("params", {})
        name = params.get("name")
        args = params.get("arguments", {})

        if name == "read_roblox_studio_output":
            lines = args.get("lines", 50)
            res = tool_get_logs(lines)
            return {
                "jsonrpc": "2.0",
                "id": msg_id,
                "result": {
                    "content": [{"type": "text", "text": res["text"]}]
                }
            }
        elif name == "check_roblox_errors_and_warnings":
            max_r = args.get("max_results", 30)
            res = tool_get_errors(max_r)
            return {
                "jsonrpc": "2.0",
                "id": msg_id,
                "result": {
                    "content": [{"type": "text", "text": res["text"]}]
                }
            }
        elif name == "get_roblox_log_session_info":
            res = tool_get_session_info()
            return {
                "jsonrpc": "2.0",
                "id": msg_id,
                "result": {
                    "content": [{"type": "text", "text": res["text"]}]
                }
            }
        else:
            return {
                "jsonrpc": "2.0",
                "id": msg_id,
                "error": {
                    "code": -32601,
                    "message": f"Ferramenta desconhecida: {name}"
                }
            }

    return {
        "jsonrpc": "2.0",
        "id": msg_id,
        "error": {
            "code": -32601,
            "message": f"Método não suportado: {method}"
        }
    }

def main():
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            line = line.strip()
            if not line:
                continue
            
            req = json.loads(line)
            res = handle_rpc_message(req)
            if res is not None:
                sys.stdout.write(json.dumps(res) + "\n")
                sys.stdout.flush()
        except KeyboardInterrupt:
            break
        except Exception as e:
            err_res = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": f"Parse error: {str(e)}"}
            }
            sys.stdout.write(json.dumps(err_res) + "\n")
            sys.stdout.flush()

if __name__ == "__main__":
    main()
