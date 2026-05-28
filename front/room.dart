import 'package:flutter/material.dart';
import 'dart:math'; // Para gerar o código aleatório
import 'gamescreen.dart'; // Importe a tela do jogo

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  // TODO: No futuro, você vai preencher essa lista fazendo uma requisição HTTP (GET) para o seu servidor Go!
  // Por enquanto, usamos dados simulados para desenhar a tela.
  List<Map<String, dynamic>> _salasDisponiveis = [];
  bool _isLoading = true;
  // Função para entrar em uma sala existente
  void _entrarNaSala(String codigoSala) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChessBoardScreen(roomCode: codigoSala),
      ),
    );
  }

  // Função para criar uma nova sala
  void _criarNovaSala() {
    // Gera um código aleatório de 4 letras/números
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String novoCodigo = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

    // Entra direto na nova sala (o Go vai criar a sala quando bater no WebSocket)
    _entrarNaSala(novoCodigo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby de Salas'),
        centerTitle: true,
      ),
      body: _salasDisponiveis.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma sala disponível no momento.\nCrie a sua!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _salasDisponiveis.length,
              itemBuilder: (context, index) {
                final sala = _salasDisponiveis[index];
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.videogame_asset, color: Colors.blue, size: 36),
                    title: Text(
                      sala['nome'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Código: ${sala['id']}  •  Jogadores: ${sala['jogadores']}/2'),
                    trailing: ElevatedButton(
                      onPressed: () => _entrarNaSala(sala['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Entrar'),
                    ),
                  ),
                );
              },
            ),
      // Botão flutuante para criar a própria sala
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarNovaSala,
        icon: const Icon(Icons.add),
        label: const Text('Criar Sala'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}
