import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_animal_screen.dart';

class AnimalDetailScreen extends StatelessWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          "Detalle del Animal",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF6F8F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('animales')
            .doc(animalId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Animal no encontrado',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final animal = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoCard(animal),
                const SizedBox(height: 20),

                _buildReproductiveHistoryCard(animal),
                const SizedBox(height: 20),

                // PASA LA VARIABLE animal COMO PARÁMETRO
                _buildActionButtons(context, animalId, animal),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> animal) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF3FD411).withOpacity(0.1),
                    image: animal['imagenUrl'] != null
                        ? DecorationImage(
                      image: NetworkImage(animal['imagenUrl']!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: animal['imagenUrl'] == null
                      ? const Icon(Icons.pets, size: 40, color: Color(0xFF3FD411))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${animal['tipo']} • ${animal['raza'] ?? 'Sin raza'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(animal),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(animal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Informacion Basica',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoRow('Identificador', animal['nombre'] ?? 'No especificado'),
            _buildInfoRow('Especie', animal['tipo'] ?? 'No especificada'),
            _buildInfoRow('Raza', animal['raza'] ?? 'No especificada'),
            _buildInfoRow('Fecha de Nacimiento', _formatTimestamp(animal['fechaNacimiento'])),


            if (animal['fechaRegistro'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Fecha de Registro',
                _formatTimestamp(animal['fechaRegistro']),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReproductiveHistoryCard(Map<String, dynamic> animal) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial Reproductivo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            _buildReproductiveEvent(
              'Inseminacion',
              Icons.biotech_outlined,
              animal['inseminacion'],
            ),
            const SizedBox(height: 12),

            _buildReproductiveEvent(
              'Parto',
              Icons.pregnant_woman_outlined,
              animal['parto'],
            ),
            const SizedBox(height: 12),

            _buildReproductiveEvent(
              'Lactancia',
              Icons.local_drink_outlined,
              animal['lactancia'],
            ),
          ],
        ),
      ),
    );
  }

  // FUNCIÓN CORREGIDA - AHORA RECIBE EL PARÁMETRO animal
  Widget _buildActionButtons(BuildContext context, String animalId, Map<String, dynamic> animal) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3FD411),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAnimalScreen(
                    animalId: animalId,
                    animalData: animal,
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Editar', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () {
              _showDeleteConfirmation(context, animalId);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, size: 20),
                SizedBox(width: 8),
                Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildReproductiveEvent(String title, IconData icon, dynamic date) {
  String formattedDate = _formatTimestamp(date);

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF3FD411).withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF3FD411).withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3FD411).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF3FD411), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate != 'Fecha no disponible' ? formattedDate : 'No programado',
                style: TextStyle(
                  color: formattedDate != 'Fecha no disponible'
                      ? const Color(0xFF3FD411)
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Color _getStatusColor(Map<String, dynamic> animal) {
    if (animal['lactancia'] != null) {
      return Colors.blue;
    } else if (animal['parto'] != null) {
      return Colors.purple;
    } else if (animal['inseminacion'] != null) {
      return Colors.orange;
    } else {
      return const Color(0xFF3FD411);
    }
  }

  String _getStatusText(Map<String, dynamic> animal) {
    if (animal['lactancia'] != null) {
      return 'EN LACTANCIA';
    } else if (animal['parto'] != null) {
      return 'EN PARTO';
    } else if (animal['inseminacion'] != null) {
      return 'INSEMINADA';
    } else {
      return 'NORMAL';
    }
  }

String _formatTimestamp(dynamic timestamp) {
  try {
    if (timestamp == null) return 'No programado';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    if (timestamp is DateTime) {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    }
    if (timestamp is String) {
      return timestamp;
    }
    return 'Fecha no disponible';
  } catch (e) {
    return 'Fecha no disponible';
  }
}


  void _showDeleteConfirmation(BuildContext context, String animalId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminacion'),
          content: const Text('Estas seguro de que quieres eliminar este animal? Esta accion no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _deleteAnimal(context, animalId);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAnimal(BuildContext context, String animalId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('animales')
          .doc(animalId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar animal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}