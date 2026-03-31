/// Constantes globales de l'application Forgeron (CNC 5 Axes).
abstract class AppConstants {
  // Communication UDP
  static const int  udpPort          = 2222;
  static const int  udpTimeoutMs     = 5000;
  static const String defaultEspIp   = '192.168.1.100';

  // CNC – limites des axes (mm / degrés)
  static const double axisXMax  = 200.0;
  static const double axisYMax  = 200.0;
  static const double axisZMax  = 150.0;
  static const double axisAMin  = -90.0;
  static const double axisAMax  =  90.0;
  static const double axisBMax  = 360.0;

  // Pas de Jog disponibles (mm)
  static const List<double> jogSteps = [0.01, 0.1, 1.0, 10.0];

  // Vitesse d'avance max (mm/min)
  static const double feedrateMax = 3000.0;

  // Intervalle de rafraîchissement de télémétrie (ms)
  static const int telemetryIntervalMs = 100;
}
