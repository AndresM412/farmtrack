import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3FD411),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final nombreFinca = data['finca'] ?? 'Sin nombre';
            final animalesTotales = data['animalesTotales'] ?? 0;
            final animalesGestacion = data['animalesGestacion'] ?? 0;
            final animalesLactancia = data['animalesLactancia'] ?? 0;
            final proximosPartos = data['proximosPartos'] ?? 0;

            return Column(
              children: [
                // ─────────────────────────────── Encabezado
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nombre de la finca
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Finca",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              nombreFinca,
                              key: ValueKey(nombreFinca),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Botón de notificaciones
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3FD411).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Color(0xFF3FD411),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─────────────────────────────── Resumen de la finca
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Resumen de la Finca",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.2,
                          children: [
                            _statCard(
                              title: "Total de Animales",
                              value: animalesTotales,
                              icon: Icons.pets,
                              color: const Color(0xFF3FD411),
                            ),
                            _statCard(
                              title: "Gestación",
                              value: animalesGestacion,
                              icon: Icons.favorite,
                              color: Colors.pink,
                            ),
                            _statCard(
                              title: "Lactancia",
                              value: animalesLactancia,
                              icon: Icons.local_drink,
                              color: Colors.blue,
                            ),
                            _statCard(
                              title: "Próximos Partos",
                              value: proximosPartos,
                              icon: Icons.calendar_month,
                              color: Colors.orange,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Alertas Recientes",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // A futuro: reemplazar con alertas reales
                        _alertCard("Confirmar gestación", "Vaca #123"),
                        _alertCard("Inseminación pendiente", "Cerda #456"),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // ─────────────────────────────── Bottom Navigation
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, "Inicio", true),
            _navItem(Icons.pets, "Animales", false),
            _navItem(Icons.alarm, "Alarmas", false),
            _navItem(Icons.analytics, "Reportes", false),
            _navItem(Icons.settings, "Ajustes", false),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Widgets auxiliares
  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 36, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  )),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _alertCard(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF3FD411).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications, color: Color(0xFF3FD411)),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(detail),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? const Color(0xFF3FD411) : Colors.grey),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? const Color(0xFF3FD411) : Colors.grey,
          ),
        ),
      ],
    );
  }
}
