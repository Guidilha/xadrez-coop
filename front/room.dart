import 'package:flutter/material.dart';
import 'gamescreen.dart'; // Importe a tela do jogo

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _entrarNaSala() {
    final codigo = _codeController.text.trim().toUpperCase(); // Força maiúsculo
    if (codigo.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        // Passa o código que o usuário digitou
        MaterialPageRoute(builder: (context) => ChessBoardScreen(roomCode: codigo)), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar em uma Sala')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Digite o código da sala do seu amigo:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 2),
              decoration: const InputDecoration(
                hintText: 'EX: AB49',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _entrarNaSala,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text('Conectar e Jogar', style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
