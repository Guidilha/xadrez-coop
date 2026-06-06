import 'package:flutter/material.dart';
import 'dart:math'; // Para gerar o código aleatório
import 'package:http/http.dart' as http; // IMPORTANTE: Para requisições na web
import 'dart:convert'; // IMPORTANTE: Para ler o JSON do servidor
import 'gamescreen.dart'; // Importe a tela do jogo

class JoinRoomScreen extends StatefulWidget {
  final String username;
  final String mode;
  const JoinRoomScreen({super.key, required this.username, required this.mode});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  List<Map<String, dynamic>> _salasDisponiveis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buscarSalas(); // Dispara a busca assim que o jogador abre a tela
  }

  // Função que conecta no seu backend Go (Render)
Future<void> _buscarSalas() async {
    try {
      final response = await http.get(Uri.parse('https://xadrez-a8qm.onrender.com/api/rooms'));

      if (response.statusCode == 200) {
        List<dynamic> dadosJson = jsonDecode(response.body);
        
        setState(() {
          _salasDisponiveis = dadosJson.map((sala) => {
            'id': sala['id'].toString(),
            'nome': sala['nome'].toString(),
            'jogadores': "${sala['jogadores']}/${sala['max']}", // Mostra 1/2 ou 2/4
            'mode': sala['mode'].toString(), // Lê o modo do servidor
          }).toList();
          _isLoading = false; // Tira a bolinha de carregamento
        });
      }
    } catch (e) {
      print("Erro ao buscar salas: $e");
      setState(() {
        _isLoading = false; // Para de carregar mesmo se der erro
      });
    }
  }

  // 👉 ATUALIZADO: Agora a função exige receber o modo da sala!
  void _entrarNaSala(String codigoSala, String modoDaSala) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChessBoardScreen(
          roomCode: codigoSala,
          username: widget.username, 
          mode: modoDaSala, // 👉 REPASSAMOS O MODO PARA O TABULEIRO AQUI
        ),
      ),
    );
  }

  // Função para criar uma nova sala
  void _criarNovaSala() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String novoCodigo = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

    // Entra direto na nova sala (o Go vai criar a sala quando bater no WebSocket)
    _entrarNaSala(novoCodigo, widget.mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby de Salas'),
        centerTitle: true,
        actions: [
          // Botão no topo para o usuário recarregar a lista manualmente
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _buscarSalas();
            },
          )
        ],
      ),
      // Lógica da tela: Carregando -> Vazio -> Lista Preenchida
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _salasDisponiveis.isEmpty
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
                        // 👉 ATUALIZADO: Mostra as vagas dinâmicas e o modo!
                        subtitle: Text('Código: ${sala['id']}  •  Jogadores: ${sala['jogadores']}  •  ${sala['mode']}'),
                        trailing: ElevatedButton(
                          // 👉 ATUALIZADO: Envia o ID e o Modo para a função!
                          onPressed: () => _entrarNaSala(sala['id'], sala['mode']),
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
