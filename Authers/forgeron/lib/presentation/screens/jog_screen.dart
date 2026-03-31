import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/machine_state.dart';
import '../providers/machine_provider.dart';
import '../widgets/glass_panel.dart';

class JogScreen extends ConsumerWidget {
  const JogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machine = ref.watch(machineProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Wrap(
          spacing: 32,
          runSpacing: 32,
          alignment: WrapAlignment.center,
          children: [
            // ── LEFT: LINEAR AXES (X, Y, Z) ──
            SizedBox(
              width: 580,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LINEAR MOTION CONTROL', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 4, color: AppColors.primary),
                  const SizedBox(height: 24),
                  
                  // Main Jog Area
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // XY Pad
                        _XYControllerHUD(),
                        
                        // Z Axis
                        _ZAxisControllerHUD(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Step Selection
                  const Text('RESOLUTION (STEP SIZE)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: _StepBoxHUD('0.001', false)),
                      SizedBox(width: 12),
                      Expanded(child: _StepBoxHUD('0.01', false)),
                      SizedBox(width: 12),
                      Expanded(child: _StepBoxHUD('0.1', true)),
                      SizedBox(width: 12),
                      Expanded(child: _StepBoxHUD('1.0', false)),
                      SizedBox(width: 12),
                      Expanded(child: _StepBoxHUD('10.0', false)),
                    ],
                  ),
                ],
              ),
            ),
            
            // ── RIGHT: ROTARY AXES & SECURITY ──
            SizedBox(
              width: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ROTARY & SECURITY', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 4, color: AppColors.secondary),
                  const SizedBox(height: 24),
                  
                  // Rotary A/B
                  _RotaryCardHUD('A', machine.a),
                  const SizedBox(height: 12),
                  _RotaryCardHUD('B', machine.b),
                  
                  const SizedBox(height: 32),
                  
                  // Safety Interlock
                  GlassPanel(
                    expand: false,
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security, color: AppColors.danger, size: 20),
                            SizedBox(width: 12),
                            Text('SAFETY INTERLOCK', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 14)),
                            Spacer(),
                            Text('ARMED', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Text('Autoriser le mouvement manuel via les contrôles physiques extérieurs.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))),
                            Switch(value: true, onChanged: (v){}, activeColor: AppColors.danger, activeTrackColor: AppColors.danger.withOpacity(0.2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Jog Info
                  const Text('JOG TELEMETRY', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.background,
                    child: Column(
                      children: [
                        _TeleRowJog('CURRENT FEED', 'F${machine.feedrate.toInt()}'),
                        _TeleRowJog('OVERRIDE', '100%'),
                        _TeleRowJog('LIMITS', 'OK'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XYControllerHUD extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('X-Y PAD', style: TextStyle(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _JogButtonHUD(Icons.arrow_upward, 'Y+', AppColors.primary),
        const SizedBox(height: 12),
        Row(
          children: [
            _JogButtonHUD(Icons.arrow_back, 'X-', AppColors.primary),
            const SizedBox(width: 12),
            Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.surfaceBorder))),
            const SizedBox(width: 12),
            _JogButtonHUD(Icons.arrow_forward, 'X+', AppColors.primary),
          ],
        ),
        const SizedBox(height: 12),
        _JogButtonHUD(Icons.arrow_downward, 'Y-', AppColors.primary),
      ],
    );
  }
}

class _ZAxisControllerHUD extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Z-AXIS', style: TextStyle(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _JogButtonHUD(Icons.add, 'Z+', AppColors.secondary, vert: true),
        const SizedBox(height: 48),
        _JogButtonHUD(Icons.remove, 'Z-', AppColors.secondary, vert: true),
      ],
    );
  }
}

class _JogButtonHUD extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool vert;
  const _JogButtonHUD(this.icon, this.label, this.color, {this.vert = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'JetBrains Mono')),
              const SizedBox(height: 4),
              Icon(icon, color: AppColors.textPrimary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RotaryCardHUD extends StatelessWidget {
  final String axis;
  final double value;
  const _RotaryCardHUD(this.axis, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Text(axis, style: const TextStyle(color: AppColors.secondary, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono')),
          const SizedBox(width: 32),
          Column(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.keyboard_arrow_up, color: AppColors.textDisabled)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDisabled)),
            ],
          ),
          const Spacer(),
          Text(value.toStringAsFixed(2), style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono')),
          const SizedBox(width: 8),
          const Text('deg', style: TextStyle(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StepBoxHUD extends StatelessWidget {
  final String label;
  final bool selected;
  const _StepBoxHUD(this.label, this.selected);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label, 
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.textPrimary, 
            fontWeight: FontWeight.w900, 
            fontSize: 12,
            fontFamily: 'JetBrains Mono'
          )
        ),
      ),
    );
  }
}

class _TeleRowJog extends StatelessWidget {
  final String label;
  final String value;
  const _TeleRowJog(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono')),
        ],
      ),
    );
  }
}
