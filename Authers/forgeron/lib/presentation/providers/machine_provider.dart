import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/machine_repository_impl.dart';
import '../../domain/entities/machine_state.dart';
import '../../domain/repositories/machine_repository.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────
final machineRepositoryProvider = Provider<MachineRepository>((ref) {
  final repo = MachineRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});

// ─── Connection Settings ──────────────────────────────────────────────────────
class ConnectionSettings {
  final String ip;
  final int port;
  const ConnectionSettings({
    this.ip = AppConstants.defaultEspIp,
    this.port = AppConstants.udpPort,
  });

  ConnectionSettings copyWith({String? ip, int? port}) =>
      ConnectionSettings(ip: ip ?? this.ip, port: port ?? this.port);
}

final connectionSettingsProvider =
    StateProvider<ConnectionSettings>((ref) => const ConnectionSettings());

// ─── Machine State Notifier ───────────────────────────────────────────────────
class MachineNotifier extends StateNotifier<MachineState> {
  final MachineRepository _repository;
  StreamSubscription<MachineState>? _subscription;

  MachineNotifier(this._repository) : super(const MachineState()) {
    _subscription = _repository.stateStream.listen((s) => state = s);
  }

  Future<void> connect(String ip, int port) async {
    await _repository.connect(ip, port);
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
  }

  Future<void> sendCommand(String cmd) => _repository.sendCommand(cmd);

  Future<void> home() => _repository.sendCommand('\$H');

  Future<void> unlock() => _repository.sendCommand('\$X');

  Future<void> feedhold() => _repository.sendCommand('!');

  Future<void> cycleResume() => _repository.sendCommand('~');

  Future<void> cycleStop() => _repository.sendCommand('\x18'); // Ctrl-X

  Future<void> jog(String axis, double step, double feedrate) =>
      _repository.jog(axis, step, feedrate);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final machineProvider =
    StateNotifierProvider<MachineNotifier, MachineState>((ref) {
  final repo = ref.watch(machineRepositoryProvider);
  return MachineNotifier(repo);
});

// ─── Jog Settings ─────────────────────────────────────────────────────────────
class JogSettings {
  final double stepMm;
  final double feedrateMmMin;
  const JogSettings({this.stepMm = 1.0, this.feedrateMmMin = 500.0});

  JogSettings copyWith({double? stepMm, double? feedrateMmMin}) =>
      JogSettings(
        stepMm: stepMm ?? this.stepMm,
        feedrateMmMin: feedrateMmMin ?? this.feedrateMmMin,
      );
}

final jogSettingsProvider =
    StateProvider<JogSettings>((ref) => const JogSettings());
