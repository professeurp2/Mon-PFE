import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GRBL SYSTEM CONFIGURATION', style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Container(width: 80, height: 4, color: AppColors.primary),
            const SizedBox(height: 48),
            
            // Linear Axes Grid
            const Text('LINEAR AXES (MAPPING & STEPS)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(60),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(1),
                },
                children: [
                   _buildHeaderRow(),
                   _buildDataRow('X', 'STEPPER_M1', '80.00', '500', true),
                   _buildDataRow('Y', 'STEPPER_M2', '80.00', '500', true),
                   _buildDataRow('Z', 'STEPPER_M3', '400.00', '300', true),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Rotary Axes Cards
            const Text('ROTARY AXES (TRUNNION KINEMATICS)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _RotarySettingsCardHUD('A AXIS', 'ROT_M4', '1:10 Ratio'),
                _RotarySettingsCardHUD('B AXIS', 'ROT_M5', '1:20 Ratio'),
              ],
            ),
            
            const SizedBox(height: 48),
            
            // System Limits
            const Text('CORE SAFETY LIMITS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
            const SizedBox(height: 12),
            GlassPanel(
              expand: false,
              child: Column(
                children: [
                  _SystemConfigRowHUD('HARD LIMITS', true),
                  _SystemConfigRowHUD('SOFT LIMITS', true),
                  _SystemConfigRowHUD('HOMING ENABLED', true),
                  _SystemConfigRowHUD('AUTO TOOL ZERO', false),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Actions
            Row(
              children: [
                _ActionHUDButtonLarge(Icons.save, 'COMMIT TO ESP32', AppColors.primary),
                const SizedBox(width: 16),
                _ActionHUDButtonLarge(Icons.refresh, 'REVERT CHANGES', AppColors.textDisabled),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: AppColors.surfaceBright),
      children: [
        'AXE', 'DRIVER', 'STEPS/MM', 'ACCEL', 'STATE'
      ].map((e) => Padding(padding: const EdgeInsets.all(16), child: Text(e, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)))).toList(),
    );
  }

  TableRow _buildDataRow(String axis, String driver, String steps, String accel, bool active) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(axis, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14))),
        Padding(padding: const EdgeInsets.all(16), child: Text(driver, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
        Padding(padding: const EdgeInsets.all(16), child: Text(steps, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'JetBrains Mono'))),
        Padding(padding: const EdgeInsets.all(16), child: Text(accel, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'JetBrains Mono'))),
        Padding(padding: const EdgeInsets.all(16), child: Icon(Icons.check_circle, color: active ? AppColors.success : AppColors.textDisabled, size: 16)),
      ],
    );
  }
}

class _RotarySettingsCardHUD extends StatelessWidget {
  final String title;
  final String driver;
  final String ratio;
  const _RotarySettingsCardHUD(this.title, this.driver, this.ratio);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.surfaceBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              const Icon(Icons.settings_input_component, color: AppColors.textDisabled, size: 16),
            ],
          ),
          const SizedBox(height: 24),
          _SmallSettingHUD('DRIVER ID', driver),
          _SmallSettingHUD('GEAR RATIO', ratio),
          _SmallSettingHUD('MAX VELOCITY', '120 deg/s'),
        ],
      ),
    );
  }
}

class _SmallSettingHUD extends StatelessWidget {
  final String label;
  final String value;
  const _SmallSettingHUD(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono')),
        ],
      ),
    );
  }
}

class _SystemConfigRowHUD extends StatelessWidget {
  final String label;
  final bool active;
  const _SystemConfigRowHUD(this.label, this.active);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          Switch(value: active, onChanged: (v){}, activeColor: AppColors.primary, activeTrackColor: AppColors.primary.withOpacity(0.2)),
        ],
      ),
    );
  }
}

class _ActionHUDButtonLarge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionHUDButtonLarge(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.12), foregroundColor: color, side: BorderSide(color: color.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24)),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0)),
    );
  }
}
