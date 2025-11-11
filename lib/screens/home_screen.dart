import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav.dart';

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
              .collection("users")
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF3FD411)),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            final totalAnimales = data['animalesTotales'] ?? 0;
            final gestacion = data['animalesGestacion'] ?? 0;
            final lactancia = data['animalesLactancia'] ?? 0;
            final proximosPartos = data['proximosPartos'] ?? 0;
            final nombreFinca = data['nombreFinca'] ?? "Finca";

            // imágenes
              final img1 = "https://plus.unsplash.com/premium_photo-1663045932351-267ae867e880?fm=jpg&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8YW5pbWFsJTIwZmFybXxlbnwwfHwwfHx8MA%3D%3D&ixlib=rb-4.1.0&q=60&w=3000";
              final img2 = "https://www.morningagclips.com/wp-content/uploads/2020/07/monika-kubala-OpMfiq8nPI0-unsplash-720x400.jpg";
              final img3 = "https://plus.unsplash.com/premium_photo-1677575242377-5e04cd0b5614?fm=jpg&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8Y293JTIwYW5kJTIwY2FsZnxlbnwwfHwwfHx8MA%3D%3D&ixlib=rb-4.1.0&q=60&w=3000";
              final img4 = "https://images.unsplash.com/photo-1665936091620-bc6c8bec50e3?fm=jpg&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGJhYnklMjBjb3dzfGVufDB8fDB8fHww&ixlib=rb-4.1.0&q=60&w=3000";
// próximos partos

            return Column(
              children: [
                // Título pantalla
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      nombreFinca,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Resumen de la Finca",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        _cardInfo("Total de Animales", totalAnimales, img1),
                        _cardInfo("Animales en Gestación", gestacion, img2),
                        _cardInfo("Animales en Lactancia", lactancia, img3),
                        _cardInfo("Próximos Partos", proximosPartos, img4),

                        const SizedBox(height: 24),

                        const Text(
                          "Alertas Recientes",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        _alertItem("Confirmar gestación", "Vaca #123"),
                        _alertItem("Inseminación pendiente", "Cerda #456"),
                      ],
                    ),
                  ),
                ),

                // ✅ barra inferior global
                const CustomBottomNav(currentIndex: 0),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cardInfo(String title, int value, String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF3FD411),
                ),
              ),
            ],
          ),
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(imageUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3FD411).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications, color: Color(0xFF3FD411)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
