import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/machine_state.dart';
import '../providers/machine_provider.dart';
import '../widgets/glass_panel.dart';

class DashboardScreenContent extends ConsumerWidget {
  const DashboardScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machine = ref.watch(machineProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32), // More whitespace as per specs
      child: Center(
        child: Wrap(
          spacing: 32,
          runSpacing: 32,
          alignment: WrapAlignment.center,
          children: [
            // ── LEFT: INDUSTRIAL HUD ──
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ConnectionHUD(),
                  const SizedBox(height: 24),
                  const Text('MACHINE ACTIONS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const SizedBox(height: 12),
                  _ActionGridHUD(),
                  const SizedBox(height: 24),
                  _MachineTelemetryHUD(machine: machine),
                ],
              ),
            ),
            
            // ── CENTER: KINETIC VISUALIZER ──
            SizedBox(
              width: 540,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PATH VISUALIZATION', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: GlassPanel(
                      expand: true,
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(Icons.architecture, color: AppColors.surfaceBorder, size: 100),
                          ),
                          // Viewport Info
                          Positioned(
                            top: 24,
                            left: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PERSPECTIVE VIEW', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
                                Text('MODEL: TRUNNION_5X_V2.STL', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 9)),
                              ],
                            ),
                          ),
                          // Path Progress Overlay
                          Positioned(
                            bottom: 24,
                            left: 24,
                            right: 24,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: const Column(
                                children: [
                                  Row(children: [Text('CYCLE PROGRESS', style: TextStyle(color: AppColors.textPrimary, fontSize: 9, fontWeight: FontWeight.bold)), Spacer(), Text('18.4%', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12))]),
                                  SizedBox(height: 8),
                                  LinearProgressIndicator(value: 0.184, backgroundColor: Colors.black, color: AppColors.primary, minHeight: 4),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ── RIGHT: PRECISION COORDINATES ──
            SizedBox(
              width: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRECISION COORDINATES (WCS)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const SizedBox(height: 12),
                  _CoordinateCardHUD('X', machine.x, AppColors.primary, isMoving: true),
                  const SizedBox(height: 8),
                  _CoordinateCardHUD('Y', machine.y, AppColors.primary, isMoving: false),
                  const SizedBox(height: 8),
                  _CoordinateCardHUD('Z', machine.z, AppColors.primary, isMoving: false),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _CoordinateCardHUD('A', machine.a, AppColors.secondary, small: true, isMoving: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _CoordinateCardHUD('B', machine.b, AppColors.secondary, small: true, isMoving: false)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('DYNAMIQUE D\'USINAGE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const SizedBox(height: 12),
                  GlassPanel(
                    expand: false,
                    child: Column(
                      children: [
                        _DynamicRowHUD('FEEDRATE', 'F${machine.feedrate.toInt()}', 'mm/min'),
                        _DynamicRowHUD('SPINDLE', '${machine.spindleSpeed.toInt()} RPM', 'S-MAX'),
                        _DynamicRowHUD('LOAD', '42.8%', 'kW'),
                        const Divider(color: AppColors.surfaceBorder, height: 24),
                        const _DynamicRowHUD('ESTIMATED', '00:18:42', 'TIME'),
                      ],
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinateCardHUD extends StatelessWidget {
  final String axis;
  final double value;
  final Color color;
  final bool small;
  final bool isMoving;

  const _CoordinateCardHUD(this.axis, this.value, this.color, {this.small = false, this.isMoving = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: small ? 14 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isMoving ? color.withOpacity(0.3) : AppColors.surfaceBorder),
        boxShadow: isMoving ? [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, spreadRadius: 0)] : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            axis, 
            style: TextStyle(
              color: isMoving ? color : AppColors.textSecondary, 
              fontSize: small ? 14 : 20, 
              fontWeight: FontWeight.w900,
              fontFamily: 'JetBrains Mono',
              shadows: isMoving ? [Shadow(color: color, blurRadius: 10)] : null,
            )
          ),
          const Spacer(),
          Text(
            value.toStringAsFixed(3), 
            style: TextStyle(
              color: AppColors.textPrimary, 
              fontSize: small ? 24 : 38, 
              fontWeight: FontWeight.w900, 
              fontFamily: 'JetBrains Mono',
              letterSpacing: -1.0,
            )
          ),
          const SizedBox(width: 8),
          const Text('mm', style: TextStyle(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ConnectionHUD extends StatelessWidget {
  const _ConnectionHUD();
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      expand: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LINK: LOCALHOST:8080', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('CORE GRBL', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success, boxShadow: [BoxShadow(color: AppColors.success, blurRadius: 8)]))
            ],
          ),
          const SizedBox(height: 16),
          _HUDMiniLog('INIT SYSTEM... OK'),
          _HUDMiniLog('PARSING G-CODE... OK'),
          _HUDMiniLog('BUFFER: 98.4%'),
        ],
      )
    );
  }
}

class _HUDMiniLog extends StatelessWidget {
  final String text;
  _HUDMiniLog(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionGridHUD extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: [
        _ActionHUDButton(Icons.play_arrow, 'START', AppColors.success),
        _ActionHUDButton(Icons.pause, 'PAUSE', AppColors.warning),
        _ActionHUDButton(Icons.stop, 'TENSION', AppColors.danger),
        _ActionHUDButton(Icons.refresh, 'RESET', AppColors.textDisabled),
      ],
    );
  }
}

class _ActionHUDButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionHUDButton(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

class _MachineTelemetryHUD extends StatelessWidget {
  final MachineState machine;
  const _MachineTelemetryHUD({required this.machine});
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
       expand: false,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Row(children: [Text('SENSOR TELEMETRY', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)), Spacer(), Icon(Icons.waves, color: AppColors.primary, size: 12)]),
           const SizedBox(height: 16),
           _TeleRowHUD('TEMP CORE', '42.5', '°C'),
           _TeleRowHUD('VOLTAGE', '24.1', 'V'),
           _TeleRowHUD('AMPERE', '2.4', 'A'),
         ],
       )
    );
  }
}

class _DynamicRowHUD extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _DynamicRowHUD(this.label, this.value, this.unit);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono')),
          const SizedBox(width: 4),
          Text(unit, style: const TextStyle(color: AppColors.textDisabled, fontSize: 8)),
        ],
      ),
    );
  }
}

class _TeleRowHUD extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _TeleRowHUD(this.label, this.value, this.unit);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDisabled, fontSize: 9, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(unit, style: const TextStyle(color: AppColors.textDisabled, fontSize: 8)),
        ],
      ),
    );
  }
}
