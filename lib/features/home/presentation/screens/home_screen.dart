import 'package:flutter/material.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getHomeImage(),
      builder: (context, snapshot) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // IMAGEN o ÍCONO
              if (snapshot.hasData && snapshot.data != null)
                Container(
                  width: 300,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(snapshot.data!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else if (snapshot.connectionState == ConnectionState.waiting)
                const CircularProgressIndicator()
              else
                const Icon(
                  Icons.visibility,
                  size: 100,
                  color: Colors.blue,
                ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Bienvenido a Eyes Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 10),
              
              const Text(
                'Tu visión, nuestra prioridad',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _getHomeImage() async {
    // Aquí llamarías a tu ApiService
    // Por ahora, devuelve la URL hardcodeada
    return 'https://res.cloudinary.com/drhhthuqq/image/upload/v1765769365/ojo_vc7bdu.jpg';
  }
}