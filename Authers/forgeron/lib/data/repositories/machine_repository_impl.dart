import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/machine_state.dart';
import '../../domain/repositories/machine_repository.dart';

/// Implémentation concrète de [MachineRepository] via socket UDP natif Dart.
/// Gère l'envoi de commandes G-Code et la réception de l'état de la machine.
class MachineRepositoryImpl implements MachineRepository {
  RawDatagramSocket? _socket;
  InternetAddress? _espAddress;
  int _espPort = 2222;

  final _stateController = StreamController<MachineState>.broadcast();
  MachineState _currentState = const MachineState();

  @override
  MachineState get currentState => _currentState;

  @override
  Stream<MachineState> get stateStream => _stateController.stream;

  @override
  Future<void> connect(String ip, int port) async {
    _espAddress = InternetAddress(ip);
    _espPort = port;

    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.listen(_onData, onError: _onError);

    // Mettre à jour l'état => connecté (envoi ping)
    await sendCommand('\$I'); // Demande d'informations à l'ESP32
    _currentState = _currentState.copyWith(status: MachineStatus.idle);
    _stateController.add(_currentState);
  }

  @override
  Future<void> disconnect() async {
    _socket?.close();
    _socket = null;
    _currentState = const MachineState();
    _stateController.add(_currentState);
  }

  @override
  Future<void> sendCommand(String command) async {
    if (_socket == null || _espAddress == null) return;
    final data = utf8.encode('$command\n');
    _socket!.send(data, _espAddress!, _espPort);
  }

  @override
  Future<void> jog(String axis, double stepMm, double feedrateMmMin) async {
    // Format de jog GRBL étendu : $J=G91G21Xx.x Fy
    final cmd = '\$J=G91G21${axis.toUpperCase()}${stepMm.toStringAsFixed(3)} F${feedrateMmMin.toInt()}';
    await sendCommand(cmd);
  }

  void _onData(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;

    try {
      final raw = utf8.decode(datagram.data);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _currentState = MachineState.fromJson(json);
      _stateController.add(_currentState);
    } catch (_) {
      // Paquet non-JSON (ACK texte, etc.) → ignorer
    }
  }

  void _onError(Object error) {
    _currentState = _currentState.copyWith(
      status: MachineStatus.alarm,
      lastError: error.toString(),
    );
    _stateController.add(_currentState);
  }

  void dispose() {
    _socket?.close();
    _stateController.close();
  }
}
