import { Server as HttpServer } from "http";
import { WebSocketServer, WebSocket } from "ws";
import { parse } from "url";
import { SystemStatsPayload } from "./types.js";

interface CustomWebSocket extends WebSocket {
  isAlive: boolean;
  clientIp?: string;
}

export class MetricsWebSocketServer {
  private wss: WebSocketServer;
  private heartbeatInterval: NodeJS.Timeout | null = null;
  private readonly maxClients = 50;

  constructor(server: HttpServer, private readonly expectedApiKey?: string) {
    this.wss = new WebSocketServer({
      server,
      path: "/ws",
      maxPayload: 1024 * 1024, // 1 MB máx
    });

    this.wss.on("connection", (ws: CustomWebSocket, req) => {
      // 1. Verificação de Limite de Conexões (Prevenção DoS)
      if (this.wss.clients.size > this.maxClients) {
        console.warn(`[WS] Limite de ${this.maxClients} conexões atingido. Conexão rejeitada.`);
        ws.close(1013, "Limite de conexões atingido");
        return;
      }

      // 2. Validação de Autenticação por Token (se API_KEY estiver configurada)
      if (this.expectedApiKey && this.expectedApiKey.trim().length > 0) {
        const { query } = parse(req.url || "", true);
        const token = query.token || req.headers["x-api-key"];

        if (token !== this.expectedApiKey) {
          console.warn(`[WS] Tentativa de conexão rejeitada: Token inválido ou ausente de ${req.socket.remoteAddress}`);
          ws.close(1008, "Token de autenticação inválido ou ausente");
          return;
        }
      }

      ws.isAlive = true;
      ws.clientIp = req.socket.remoteAddress || "desconhecido";

      console.log(`[WS] Cliente conectado: ${ws.clientIp} (Total de clientes: ${this.wss.clients.size})`);

      ws.on("pong", () => {
        ws.isAlive = true;
      });

      ws.on("message", (data) => {
        try {
          const message = data.toString();
          if (message === "ping") {
            ws.send("pong");
          }
        } catch {
          // Ignora mensagens malformadas
        }
      });

      ws.on("close", (code, reason) => {
        console.log(`[WS] Cliente desconectado (${code}): ${reason || "normal"}. Clientes ativos: ${this.wss.clients.size}`);
      });

      ws.on("error", (err) => {
        console.error(`[WS] Erro no socket cliente ${ws.clientIp}:`, err.message);
      });
    });

    // Inicia verificação periódica de heartbeat (cada 30s)
    this.startHeartbeat();
  }

  private startHeartbeat(): void {
    this.heartbeatInterval = setInterval(() => {
      this.wss.clients.forEach((client) => {
        const customWs = client as CustomWebSocket;
        if (!customWs.isAlive) {
          console.log(`[WS] Terminando cliente inativo: ${customWs.clientIp}`);
          return customWs.terminate();
        }
        customWs.isAlive = false;
        customWs.ping();
      });
    }, 30000);
  }

  public broadcast(stats: SystemStatsPayload): void {
    if (this.wss.clients.size === 0) return;

    const data = JSON.stringify(stats);

    this.wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(data, (err) => {
          if (err) {
            console.error("[WS] Falha ao enviar pacote para cliente:", err.message);
          }
        });
      }
    });
  }

  public getClientCount(): number {
    return this.wss.clients.size;
  }

  public close(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }
    this.wss.close();
  }
}

