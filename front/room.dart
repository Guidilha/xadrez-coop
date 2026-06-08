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
  
  Future<void> _escolherEquipeEEntrar(BuildContext context, String codigo, String modo, String username) async {
    String? equipeEscolhida = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha sua Equipe', textAlign: TextAlign.center),
        content: const Text('Em qual lado do tabuleiro você deseja jogar?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, 'w'), // Envia 'w' para o Go
            child: const Text('Brancas', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, 'b'), // Envia 'b' para o Go
            child: const Text('Pretas', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // Se ele escolheu uma equipe e não apenas fechou a janela, abre a sala!
    if (equipeEscolhida != null) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChessBoardScreen(
            roomCode: codigo,
            username: username,
            mode: modo,
            team: equipeEscolhida, // Repassa a escolha
          ),
        ),
      );
    }
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

  // Função para criar uma nova sala
  void _criarNovaSala() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String novoCodigo = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

    // 👉 AGORA ELE ABRE O POP-UP EM VEZ DE PULAR DIRETO PRA SALA
    _escolherEquipeEEntrar(context, novoCodigo, widget.mode, widget.username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161512),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262421),
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
                        subtitle: Text('Código: ${sala['id']}  •  Jogadores: ${sala['jogadores']}  •  ${sala['mode']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _escolherEquipeEEntrar(context, sala['id'], sala['mode'], widget.username),
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
