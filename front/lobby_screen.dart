import 'package:flutter/material.dart';
import 'gamescreen.dart';

class LobbyScreen extends StatefulWidget {
  final String modoDeJogo;
  const LobbyScreen({super.key, required this.modoDeJogo});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  // Simulando o estado da sala
  final String codigoDaSala = "X7B9"; // O Go vai gerar isso no futuro
  bool _oponenteConectado = false; // Muda para true quando o socket avisar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lobby - ${widget.modoDeJogo}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Código da sua sala:', style: TextStyle(fontSize: 16)),
              Text(
                codigoDaSala,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 5, color: Colors.blue),
              ),
              const SizedBox(height: 40),
              
              // Jogador 1 (Host)
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white)),
                title: const Text('Você (Host)'),
                subtitle: const Text('Pronto'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
                tileColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),
              
              // Jogador 2 (Convidado)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _oponenteConectado ? Colors.red : Colors.grey, 
                  child: const Icon(Icons.person_outline, color: Colors.white)
                ),
                title: Text(_oponenteConectado ? 'Adversário Conectado!' : 'Aguardando oponente...'),
                subtitle: Text(_oponenteConectado ? 'Pronto para iniciar' : 'Compartilhe o código acima'),
                trailing: _oponenteConectado 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              
              const SizedBox(height: 40),
              
              // Botão de Iniciar (Só funciona se o oponente entrar)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                onPressed: _oponenteConectado ? () {
                    Navigator.pushReplacement(
                        context,
                        // Remova o "const" antes de ChessBoardScreen e passe a variável
                        MaterialPageRoute(builder: (context) => ChessBoardScreen(roomCode: codigoDaSala)), 
                      );
                    } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Iniciar Partida', style: TextStyle(fontSize: 18)),
                ),
              ),
              
              // Botão temporário só para você testar a mudança de estado na UI
              TextButton(
                onPressed: () => setState(() => _oponenteConectado = true),
                child: const Text('(Dev) Simular entrada de oponente'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
