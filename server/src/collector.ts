import { exec } from "node:child_process";
import os from "node:os";
import si from "systeminformation";
import {
  SystemStatsPayload,
  SystemSpecsPayload,
  CpuStats,
  MemoryStats,
  DiskStats,
  NetworkStats,
  GpuStats,
  ProcessItem,
} from "./types.js";

// Cache para especificações estáticas do hardware (para não recalcular em cada tick)
let cachedSpecs: SystemSpecsPayload | null = null;
let cachedCpuInfo: si.Systeminformation.CpuData | null = null;
let cachedDisks: DiskStats[] = [];
let lastDiskPoll = 0;
let cachedGfx: GpuStats[] = [];
let lastGfxPoll = 0;
let cachedWindowsVramUsedMb: number | null = null;
let isPollingWindowsVram = false;

function pollWindowsVram(): void {
  if (process.platform !== "win32" || isPollingWindowsVram) return;
  isPollingWindowsVram = true;
  exec('typeperf "\\GPU Local Adapter Memory(*)\\Local Usage" -sc 1', { timeout: 3500 }, (err, stdout) => {
    isPollingWindowsVram = false;
    if (err || !stdout) return;
    try {
      const lines = stdout.trim().split(/\r?\n/).map((l) => l.trim()).filter((l) => l.length > 0);
      if (lines.length >= 2) {
        const values = lines[1]
          .split(",")
          .slice(1)
          .map((v) => parseFloat(v.replace(/"/g, "")))
          .filter((v) => !isNaN(v));
        if (values.length > 0) {
          const maxUsedBytes = Math.max(...values);
          cachedWindowsVramUsedMb = Math.round(maxUsedBytes / (1024 * 1024));
        }
      }
    } catch (_) {}
  });
}

// Inicia polling assíncrono em segundo plano para o Windows (não bloqueia o loop principal)
if (process.platform === "win32") {
  pollWindowsVram();
  setInterval(pollWindowsVram, 4000);
}

export async function getSystemSpecs(): Promise<SystemSpecsPayload> {
  if (cachedSpecs) {
    return cachedSpecs;
  }

  const [os, cpu, memLayout, diskLayout, graphics] = await Promise.all([
    si.osInfo(),
    si.cpu(),
    si.memLayout().catch(() => []),
    si.diskLayout().catch(() => []),
    si.graphics().catch(() => ({ controllers: [], displays: [] })),
  ]);

  cachedCpuInfo = cpu;

  const specs: SystemSpecsPayload = {
    hostname: os.hostname,
    platform: os.platform,
    distro: os.distro,
    release: os.release,
    arch: os.arch,
    cpu: {
      manufacturer: cpu.manufacturer,
      brand: cpu.brand,
      speed: cpu.speed,
      speedMin: cpu.speedMin,
      speedMax: cpu.speedMax,
      cores: cpu.cores,
      physicalCores: cpu.physicalCores,
      processors: cpu.processors,
      socket: cpu.socket,
    },
    memory: {
      total: (await si.mem()).total,
      layout: memLayout.map((m) => ({
        size: m.size,
        type: m.type,
        clockSpeed: m.clockSpeed ?? null,
        bank: m.bank,
      })),
    },
    disks: diskLayout.map((d) => ({
      device: d.device,
      type: d.type,
      name: d.name,
      size: d.size,
      interfaceType: d.interfaceType,
    })),
    gpus: graphics.controllers.map((g) => ({
      vendor: g.vendor,
      model: g.model,
      vram: g.vram ?? null,
      driverVersion: g.driverVersion || "N/A",
    })),
    osInfo: {
      platform: os.platform,
      distro: os.distro,
      release: os.release,
      kernel: os.kernel,
      arch: os.arch,
      hostname: os.hostname,
      build: os.build,
    },
  };

  cachedSpecs = specs;
  return specs;
}

export async function collectSystemStats(): Promise<SystemStatsPayload> {
  const now = Date.now();

  // Atualiza discos a cada 4 segundos (reduz overhead de I/O WMI)
  const shouldPollDisks = now - lastDiskPoll > 4000 || cachedDisks.length === 0;
  // Atualiza GPUs a cada 3 segundos
  const shouldPollGpu = now - lastGfxPoll > 3000 || cachedGfx.length === 0;

  // Leituras essenciais ultra-rápidas a cada tick (CPU, Velocidade, Temp, RAM)
  const [load, cpuSpeed, cpuTemp, mem, fsResult, gfxResult, timeData] =
    await Promise.all([
      si.currentLoad().catch(() => ({ currentLoad: 0, cpus: [] })),
      si.cpuCurrentSpeed().catch(() => ({ avg: 0 })),
      si.cpuTemperature().catch(() => ({ main: null })),
      si.mem().catch(() => ({
        total: 1,
        used: 0,
        free: 0,
        swaptotal: 0,
        swapused: 0,
      })),
      shouldPollDisks ? si.fsSize().catch(() => []) : Promise.resolve(null),
      shouldPollGpu ? si.graphics().catch(() => ({ controllers: [] })) : Promise.resolve(null),
      si.time(),
    ]);

  if (fsResult !== null) {
    cachedDisks = fsResult.map((f) => ({
      fs: f.fs,
      type: f.type,
      size: f.size,
      used: f.used,
      available: f.available,
      usePercent: Number(f.use.toFixed(1)),
      mount: f.mount,
    }));
    lastDiskPoll = now;
  }

  if (gfxResult !== null) {
    cachedGfx = gfxResult.controllers.map((g) => {
      const memTotal = g.memoryTotal || g.vram || null;
      let memUsed = g.memoryUsed || null;
      if (process.platform === "win32" && cachedWindowsVramUsedMb !== null) {
        memUsed = cachedWindowsVramUsedMb;
      }
      return {
        model: g.model || "GPU Genérica",
        vendor: g.vendor || "Desconhecido",
        utilizationGpu:
          g.utilizationGpu !== undefined && g.utilizationGpu !== null
            ? Number(g.utilizationGpu.toFixed(1))
            : null,
        memoryTotal: memTotal,
        memoryUsed: memUsed,
        memoryFree: g.memoryFree || (memTotal && memUsed ? Math.max(0, memTotal - memUsed) : null),
        temperatureGpu: g.temperatureGpu || null,
      };
    });
    lastGfxPoll = now;
  }

  const cpuBrand = cachedCpuInfo?.brand || (await si.cpu()).brand;

  const cpuStats: CpuStats = {
    usage: Number(load.currentLoad.toFixed(1)),
    temp: cpuTemp.main !== null && !isNaN(cpuTemp.main) ? Number(cpuTemp.main.toFixed(1)) : null,
    speed: Number(cpuSpeed.avg.toFixed(2)),
    cores: load.cpus.map((c) => Number(c.load.toFixed(1))),
    brand: cpuBrand,
    physicalCores: cachedCpuInfo?.physicalCores || load.cpus.length,
    logicalCores: load.cpus.length,
  };

  const memUsagePercent =
    mem.total > 0 ? Number(((mem.used / mem.total) * 100).toFixed(1)) : 0;
  const swapUsagePercent =
    mem.swaptotal > 0
      ? Number(((mem.swapused / mem.swaptotal) * 100).toFixed(1))
      : 0;

  const memoryStats: MemoryStats = {
    total: mem.total,
    used: mem.used,
    free: mem.free,
    usagePercent: memUsagePercent,
    swapTotal: mem.swaptotal,
    swapUsed: mem.swapused,
    swapPercent: swapUsagePercent,
  };

  const network: NetworkStats = {
    interface: "lan",
    ip4: "127.0.0.1",
    rxSec: 0,
    txSec: 0,
    rxTotal: 0,
    txTotal: 0,
  };

  return {
    timestamp: now,
    uptime: Math.round(timeData.uptime),
    platform: process.platform,
    hostname: cachedSpecs?.hostname || os.hostname(),
    cpu: cpuStats,
    memory: memoryStats,
    disks: cachedDisks,
    network,
    gpu: cachedGfx,
    topProcesses: [],
  };
}
