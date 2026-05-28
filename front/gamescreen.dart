import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChessBoardScreen extends StatefulWidget {
  final String roomCode; // Agora a tela exige um código de sala
  
  const ChessBoardScreen({super.key, required this.roomCode});

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late WebSocketChannel _channel;
  
  String currentFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"; 
  String turnoAtual = "White";
  String? casaSelecionada;
  int playerCount = 0; // Controla se o jogo começou

  @override
  void initState() {
    super.initState();
    // Conecta enviando o código da sala na URL
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/ws/play?room=${widget.roomCode}')
    );
    
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['error'] != null) {
        // Se a sala estiver cheia, expulsa o usuário
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sala cheia!')));
        return;
      }
      
      setState(() {
        currentFen = data['fen'];
        turnoAtual = data['turn'];
        playerCount = data['player_count']; // Atualiza a quantidade de jogadores
        casaSelecionada = null; 
      });
    });
  }

  // ... (Mantenha as funções gerarListaDoTabuleiro e _aoClicarNaCasa exatamente iguais)
  List<String> gerarListaDoTabuleiro() {
    List<String> board = [];
    String linhasFen = currentFen.split(' ')[0];
    for (int i = 0; i < linhasFen.length; i++) {
      String caractere = linhasFen[i];
      if (caractere == '/') continue;
      if (int.tryParse(caractere) != null) {
        board.addAll(List.filled(int.parse(caractere), ''));
      } else {
        board.add(caractere);
      }
    }
    return board;
  }

  void _aoClicarNaCasa(String nomeDaCasa) {
    setState(() {
      if (casaSelecionada == null) {
        casaSelecionada = nomeDaCasa; 
      } else {
        String jogadaParaOBackend = "$casaSelecionada$nomeDaCasa";
        _channel.sink.add(jsonEncode({"move": jogadaParaOBackend}));
        casaSelecionada = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // SE NÃO TEM 2 JOGADORES, MOSTRA A TELA DE ESPERA
    if (playerCount < 2) {
      List<String> casasVisuais = gerarListaDoTabuleiro();
      return Scaffold(
        appBar: AppBar(title: const Text('Lobby de Espera')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Passe este código para o seu adversário:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                widget.roomCode,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 5, color: Colors.blue),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Aguardando oponente se conectar...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    
    
    return Scaffold(
      appBar: AppBar(title: Text("Turno: $turnoAtual | Sala: ${widget.roomCode}")),
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 64,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
            itemBuilder: (context, index) {
              int linha = index ~/ 8;
              int coluna = index % 8;
              bool casaClara = (linha + coluna) % 2 == 0;
              
              String peca = casasVisuais[index];
              String nomeDaCasa = '${String.fromCharCode(97 + coluna)}${8 - linha}'; 
              bool estaSelecionada = casaSelecionada == nomeDaCasa;

              return GestureDetector(
                onTap: () => _aoClicarNaCasa(nomeDaCasa),
                child: Container(
                  decoration: BoxDecoration(
                    color: estaSelecionada 
                        ? Colors.yellow.withOpacity(0.6) 
                        : (casaClara ? Colors.white : Colors.brown[400]),
                  ),
                  child: Center(
                    child: Text(
                      peca, 
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
