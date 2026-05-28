import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChessBoardScreen extends StatefulWidget {
  final String roomCode;
  
  const ChessBoardScreen({super.key, required this.roomCode});

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late WebSocketChannel _channel;
  
  String currentFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"; 
  String turnoAtual = "White";
  String? casaSelecionada;
  int playerCount = 0; 

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://xadrez-a8qm.onrender.com/ws/play?room=${widget.roomCode}')
    ); 
    
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['error'] != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sala cheia!')));
        return;
      }
      
      setState(() {
        currentFen = data['fen'];
        turnoAtual = data['turn'];
        playerCount = data['player_count']; 
        casaSelecionada = null; 
      });
    });
  }

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
    // CORREÇÃO 1: Variável movida para o topo para que o GridView consiga enxergá-la
    List<String> casasVisuais = gerarListaDoTabuleiro();

    // SE NÃO TEM 2 JOGADORES, MOSTRA A TELA DE ESPERA
    if (playerCount < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aguardando Oponente')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // CORREÇÃO 2: Textos e ícones atualizados para o novo sistema
              Icon(Icons.satellite_alt, size: 80, color: Colors.blue),
              SizedBox(height: 24),
              Text('Sua sala está aberta!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Aguardando alguém entrar pela lista de salas...', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 40),
              CircularProgressIndicator(),
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
