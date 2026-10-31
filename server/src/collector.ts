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
  // Executa leituras em paralelo para obter máximo desempenho e consistência temporal
  const [load, cpuSpeed, cpuTemp, mem, fs, netStats, netIfaces, gfx, procs, timeData] =
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
      si.fsSize().catch(() => []),
      si.networkStats().catch(() => []),
      si.networkInterfaces().catch(() => []),
      si.graphics().catch(() => ({ controllers: [] })),
      si.processes().catch(() => ({ list: [] })),
      si.time(),
    ]);

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

  const disks: DiskStats[] = fs.map((f) => ({
    fs: f.fs,
    type: f.type,
    size: f.size,
    used: f.used,
    available: f.available,
    usePercent: Number(f.use.toFixed(1)),
    mount: f.mount,
  }));

  // Interface primária de rede conectada
  const activeNetStat =
    netStats.find((s) => s.rx_sec !== null && s.rx_sec > 0) ||
    netStats[0] || {
      iface: "default",
      rx_sec: 0,
      tx_sec: 0,
      rx_bytes: 0,
      tx_bytes: 0,
    };

  // Local IPv4
  const ifaceList = Array.isArray(netIfaces) ? netIfaces : [netIfaces];
  const activeIface = ifaceList.find(
    (i) => i.iface === activeNetStat.iface || (i.ip4 && i.ip4 !== "127.0.0.1")
  );

  const network: NetworkStats = {
    interface: activeNetStat.iface || "Ativa",
    ip4: activeIface?.ip4 || "127.0.0.1",
    rxSec: Math.max(0, Math.round(activeNetStat.rx_sec || 0)),
    txSec: Math.max(0, Math.round(activeNetStat.tx_sec || 0)),
    rxTotal: activeNetStat.rx_bytes || 0,
    txTotal: activeNetStat.tx_bytes || 0,
  };

  const gpus: GpuStats[] = gfx.controllers.map((g) => ({
    model: g.model || "GPU Genérica",
    vendor: g.vendor || "Desconhecido",
    utilizationGpu:
      g.utilizationGpu !== undefined && g.utilizationGpu !== null
        ? Number(g.utilizationGpu.toFixed(1))
        : null,
    memoryTotal: g.memoryTotal || g.vram || null,
    memoryUsed: g.memoryUsed || null,
    memoryFree: g.memoryFree || null,
    temperatureGpu: g.temperatureGpu || null,
  }));

  // Top 15 processos reais por CPU + RAM ordenados (ignora System Idle Process)
  const topProcesses: ProcessItem[] = procs.list
    .filter((p) => p.name && p.name !== "System Idle Process" && p.cpu >= 0)
    .sort((a, b) => b.cpu + b.mem - (a.cpu + a.mem))
    .slice(0, 15)
    .map((p) => ({
      pid: p.pid,
      name: p.name,
      cpu: Number(p.cpu.toFixed(1)),
      mem: Number(p.mem.toFixed(1)),
      user: p.user || "system",
    }));

  return {
    timestamp: Date.now(),
    uptime: Math.round(timeData.uptime),
    platform: process.platform,
    hostname: (await si.osInfo()).hostname,
    cpu: cpuStats,
    memory: memoryStats,
    disks,
    network,
    gpu: gpus,
    topProcesses,
  };
}
