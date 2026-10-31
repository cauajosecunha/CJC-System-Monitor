import 'process_model.dart';

class CpuStatsModel {
  final double usage;
  final double? temp;
  final double speed;
  final List<double> cores;
  final String brand;
  final int physicalCores;
  final int logicalCores;

  const CpuStatsModel({
    required this.usage,
    this.temp,
    required this.speed,
    required this.cores,
    required this.brand,
    required this.physicalCores,
    required this.logicalCores,
  });

  factory CpuStatsModel.fromJson(Map<String, dynamic> json) {
    return CpuStatsModel(
      usage: (json['usage'] as num?)?.toDouble() ?? 0.0,
      temp: (json['temp'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      cores: ((json['cores'] as List<dynamic>?) ?? [])
          .map((c) => (c as num).toDouble())
          .toList(),
      brand: (json['brand'] as String?) ?? 'CPU',
      physicalCores: (json['physicalCores'] as num?)?.toInt() ?? 1,
      logicalCores: (json['logicalCores'] as num?)?.toInt() ?? 1,
    );
  }
}

class MemoryStatsModel {
  final int total;
  final int used;
  final int free;
  final double usagePercent;
  final int swapTotal;
  final int swapUsed;
  final double swapPercent;

  const MemoryStatsModel({
    required this.total,
    required this.used,
    required this.free,
    required this.usagePercent,
    required this.swapTotal,
    required this.swapUsed,
    required this.swapPercent,
  });

  factory MemoryStatsModel.fromJson(Map<String, dynamic> json) {
    return MemoryStatsModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      used: (json['used'] as num?)?.toInt() ?? 0,
      free: (json['free'] as num?)?.toInt() ?? 0,
      usagePercent: (json['usagePercent'] as num?)?.toDouble() ?? 0.0,
      swapTotal: (json['swapTotal'] as num?)?.toInt() ?? 0,
      swapUsed: (json['swapUsed'] as num?)?.toInt() ?? 0,
      swapPercent: (json['swapPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DiskStatsModel {
  final String fs;
  final String type;
  final int size;
  final int used;
  final int available;
  final double usePercent;
  final String mount;

  const DiskStatsModel({
    required this.fs,
    required this.type,
    required this.size,
    required this.used,
    required this.available,
    required this.usePercent,
    required this.mount,
  });

  factory DiskStatsModel.fromJson(Map<String, dynamic> json) {
    return DiskStatsModel(
      fs: (json['fs'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      used: (json['used'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
      usePercent: (json['usePercent'] as num?)?.toDouble() ?? 0.0,
      mount: (json['mount'] as String?) ?? '',
    );
  }
}

class NetworkStatsModel {
  final String interfaceName;
  final String ip4;
  final int rxSec;
  final int txSec;
  final int rxTotal;
  final int txTotal;

  const NetworkStatsModel({
    required this.interfaceName,
    required this.ip4,
    required this.rxSec,
    required this.txSec,
    required this.rxTotal,
    required this.txTotal,
  });

  factory NetworkStatsModel.fromJson(Map<String, dynamic> json) {
    return NetworkStatsModel(
      interfaceName: (json['interface'] as String?) ?? 'LAN',
      ip4: (json['ip4'] as String?) ?? '127.0.0.1',
      rxSec: (json['rxSec'] as num?)?.toInt() ?? 0,
      txSec: (json['txSec'] as num?)?.toInt() ?? 0,
      rxTotal: (json['rxTotal'] as num?)?.toInt() ?? 0,
      txTotal: (json['txTotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class GpuStatsModel {
  final String model;
  final String vendor;
  final double? utilizationGpu;
  final int? memoryTotal;
  final int? memoryUsed;
  final int? memoryFree;
  final double? temperatureGpu;

  const GpuStatsModel({
    required this.model,
    required this.vendor,
    this.utilizationGpu,
    this.memoryTotal,
    this.memoryUsed,
    this.memoryFree,
    this.temperatureGpu,
  });

  factory GpuStatsModel.fromJson(Map<String, dynamic> json) {
    return GpuStatsModel(
      model: (json['model'] as String?) ?? 'GPU',
      vendor: (json['vendor'] as String?) ?? '',
      utilizationGpu: (json['utilizationGpu'] as num?)?.toDouble(),
      memoryTotal: (json['memoryTotal'] as num?)?.toInt(),
      memoryUsed: (json['memoryUsed'] as num?)?.toInt(),
      memoryFree: (json['memoryFree'] as num?)?.toInt(),
      temperatureGpu: (json['temperatureGpu'] as num?)?.toDouble(),
    );
  }
}

class SystemStatsModel {
  final int timestamp;
  final int uptime;
  final String platform;
  final String hostname;
  final CpuStatsModel cpu;
  final MemoryStatsModel memory;
  final List<DiskStatsModel> disks;
  final NetworkStatsModel network;
  final List<GpuStatsModel> gpu;
  final List<ProcessModel> topProcesses;

  const SystemStatsModel({
    required this.timestamp,
    required this.uptime,
    required this.platform,
    required this.hostname,
    required this.cpu,
    required this.memory,
    required this.disks,
    required this.network,
    required this.gpu,
    required this.topProcesses,
  });

  factory SystemStatsModel.fromJson(Map<String, dynamic> json) {
    return SystemStatsModel(
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      uptime: (json['uptime'] as num?)?.toInt() ?? 0,
      platform: (json['platform'] as String?) ?? '',
      hostname: (json['hostname'] as String?) ?? '',
      cpu: CpuStatsModel.fromJson(json['cpu'] as Map<String, dynamic>? ?? {}),
      memory: MemoryStatsModel.fromJson(json['memory'] as Map<String, dynamic>? ?? {}),
      disks: ((json['disks'] as List<dynamic>?) ?? [])
          .map((d) => DiskStatsModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      network: NetworkStatsModel.fromJson(json['network'] as Map<String, dynamic>? ?? {}),
      gpu: ((json['gpu'] as List<dynamic>?) ?? [])
          .map((g) => GpuStatsModel.fromJson(g as Map<String, dynamic>))
          .toList(),
      topProcesses: ((json['topProcesses'] as List<dynamic>?) ?? [])
          .map((p) => ProcessModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

