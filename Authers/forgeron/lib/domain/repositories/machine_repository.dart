import '../entities/machine_state.dart';

/// Contrat (interface) du domaine pour piloter la machine CNC.
/// Les implémentations concrètes sont dans la couche Data.
abstract class MachineRepository {
  /// Se connecte à l'ESP32 via UDP.
  Future<void> connect(String ip, int port);

  /// Déconnecte le socket UDP.
  Future<void> disconnect();

  /// Envoie une commande brute (G-Code, $H, etc.) à l'ESP32.
  Future<void> sendCommand(String command);

  /// Envoie un déplacement de jog sur un axe donné.
  Future<void> jog(String axis, double stepMm, double feedrateMmMin);

  /// Stream de mises à jour de l'état de la machine reçues de l'ESP32.
  Stream<MachineState> get stateStream;

  /// État courant de la machine.
  MachineState get currentState;
}
