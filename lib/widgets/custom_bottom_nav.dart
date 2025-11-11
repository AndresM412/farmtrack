import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/animals_screen.dart';
import '../screens/alarms/alarms_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AnimalsScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AlarmsScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3))),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, 0, Icons.home, "Inicio"),
          _navItem(context, 1, Icons.pets, "Animales"),
          _navItem(context, 2, Icons.alarm, "Alarmas"),
          _navItem(context, 3, Icons.analytics, "Reportes"),
          _navItem(context, 4, Icons.settings, "Ajustes"),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, int index, IconData icon, String label) {
    final bool active = index == currentIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isHovering = false;

          return MouseRegion(
            onEnter: (_) => setState(() => isHovering = true),
            onExit: (_) => setState(() => isHovering = false),
            child: GestureDetector(
              onTap: () => _onItemTapped(context, index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF3FD411).withOpacity(0.15)
                      : isHovering
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: isHovering ? 1.15 : 1.0,
                      child: Icon(
                        icon,
                        color:
                        active ? const Color(0xFF3FD411) : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF3FD411)
                            : isHovering
                            ? Colors.black
                            : Colors.grey[700],
                        fontSize: 12,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
