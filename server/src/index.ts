import http from "http";
import os from "os";
import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import dotenv from "dotenv";
import { MetricsWebSocketServer } from "./websocket.js";
import { collectSystemStats, getSystemSpecs } from "./collector.js";
import { DiscoveryService } from "./discovery.js";

dotenv.config({ override: true });

// Previne colisão caso a porta 4050 seja herdada do ambiente do ProjectUpdater
let resolvedPort = process.env.PORT;
if (!resolvedPort || resolvedPort === "4050") {
  resolvedPort = "4080";
}
const PORT = parseInt(resolvedPort, 10);
const HOST = process.env.HOST || "0.0.0.0";
const UPDATE_INTERVAL_MS = Math.max(500, parseInt(process.env.UPDATE_INTERVAL_MS || "1000", 10));
const API_KEY = process.env.API_KEY || "";
const CORS_ORIGIN = process.env.CORS_ORIGIN || "*";
const UDP_DISCOVERY_PORT = parseInt(process.env.UDP_DISCOVERY_PORT || "4080", 10);

const app = express();
app.set("trust proxy", 1);
app.disable("x-powered-by"); // Oculta assinatura do Express contra fingerprinting

app.use(cors({ origin: CORS_ORIGIN, methods: ["GET", "OPTIONS"] }));
app.use(express.json());

// Serviço de descoberta via UDP broadcast na rede IPv4 local
const discoveryService = new DiscoveryService(PORT, UDP_DISCOVERY_PORT);

// Middleware de autenticação opcional por token (se API_KEY estiver definida)
const authMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  if (!API_KEY || API_KEY.trim() === "") {
    return next();
  }

  const token = req.headers["x-api-key"] || req.query.token;
  if (token !== API_KEY) {
    res.status(401).json({
      error: "Não autorizado",
      message: "Chave de autenticação ausente ou inválida via cabeçalho 'X-API-Key' ou query param '?token='",
    });
    return;
  }

  next();
};

// --- ROTAS HTTP REST ---

/**
 * Healthcheck básico e status do serviço (com identificação IPv4 explícita)
 */
app.get("/api/status", (_req: Request, res: Response) => {
  res.json({
    status: "online",
    name: "CJC System Monitor Daemon",
    version: "1.0.0",
    hostname: os.hostname(),
    ipv4: discoveryService.getPrimaryIpv4(),
    port: PORT,
    timestamp: Date.now(),
    uptime: Math.round(process.uptime()),
    clientsConnected: wsServer ? wsServer.getClientCount() : 0,
    authRequired: Boolean(API_KEY && API_KEY.trim().length > 0),
  });
});

/**
 * Especificações estáticas detalhadas do hardware e do OS
 */
app.get("/api/specs", authMiddleware, async (_req: Request, res: Response) => {
  try {
    const specs = await getSystemSpecs();
    res.json(specs);
  } catch (error) {
    console.error("[HTTP] Erro ao obter especificações do sistema:", error);
    res.status(500).json({ error: "Falha ao obter especificações do hardware" });
  }
});

/**
 * Snapshot sob demanda das métricas em tempo real
 */
app.get("/api/stats", authMiddleware, async (_req: Request, res: Response) => {
  try {
    const stats = await collectSystemStats();
    res.json(stats);
  } catch (error) {
    console.error("[HTTP] Erro ao coletar estatísticas do sistema:", error);
    res.status(500).json({ error: "Falha ao coletar métricas do sistema" });
  }
});

// Criação do servidor HTTP e integração com WebSocket
const server = http.createServer(app);
const wsServer = new MetricsWebSocketServer(server, API_KEY);

// Loop de telemetria contínua com economia inteligente de recursos
let isCollecting = false;
const broadcastTick = async () => {
  if (wsServer.getClientCount() === 0) {
    return;
  }

  if (isCollecting) return;
  isCollecting = true;

  try {
    const stats = await collectSystemStats();
    wsServer.broadcast(stats);
  } catch (error) {
    console.error("[BROADCAST] Erro no ciclo de telemetria:", error);
  } finally {
    isCollecting = false;
  }
};

const intervalHandle = setInterval(broadcastTick, UPDATE_INTERVAL_MS);

// Inicialização do Servidor e do Beacon UDP IPv4
server.listen(PORT, HOST, () => {
  const hostIpv4 = discoveryService.getPrimaryIpv4();
  discoveryService.start();

  console.log("==================================================");
  console.log(`🚀 CJC System Monitor Server Rodando com Sucesso!`);
  console.log(`🌐 IPv4 Local: http://${hostIpv4}:${PORT}`);
  console.log(`⚡ WebSocket IPv4: ws://${hostIpv4}:${PORT}/ws`);
  console.log(`📡 Beacon UDP Discovery: Porta ${UDP_DISCOVERY_PORT} (IPv4 LAN)`);
  console.log(`⏱️  Intervalo de Streaming: ${UPDATE_INTERVAL_MS}ms`);
  console.log(`🔒 Autenticação: ${API_KEY ? "Ativa (API_KEY configurada)" : "Livre na LAN"}`);
  console.log("==================================================");
});

// Encerramento Gracioso (Graceful Shutdown)
const gracefulShutdown = () => {
  console.log("\n[SERVER] Encerrando serviços graciosamente...");
  clearInterval(intervalHandle);
  discoveryService.stop();
  wsServer.close();
  server.close(() => {
    console.log("[SERVER] Servidor finalizado com sucesso.");
    process.exit(0);
  });
};

process.on("SIGINT", gracefulShutdown);
process.on("SIGTERM", gracefulShutdown);
