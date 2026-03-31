import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/machine_state.dart';
import '../providers/machine_provider.dart';
import 'dashboard_screen.dart';
import 'jog_screen.dart';
import 'gcode_screen.dart';
import 'settings_screen.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  String _currentTime = '';
  Timer? _timer;

  final List<Widget> _screens = [
    const DashboardScreenContent(),
    const JogScreen(),
    const GCodeScreen(),
    const Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text("Homing", style: TextStyle(color: Colors.white)))),
    const SettingsScreen(),
    const Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text("Sécurité", style: TextStyle(color: Colors.white)))),
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('yyyy-MM-dd | HH:mm:ss').format(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final machine = ref.watch(machineProvider);
    final isConnected = machine.status != MachineStatus.disconnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _StatusFooter(currentTime: _currentTime),
      body: Column(
        children: [
          // ── TOP HEADER (CNC THEMIS) ──
          _HeaderBar(
            machine: machine, 
            isConnected: isConnected,
            isSidebarExpanded: _isSidebarExpanded,
            onMenuToggle: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
          ),
          
          Expanded(
            child: Row(
              children: [
                // ── SIDEBAR ──
                _Sidebar(
                  selectedIndex: _selectedIndex,
                  isExpanded: _isSidebarExpanded,
                  onItemSelected: (index) => setState(() => _selectedIndex = index),
                ),
                
                // ── MAIN CONTENT ──
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final MachineState machine;
  final bool isConnected;
  final bool isSidebarExpanded;
  final VoidCallback onMenuToggle;

  const _HeaderBar({
    required this.machine, 
    required this.isConnected,
    required this.isSidebarExpanded,
    required this.onMenuToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          // Menu Toggle Button
          IconButton(
            icon: Icon(isSidebarExpanded ? Icons.menu_open : Icons.menu, color: AppColors.textPrimary),
            onPressed: onMenuToggle,
          ),
          const SizedBox(width: 8),
          const Text(
            'CNC THEMIS',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 48),
          
          _HeaderStatusIndicator(
            label: 'IDLE',
            isActive: machine.status == MachineStatus.idle,
            color: AppColors.success,
          ),
          const SizedBox(width: 24),
          _HeaderStatusIndicator(
            label: 'LINK',
            isActive: isConnected,
            color: AppColors.primary,
          ),
          
          const Spacer(),
          
          // Emergency Button
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              ),
              onPressed: () {},
              icon: const Icon(Icons.error_outline),
              label: const Text('EMERGENCY STOP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatusIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  const _HeaderStatusIndicator({required this.label, required this.isActive, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: isActive ? color : AppColors.textDisabled, size: 8),
        const SizedBox(width: 8),
        Text(
          label, 
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textDisabled, 
            fontWeight: FontWeight.bold, 
            fontSize: 11,
            letterSpacing: 1.0
          )
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final bool isExpanded;
  final Function(int) onItemSelected;

  const _Sidebar({
    required this.selectedIndex, 
    required this.isExpanded,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isExpanded ? 260 : 72,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _NavItem(title: 'DASHBOARD', icon: Icons.dashboard, selected: selectedIndex == 0, isExpanded: isExpanded, onTap: () => onItemSelected(0)),
          _NavItem(title: 'CONTRÔLE MANUEL', icon: Icons.control_camera, selected: selectedIndex == 1, isExpanded: isExpanded, onTap: () => onItemSelected(1)),
          _NavItem(title: 'ÉDITEUR G-CODE', icon: Icons.code, selected: selectedIndex == 2, isExpanded: isExpanded, onTap: () => onItemSelected(2)),
          _NavItem(title: 'RETOUR ORIGINE', icon: Icons.location_on, selected: selectedIndex == 3, isExpanded: isExpanded, onTap: () => onItemSelected(3)),
          _NavItem(title: 'PARAMÈTRES AXES', icon: Icons.settings, selected: selectedIndex == 4, isExpanded: isExpanded, onTap: () => onItemSelected(4)),
          _NavItem(title: 'SÉCURITÉ MACHINE', icon: Icons.security, selected: selectedIndex == 5, isExpanded: isExpanded, onTap: () => onItemSelected(5)),
          const Spacer(),
          // User profile
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.surfaceBorder))),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                CircleAvatar(backgroundColor: AppColors.surfaceBorder, radius: 14, child: const Icon(Icons.person, color: AppColors.textSecondary, size: 16)),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OPÉRATEUR L01', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 10)),
                        Text('MODE EXPERT', style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavItem({
    required this.title, 
    required this.icon, 
    required this.selected, 
    required this.isExpanded,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: selected ? AppColors.primary : Colors.transparent, width: 2)),
        ),
        child: Row(
          mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            SizedBox(width: isExpanded ? 12 : 0),
            Icon(icon, color: selected ? AppColors.primary : AppColors.textDisabled, size: 20),
            if (isExpanded) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title, 
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary, 
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal, 
                    fontSize: 10, 
                    letterSpacing: 0.8
                  )
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusFooter extends StatelessWidget {
  final String currentTime;
  const _StatusFooter({required this.currentTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(currentTime, style: const TextStyle(color: AppColors.textDisabled, fontSize: 10, fontFamily: 'monospace')),
          const Row(
            children: [
              Icon(Icons.terminal, color: AppColors.success, size: 10),
              SizedBox(width: 8),
              Text('GRBL 1.1h [5-AXIS] - CORE OK', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          ),
          const Text('LATENCY: 12ms', style: TextStyle(color: AppColors.textDisabled, fontSize: 9)),
        ],
      ),
    );
  }
}
