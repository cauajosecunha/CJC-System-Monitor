export interface CpuStats {
  usage: number; // Porcentagem geral de uso
  temp: number | null; // Temperatura em °C
  speed: number; // GHz atual
  cores: number[]; // Uso individual por core (%)
  brand: string;
  physicalCores: number;
  logicalCores: number;
}

export interface MemoryStats {
  total: number; // bytes
  used: number; // bytes
  free: number; // bytes
  usagePercent: number;
  swapTotal: number;
  swapUsed: number;
  swapPercent: number;
}

export interface DiskStats {
  fs: string; // ex: "C:" ou "/"
  type: string; // ex: "NTFS", "ext4"
  size: number; // bytes
  used: number; // bytes
  available: number; // bytes
  usePercent: number;
  mount: string;
}

export interface DiskIoStats {
  rIO_sec: number; // Leitura IOPS
  wIO_sec: number; // Escrita IOPS
  rWaitTime: number;
  wWaitTime: number;
}

export interface NetworkStats {
  interface: string;
  ip4: string;
  rxSec: number; // Bytes recebidos / seg (download speed)
  txSec: number; // Bytes enviados / seg (upload speed)
  rxTotal: number; // Total recebido acumulado
  txTotal: number; // Total enviado acumulado
}

export interface GpuStats {
  model: string;
  vendor: string;
  utilizationGpu: number | null; // %
  memoryTotal: number | null; // MB ou bytes
  memoryUsed: number | null;
  memoryFree: number | null;
  temperatureGpu: number | null; // °C
}

export interface ProcessItem {
  pid: number;
  name: string;
  cpu: number;
  mem: number;
  user: string;
}

export interface SystemStatsPayload {
  timestamp: number;
  uptime: number; // segundos
  platform: string; // "win32", "linux", "darwin"
  hostname: string;
  cpu: CpuStats;
  memory: MemoryStats;
  disks: DiskStats[];
  network: NetworkStats;
  gpu: GpuStats[];
  topProcesses: ProcessItem[];
}

export interface SystemSpecsPayload {
  hostname: string;
  platform: string;
  distro: string;
  release: string;
  arch: string;
  cpu: {
    manufacturer: string;
    brand: string;
    speed: number;
    speedMin: number;
    speedMax: number;
    cores: number;
    physicalCores: number;
    processors: number;
    socket: string;
  };
  memory: {
    total: number;
    layout: Array<{
      size: number;
      type: string;
      clockSpeed: number | null;
      bank: string;
    }>;
  };
  disks: Array<{
    device: string;
    type: string;
    name: string;
    size: number;
    interfaceType: string;
  }>;
  gpus: Array<{
    vendor: string;
    model: string;
    vram: number | null;
    driverVersion: string;
  }>;
  osInfo: {
    platform: string;
    distro: string;
    release: string;
    kernel: string;
    arch: string;
    hostname: string;
    build: string;
  };
}
