class CpuSpecModel {
  final String manufacturer;
  final String brand;
  final double speed;
  final double speedMin;
  final double speedMax;
  final int cores;
  final int physicalCores;
  final int processors;
  final String socket;

  const CpuSpecModel({
    required this.manufacturer,
    required this.brand,
    required this.speed,
    required this.speedMin,
    required this.speedMax,
    required this.cores,
    required this.physicalCores,
    required this.processors,
    required this.socket,
  });

  factory CpuSpecModel.fromJson(Map<String, dynamic> json) {
    return CpuSpecModel(
      manufacturer: (json['manufacturer'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      speedMin: (json['speedMin'] as num?)?.toDouble() ?? 0.0,
      speedMax: (json['speedMax'] as num?)?.toDouble() ?? 0.0,
      cores: (json['cores'] as num?)?.toInt() ?? 1,
      physicalCores: (json['physicalCores'] as num?)?.toInt() ?? 1,
      processors: (json['processors'] as num?)?.toInt() ?? 1,
      socket: (json['socket'] as String?) ?? '',
    );
  }
}

class MemSlotSpecModel {
  final int size;
  final String type;
  final int? clockSpeed;
  final String bank;

  const MemSlotSpecModel({
    required this.size,
    required this.type,
    this.clockSpeed,
    required this.bank,
  });

  factory MemSlotSpecModel.fromJson(Map<String, dynamic> json) {
    return MemSlotSpecModel(
      size: (json['size'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String?) ?? '',
      clockSpeed: (json['clockSpeed'] as num?)?.toInt(),
      bank: (json['bank'] as String?) ?? '',
    );
  }
}

class DiskSpecModel {
  final String device;
  final String type;
  final String name;
  final int size;
  final String interfaceType;

  const DiskSpecModel({
    required this.device,
    required this.type,
    required this.name,
    required this.size,
    required this.interfaceType,
  });

  factory DiskSpecModel.fromJson(Map<String, dynamic> json) {
    return DiskSpecModel(
      device: (json['device'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      interfaceType: (json['interfaceType'] as String?) ?? '',
    );
  }
}

class GpuSpecModel {
  final String vendor;
  final String model;
  final int? vram;
  final String driverVersion;

  const GpuSpecModel({
    required this.vendor,
    required this.model,
    this.vram,
    required this.driverVersion,
  });

  factory GpuSpecModel.fromJson(Map<String, dynamic> json) {
    return GpuSpecModel(
      vendor: (json['vendor'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      vram: (json['vram'] as num?)?.toInt(),
      driverVersion: (json['driverVersion'] as String?) ?? '',
    );
  }
}

class SystemSpecsModel {
  final String hostname;
  final String platform;
  final String distro;
  final String release;
  final String arch;
  final CpuSpecModel cpu;
  final int totalMemory;
  final List<MemSlotSpecModel> memLayout;
  final List<DiskSpecModel> disks;
  final List<GpuSpecModel> gpus;

  const SystemSpecsModel({
    required this.hostname,
    required this.platform,
    required this.distro,
    required this.release,
    required this.arch,
    required this.cpu,
    required this.totalMemory,
    required this.memLayout,
    required this.disks,
    required this.gpus,
  });

  factory SystemSpecsModel.fromJson(Map<String, dynamic> json) {
    final memJson = (json['memory'] as Map<String, dynamic>?) ?? {};
    return SystemSpecsModel(
      hostname: (json['hostname'] as String?) ?? '',
      platform: (json['platform'] as String?) ?? '',
      distro: (json['distro'] as String?) ?? '',
      release: (json['release'] as String?) ?? '',
      arch: (json['arch'] as String?) ?? '',
      cpu: CpuSpecModel.fromJson(json['cpu'] as Map<String, dynamic>? ?? {}),
      totalMemory: (memJson['total'] as num?)?.toInt() ?? 0,
      memLayout: ((memJson['layout'] as List<dynamic>?) ?? [])
          .map((m) => MemSlotSpecModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      disks: ((json['disks'] as List<dynamic>?) ?? [])
          .map((d) => DiskSpecModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      gpus: ((json['gpus'] as List<dynamic>?) ?? [])
          .map((g) => GpuSpecModel.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}

