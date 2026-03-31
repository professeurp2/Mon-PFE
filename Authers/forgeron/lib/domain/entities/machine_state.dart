/// Représente l'état de la machine CNC (FSM).
enum MachineStatus { idle, homing, run, hold, alarm, disconnected }

/// Entité principale de l'état de la machine CNC 5 Axes.
/// Layer : Domain — aucune dépendance Flutter ou réseau.
class MachineState {
  final MachineStatus status;
  final double x;
  final double y;
  final double z;
  final double a; // Tilt (degré)
  final double b; // Pan (degré)
  final double feedrate; // mm/min
  final double spindleSpeed; // tr/min
  final bool limitX;
  final bool limitY;
  final bool limitZ;
  final String lastError;

  const MachineState({
    this.status = MachineStatus.disconnected,
    this.x = 0.0,
    this.y = 0.0,
    this.z = 0.0,
    this.a = 0.0,
    this.b = 0.0,
    this.feedrate = 0.0,
    this.spindleSpeed = 0.0,
    this.limitX = false,
    this.limitY = false,
    this.limitZ = false,
    this.lastError = '',
  });

  MachineState copyWith({
    MachineStatus? status,
    double? x,
    double? y,
    double? z,
    double? a,
    double? b,
    double? feedrate,
    double? spindleSpeed,
    bool? limitX,
    bool? limitY,
    bool? limitZ,
    String? lastError,
  }) {
    return MachineState(
      status: status ?? this.status,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      a: a ?? this.a,
      b: b ?? this.b,
      feedrate: feedrate ?? this.feedrate,
      spindleSpeed: spindleSpeed ?? this.spindleSpeed,
      limitX: limitX ?? this.limitX,
      limitY: limitY ?? this.limitY,
      limitZ: limitZ ?? this.limitZ,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Parse depuis un JSON envoyé par l'ESP32.
  factory MachineState.fromJson(Map<String, dynamic> json) {
    return MachineState(
      status: _parseStatus(json['status'] as String? ?? 'idle'),
      x: (json['x'] as num? ?? 0).toDouble(),
      y: (json['y'] as num? ?? 0).toDouble(),
      z: (json['z'] as num? ?? 0).toDouble(),
      a: (json['a'] as num? ?? 0).toDouble(),
      b: (json['b'] as num? ?? 0).toDouble(),
      feedrate: (json['f'] as num? ?? 0).toDouble(),
      spindleSpeed: (json['s'] as num? ?? 0).toDouble(),
      limitX: json['lx'] as bool? ?? false,
      limitY: json['ly'] as bool? ?? false,
      limitZ: json['lz'] as bool? ?? false,
    );
  }

  static MachineStatus _parseStatus(String s) {
    switch (s.toUpperCase()) {
      case 'IDLE':    return MachineStatus.idle;
      case 'HOMING':  return MachineStatus.homing;
      case 'RUN':     return MachineStatus.run;
      case 'HOLD':    return MachineStatus.hold;
      case 'ALARM':   return MachineStatus.alarm;
      default:        return MachineStatus.disconnected;
    }
  }

  @override
  String toString() =>
      'MachineState(status: $status, X:$x Y:$y Z:$z A:$a B:$b)';
}
