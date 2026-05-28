import 'package:flutter/material.dart';
import 'gamescreen.dart';

class LobbyScreen extends StatefulWidget {
  final String modoDeJogo;
  // O código continua aqui para o sistema funcionar, mas o usuário não vai ver!
  final String roomID; 

  const LobbyScreen({
    super.key, 
    required this.modoDeJogo, 
    required this.roomID, 
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
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
              // Substituímos o código gigante por um ícone de radar/procura
              const Icon(Icons.radar, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Sua sala está pública!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aguardando...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                title: Text(_oponenteConectado ? 'Adversário Encontrado!' : 'Buscando oponente...'),
                subtitle: Text(_oponenteConectado ? 'Pronto para iniciar' : 'Aguardando conexão'),
                trailing: _oponenteConectado 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              
              const SizedBox(height: 40),
              
              // Botão de Iniciar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                onPressed: _oponenteConectado ? () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          // Repassamos o ID oculto para o tabuleiro funcionar
                          builder: (context) => ChessBoardScreen(roomCode: widget.roomID), 
                        ), 
                      );
                    } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Iniciar Partida', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
