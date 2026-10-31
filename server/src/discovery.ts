import dgram from "dgram";
import os from "os";

export interface DiscoveryBeaconPayload {
  service: "cjc-system-monitor";
  name: string;
  hostname: string;
  ipv4: string;
  port: number;
  timestamp: number;
}

export class DiscoveryService {
  private socket: dgram.Socket | null = null;
  private timer: NodeJS.Timeout | null = null;
  private readonly port: number;
  private readonly httpPort: number;

  constructor(httpPort: number = 4080, udpPort: number = 4080) {
    this.httpPort = httpPort;
    this.port = udpPort;
  }

  /**
   * Obtém o melhor endereço IPv4 local da máquina (não interno)
   */
  public getPrimaryIpv4(): string {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
      const ifaceList = interfaces[name];
      if (!ifaceList) continue;
      for (const iface of ifaceList) {
        // Filtra para IPv4, não-loopback e preferencialmente rede privada 192.168.x.x, 10.x.x, 172.x.x
        if (iface.family === "IPv4" && !iface.internal) {
          if (iface.address.startsWith("192.168.") || iface.address.startsWith("10.")) {
            return iface.address;
          }
        }
      }
    }
    // Fallback para qualquer IPv4 não-interno
    for (const name of Object.keys(interfaces)) {
      const ifaceList = interfaces[name];
      if (!ifaceList) continue;
      for (const iface of ifaceList) {
        if (iface.family === "IPv4" && !iface.internal) {
          return iface.address;
        }
      }
    }
    return "127.0.0.1";
  }

  public start(): void {
    try {
      this.socket = dgram.createSocket({ type: "udp4", reuseAddr: true });

      this.socket.on("error", (err) => {
        console.warn("[DISCOVERY] Aviso no socket UDP:", err.message);
      });

      this.socket.on("message", (msg, rinfo) => {
        const text = msg.toString().trim();
        if (text === "DISCOVER_CJC_MONITOR") {
          console.log(`[DISCOVERY] Consulta de descoberta IPv4 recebida de ${rinfo.address}:${rinfo.port}`);
          this.sendAnnouncementTo(rinfo.address, rinfo.port);
        }
      });

      this.socket.bind(this.port, "0.0.0.0", () => {
        if (!this.socket) return;
        try {
          this.socket.setBroadcast(true);
          console.log(`[DISCOVERY] Beacon de descoberta IPv4 ativo na porta UDP ${this.port}`);
        } catch (e: any) {
          console.warn("[DISCOVERY] Não foi possível ativar broadcast UDP:", e.message);
        }
      });

      // Emite anúncio via broadcast a cada 3 segundos
      this.timer = setInterval(() => {
        this.broadcastBeacon();
      }, 3000);
    } catch (err: any) {
      console.warn("[DISCOVERY] Falha ao inicializar discovery UDP:", err.message);
    }
  }

  private broadcastBeacon(): void {
    if (!this.socket) return;

    const payload: DiscoveryBeaconPayload = {
      service: "cjc-system-monitor",
      name: "CJC System Monitor",
      hostname: os.hostname(),
      ipv4: this.getPrimaryIpv4(),
      port: this.httpPort,
      timestamp: Date.now(),
    };

    const message = Buffer.from(JSON.stringify(payload));
    this.socket.send(message, 0, message.length, this.port, "255.255.255.255", (err) => {
      if (err && (err as any).code !== "ENETUNREACH") {
        // Ignora silenciosamente erros passageiros de rede
      }
    });
  }

  private sendAnnouncementTo(targetIp: string, targetPort: number): void {
    if (!this.socket) return;

    const payload: DiscoveryBeaconPayload = {
      service: "cjc-system-monitor",
      name: "CJC System Monitor",
      hostname: os.hostname(),
      ipv4: this.getPrimaryIpv4(),
      port: this.httpPort,
      timestamp: Date.now(),
    };

    const message = Buffer.from(JSON.stringify(payload));
    this.socket.send(message, 0, message.length, targetPort, targetIp);
  }

  public stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    if (this.socket) {
      try {
        this.socket.close();
      } catch {}
      this.socket = null;
    }
  }
}

