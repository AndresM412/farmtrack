import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav.dart';
import 'add_animal_screen.dart';
import 'animal_detail_screen.dart'; // IMPORTAR LA NUEVA PANTALLA

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F6),
        elevation: 0,
        title: const Text(
          "Animales",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade200,
                hintText: "Buscar por nombre...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('animales')
                  .orderBy('fechaRegistro', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = docs.where((d) {
                  final nombre = d['nombre'].toString().toLowerCase();
                  return nombre.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay animales registrados",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final animalId = doc.id; // OBTENER EL ID DEL DOCUMENTO

                    final nombre = data['nombre'] ?? 'Sin nombre';
                    final tipo = data['tipo'] ?? 'Desconocido';
                    final raza = data['raza'] ?? '';
                    final imagenUrl = data['imagenUrl'];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imagenUrl != null
                                ? Image.network(
                              imagenUrl,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              color: const Color(0xFF3FD411).withOpacity(0.1),
                              child: const Icon(Icons.pets, color: Color(0xFF3FD411)),
                            ),
                          ),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$tipo ${raza.isNotEmpty ? '• $raza' : ''}'),
                            if (data['fechaNacimiento'] != null)
                              Text(
                                'Nacimiento: ${data['fechaNacimiento']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStatusText(data),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          // NAVEGAR A LA PANTALLA DE DETALLE
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnimalDetailScreen(animalId: animalId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Tooltip(
          message: 'Agregar animal',
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF3FD411),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAnimalScreen(),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),

      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  // FUNCIÓN PARA OBTENER COLOR DEL ESTADO
  Color _getStatusColor(Map<String, dynamic> animal) {
    if (animal['lactancia'] != null) {
      return Colors.blue; // En lactancia
    } else if (animal['parto'] != null) {
      return Colors.purple; // En parto
    } else if (animal['inseminacion'] != null) {
      return Colors.orange; // Inseminada
    } else {
      return const Color(0xFF3FD411); // Normal
    }
  }

  // FUNCIÓN PARA OBTENER TEXTO DEL ESTADO
  String _getStatusText(Map<String, dynamic> animal) {
    if (animal['lactancia'] != null) {
      return 'LACTANCIA';
    } else if (animal['parto'] != null) {
      return 'PARTO';
    } else if (animal['inseminacion'] != null) {
      return 'INSEMINADA';
    } else {
      return 'NORMAL';
    }
  }
}