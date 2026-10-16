# 📡 Roblox Studio Log Watcher (MCP Server)

Servidor local compatível com o protocolo [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) que permite ao assistente de IA inspecionar os logs do Roblox Studio em tempo real.

## Ferramentas Disponíveis

| Ferramenta | Descrição | Parâmetros |
|---|---|---|
| `read_roblox_studio_output` | Lê as últimas $N$ linhas de output do jogo | `lines` (padrão: 50) |
| `check_roblox_errors_and_warnings` | Filtra prints de erro, exceções e warnings | `max_results` (padrão: 30) |
| `get_roblox_log_session_info` | Retorna o caminho, data e tamanho do log ativo | nenhum |

## Diretório de Logs Monitorado
`%LOCALAPPDATA%\Roblox\logs\*.log`

## Como Testar Manualmente
```bash
python tools/mcp_roblox_logs/server.py
```
Ou rodando uma requisição de teste:
```bash
python -c "import subprocess, json; p = subprocess.Popen(['python', 'tools/mcp_roblox_logs/server.py'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True); p.stdin.write(json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list', 'params': {}}) + '\n'); p.stdin.flush(); print(p.stdout.readline()); p.terminate()"
```
