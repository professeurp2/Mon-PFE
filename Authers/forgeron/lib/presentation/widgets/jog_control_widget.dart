import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';
import '../providers/machine_provider.dart';
import '../../domain/entities/machine_state.dart';
import 'glass_panel.dart';

/// Panneau de contrôle de jog — 5 axes (X, Y, Z, A, B).
class JogControlWidget extends ConsumerWidget {
  const JogControlWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jogSettings = ref.watch(jogSettingsProvider);
    final machineState = ref.watch(machineProvider);
    final isConnected = machineState.status != MachineStatus.disconnected &&
        machineState.status != MachineStatus.alarm;

    return GlassPanel(
      title: 'CONTRÔLE MANUEL',
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sélecteur de pas ────────────────────────────
          _StepSelector(
            current: jogSettings.stepMm,
            onChanged: (v) => ref.read(jogSettingsProvider.notifier)
                .state = jogSettings.copyWith(stepMm: v),
          ),
          const SizedBox(height: AppSizes.paddingM),

          // ── Pavé XY ─────────────────────────────────────
          _buildSectionLabel('AXES LINÉAIRES'),
          const SizedBox(height: AppSizes.paddingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AxisPad(
                axis: 'Y',
                color: AppColors.axisY,
                enabled: isConnected,
                step: jogSettings.stepMm,
                feedrate: jogSettings.feedrateMmMin,
              ),
              const SizedBox(width: AppSizes.paddingL),
              _AxisPad(
                axis: 'X',
                color: AppColors.axisX,
                enabled: isConnected,
                step: jogSettings.stepMm,
                feedrate: jogSettings.feedrateMmMin,
              ),
              const SizedBox(width: AppSizes.paddingL),
              _AxisPad(
                axis: 'Z',
                color: AppColors.axisZ,
                enabled: isConnected,
                step: jogSettings.stepMm,
                feedrate: jogSettings.feedrateMmMin,
                isVertical: true,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingM),

          // ── Axes rotatifs A / B ──────────────────────────
          _buildSectionLabel('AXES ROTATIFS (TRUNNION)'),
          const SizedBox(height: AppSizes.paddingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RotaryAxis(
                label: 'A (TILT)',
                color: AppColors.axisA,
                axis: 'A',
                enabled: isConnected,
                step: jogSettings.stepMm,
                feedrate: jogSettings.feedrateMmMin,
              ),
              const SizedBox(width: AppSizes.paddingL),
              _RotaryAxis(
                label: 'B (PAN)',
                color: AppColors.axisB,
                axis: 'B',
                enabled: isConnected,
                step: jogSettings.stepMm,
                feedrate: jogSettings.feedrateMmMin,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingM),

          // ── Vitesse d'avance ─────────────────────────────
          _FeedrateSlider(
            value: jogSettings.feedrateMmMin,
            onChanged: (v) => ref.read(jogSettingsProvider.notifier)
                .state = jogSettings.copyWith(feedrateMmMin: v),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textDisabled,
        fontSize: 10,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Sélecteur de pas ──────────────────────────────────────────────────────────
class _StepSelector extends StatelessWidget {
  final double current;
  final ValueChanged<double> onChanged;

  const _StepSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingXS,
      children: [
        const Text('PAS :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ...AppConstants.jogSteps.map((step) {
          final selected = step == current;
          return ChoiceChip(
            label: Text(step < 1 ? '${step}mm' : '${step.toInt()}mm'),
            selected: selected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 11,
            ),
            onSelected: (_) => onChanged(step),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            visualDensity: VisualDensity.compact,
          );
        }),
      ],
    );
  }
}

// ─── Pavé d'axe linéaire (boutons +/-) ────────────────────────────────────────
class _AxisPad extends ConsumerWidget {
  final String axis;
  final Color color;
  final bool enabled;
  final double step;
  final double feedrate;
  final bool isVertical;

  const _AxisPad({
    required this.axis,
    required this.color,
    required this.enabled,
    required this.step,
    required this.feedrate,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget btn(String dir, double v) => _JogButton(
          label: '$axis$dir',
          color: color,
          enabled: enabled,
          onTap: () => ref
              .read(machineProvider.notifier)
              .jog(axis, v, feedrate),
        );

    return Column(
      children: [
        Text(axis, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        btn('+', step),
        const SizedBox(height: 4),
        btn('-', -step),
      ],
    );
  }
}

// ─── Axe rotatif (boutons + et - avec icône arc) ──────────────────────────────
class _RotaryAxis extends ConsumerWidget {
  final String label;
  final Color color;
  final String axis;
  final bool enabled;
  final double step;
  final double feedrate;

  const _RotaryAxis({
    required this.label,
    required this.color,
    required this.axis,
    required this.enabled,
    required this.step,
    required this.feedrate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(machineProvider.notifier);
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            _JogButton(
              label: '↺',
              color: color,
              enabled: enabled,
              onTap: () => notifier.jog(axis, -step, feedrate),
            ),
            const SizedBox(width: 4),
            _JogButton(
              label: '↻',
              color: color,
              enabled: enabled,
              onTap: () => notifier.jog(axis, step, feedrate),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Bouton Jog individuel ────────────────────────────────────────────────────
class _JogButton extends StatefulWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _JogButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_JogButton> createState() => _JogButtonState();
}

class _JogButtonState extends State<_JogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) { setState(() => _pressed = false); widget.onTap(); } : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: AppSizes.jogButtonSize,
        height: AppSizes.jogButtonSize,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.3)
              : AppColors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: Border.all(
            color: widget.enabled ? widget.color.withOpacity(0.6) : AppColors.textDisabled,
            width: 1.5,
          ),
          boxShadow: _pressed
              ? [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 12)]
              : [],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.enabled ? widget.color : AppColors.textDisabled,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Slider de vitesse d'avance ───────────────────────────────────────────────
class _FeedrateSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _FeedrateSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.speed, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        const Text('F :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.primaryLight,
              overlayColor: AppColors.primary.withOpacity(0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: 10,
              max: AppConstants.feedrateMax,
              onChanged: onChanged,
            ),
          ),
        ),
        Text(
          '${value.toInt()} mm/min',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
      ],
    );
  }
}
