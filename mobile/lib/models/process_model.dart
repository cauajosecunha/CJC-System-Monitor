class ProcessModel {
  final int pid;
  final String name;
  final double cpu;
  final double mem;
  final String user;

  const ProcessModel({
    required this.pid,
    required this.name,
    required this.cpu,
    required this.mem,
    required this.user,
  });

  factory ProcessModel.fromJson(Map<String, dynamic> json) {
    return ProcessModel(
      pid: (json['pid'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Processo',
      cpu: (json['cpu'] as num?)?.toDouble() ?? 0.0,
      mem: (json['mem'] as num?)?.toDouble() ?? 0.0,
      user: (json['user'] as String?) ?? 'system',
    );
  }
}

