import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_panel.dart';

class GCodeScreen extends StatelessWidget {
  const GCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LEFT: G-CODE STREAM ──
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('COMMAND STREAM', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const Spacer(),
                    _EditorToolBtn(Icons.file_open, 'UPLOAD'),
                    const SizedBox(width: 8),
                    _EditorToolBtn(Icons.save, 'SAVE'),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)), child: const Text('TRANSMIT TO CORE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Active Editor
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: const SingleChildScrollView(
                      child: Column(
                        children: [
                          _GCodeLineHUD(1241, 'G01', 'X122.10 Y-45.12 Z-12.00', 'F800', isPast: true),
                          _GCodeLineHUD(1242, 'G01', 'X123.50 Y-45.50 Z-12.30', 'F800', isPast: true),
                          _GCodeLineHUD(1243, 'M08', '; Coolant On', '', isPast: true),
                          _GCodeLineHUD(1244, 'G01', 'X124.80 Y-44.90 Z-12.60', 'F800', isActive: true),
                          _GCodeLineHUD(1245, 'G01', 'X125.34 Y-45.12 Z-12.78 A45.0 B90.0', 'F800'),
                          _GCodeLineHUD(1246, 'G01', 'X126.80 Y-45.30 Z-12.90', 'F800'),
                          _GCodeLineHUD(1247, 'G01', 'X127.12 Y-45.80 Z-13.10', 'F800'),
                          _GCodeLineHUD(1248, 'M05', '; End Segment', ''),
                        ],
                      ),
                    ),
                  ),
                ),
                // Footer Editor
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(color: AppColors.surface, border: Border(left: BorderSide(color: AppColors.surfaceBorder), right: BorderSide(color: AppColors.surfaceBorder), bottom: BorderSide(color: AppColors.surfaceBorder))),
                  child: const Row(
                    children: [
                      Text('LINE: 1244', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                      SizedBox(width: 24),
                      Text('ISO 6983 COMPLIANT', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text('UTF-8', style: TextStyle(color: AppColors.textDisabled, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(width: 32),
          
          // ── RIGHT: ANALYTICS HUD ──
          SizedBox(
            width: 340,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ANALYTICS ENGINE', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Container(width: 40, height: 4, color: AppColors.primary),
                const SizedBox(height: 32),
                
                _AnalyticsCardHUD('EST. DURATION', '01h 42m', Icons.timer),
                const SizedBox(height: 12),
                _AnalyticsCardHUD('TOTAL DISTANCE', '4 825 mm', Icons.straighten),
                const SizedBox(height: 12),
                _AnalyticsCardHUD('PEAK FEEDRATE', 'F3500', Icons.speed),
                
                const SizedBox(height: 32),
                
                // Machine Limits
                const Text('PRE-FLIGHT VALIDATION', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                const SizedBox(height: 12),
                GlassPanel(
                  expand: false,
                  child: Column(
                    children: [
                      _ValidationRowHUD('XYZ BOUNDARIES', true),
                      _ValidationRowHUD('ROTARY RANGE (AB)', true),
                      _ValidationRowHUD('SPINDLE SPEED (RPM)', true),
                      _ValidationRowHUD('G-CODE SYNTX (CRC)', true),
                    ],
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EditorToolBtn(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.surfaceBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20)),
      icon: Icon(icon, color: AppColors.textSecondary, size: 16),
      label: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _GCodeLineHUD extends StatelessWidget {
  final int number;
  final String cmd;
  final String args;
  final String feed;
  final bool isPast;
  final bool isActive;

  const _GCodeLineHUD(this.number, this.cmd, this.args, this.feed, {this.isPast = false, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    Color textColor = isActive ? AppColors.textPrimary : (isPast ? AppColors.textDisabled : AppColors.textSecondary);
    
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceBright : Colors.transparent,
        border: Border(left: BorderSide(color: isActive ? AppColors.primary : Colors.transparent, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(number.toString(), style: TextStyle(color: AppColors.textDisabled.withOpacity(0.5), fontSize: 12, fontFamily: 'JetBrains Mono'))),
          Text(cmd, style: TextStyle(color: isActive ? AppColors.warning : textColor, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontFamily: 'JetBrains Mono')),
          const SizedBox(width: 12),
          Expanded(child: Text(args, style: TextStyle(color: textColor, fontSize: 13, fontFamily: 'JetBrains Mono'))),
          Text(feed, style: TextStyle(color: isPast ? AppColors.textDisabled : AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono')),
        ],
      ),
    );
  }
}

class _AnalyticsCardHUD extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _AnalyticsCardHUD(this.title, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.surfaceBorder)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDisabled, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textDisabled, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidationRowHUD extends StatelessWidget {
  final String label;
  final bool isValid;
  const _ValidationRowHUD(this.label, this.isValid);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: isValid ? AppColors.success : AppColors.danger, size: 14),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
