import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChessBoardScreen extends StatefulWidget {
  final String roomCode;
  final String username; 
  final String mode; // 👉 NOVO: Agora exige saber o modo!
  
  const ChessBoardScreen({super.key, required this.roomCode, required this.username, required this.mode});

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late WebSocketChannel _channel;
  
  String currentFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"; 
  String? casaSelecionada;
  List<String> movimentosValidos = [];
  bool isDialogOpen = false; 
  bool euPediRevanche = false; 
  int rematchVotes = 0;
  
  // 👉 NOVAS VARIÁVEIS DE ESTADO MULTIPLAYER
  int playerCount = 0; 
  int maxPlayers = 2;
  Map<String, dynamic> jogadoresConectados = {}; // Dicionário: { "w1": "Davi", "b2": "João" }
  String activeRole = "w1"; // Quem deve jogar agora
  String? myRole; // Minha cadeira (ex: "b1")

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://xadrez-a8qm.onrender.com/ws/play?room=${widget.roomCode}&user=${widget.username}&mode=${widget.mode}')
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
        playerCount = data['player_count']; 
        maxPlayers = data['max_players'] ?? 2;
        movimentosValidos = List<String>.from(data['valid_moves'] ?? []);
        rematchVotes = data['rematch_votes'] ?? 0;
        
        jogadoresConectados = data['players'] ?? {};
        activeRole = data['active_role'] ?? 'w1';
        casaSelecionada = null; 

        // Descobre em qual cadeira eu estou sentado
        if (myRole == null && jogadoresConectados.containsValue(widget.username)) {
          jogadoresConectados.forEach((cargo, nome) {
            if (nome == widget.username) myRole = cargo;
          });
        }
      });

      String status = data['status'] ?? '*';
      if (status != '*') {
        if (!isDialogOpen) _mostrarFimDeJogo(status); 
        else {
          Navigator.of(context).pop(); 
          isDialogOpen = false;
          _mostrarFimDeJogo(status); 
        }
      } else {
        if (isDialogOpen) {
          Navigator.pop(context);
          isDialogOpen = false;
        }
        euPediRevanche = false; 
      }
    });
  }

  void _mostrarFimDeJogo(String resultado) {
    if (isDialogOpen) return; 
    isDialogOpen = true;

    String mensagem = "O jogo terminou em empate!";
    if (resultado == "1-0") mensagem = "Xeque-Mate!\nEquipe das Brancas Venceu!";
    else if (resultado == "0-1") mensagem = "Xeque-Mate!\nEquipe das Pretas Venceu!";

    Widget rematchWidget = euPediRevanche 
        ? const Text("Aguardando votos...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        : ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              _channel.sink.add(jsonEncode({"move": "rematch"}));
              setState(() => euPediRevanche = true);
            },
            child: Text("Pedir Revanche ($rematchVotes/$playerCount)"),
          );

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        title: Text(
          rematchVotes > 0 && !euPediRevanche ? "Adversário pediu revanche!" : "Fim de Jogo!", 
          style: TextStyle(fontWeight: FontWeight.bold, color: rematchVotes > 0 ? Colors.green : Colors.black)
        ),
        content: Text(mensagem, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
        actions: [
          rematchWidget,
          TextButton(
            onPressed: () {
              Navigator.pop(context); Navigator.pop(context); 
              isDialogOpen = false;
            },
            child: const Text("Sair da Sala", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  // 👉 FÁBRICA DE CARDS DINÂMICOS (Cuida do brilho/fade e cor da caixa)
  Widget _buildPlayerBadge(String roleID) {
    String name = jogadoresConectados[roleID] ?? "Aguardando...";
    bool isMyTurn = (activeRole == roleID); // Brilha apenas se for a vez EXATA dele
    bool isMe = (myRole == roleID);
    bool isWhiteTeam = roleID.startsWith('w');

    return AnimatedOpacity(
      opacity: isMyTurn ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isWhiteTeam ? Colors.grey[300] : Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
        child: Text(
          "$name ${isMe ? '(Você)' : ''}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isWhiteTeam ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }

  List<String> gerarListaDoTabuleiro() {
    List<String> board = [];
    String linhasFen = currentFen.split(' ')[0];
    for (int i = 0; i < linhasFen.length; i++) {
      String caractere = linhasFen[i];
      if (caractere == '/') continue;
      if (int.tryParse(caractere) != null) board.addAll(List.filled(int.parse(caractere), ''));
      else board.add(caractere);
    }
    return board;
  }

  Widget _obterWidgetPeca(String fenChar) {
    if (fenChar.isEmpty) return const SizedBox();
    String url = '';
    switch (fenChar) {
      case 'r': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/ff/Chess_rdt45.svg/120px-Chess_rdt45.svg.png'; break;
      case 'n': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Chess_ndt45.svg/120px-Chess_ndt45.svg.png'; break;
      case 'b': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/Chess_bdt45.svg/120px-Chess_bdt45.svg.png'; break;
      case 'q': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Chess_qdt45.svg/120px-Chess_qdt45.svg.png'; break;
      case 'k': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Chess_kdt45.svg/120px-Chess_kdt45.svg.png'; break;
      case 'p': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Chess_pdt45.svg/120px-Chess_pdt45.svg.png'; break;
      case 'R': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Chess_rlt45.svg/120px-Chess_rlt45.svg.png'; break;
      case 'N': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Chess_nlt45.svg/120px-Chess_nlt45.svg.png'; break;
      case 'B': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Chess_blt45.svg/120px-Chess_blt45.svg.png'; break;
      case 'Q': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Chess_qlt45.svg/120px-Chess_qlt45.svg.png'; break;
      case 'K': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Chess_klt45.svg/120px-Chess_klt45.svg.png'; break;
      case 'P': url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Chess_plt45.svg/120px-Chess_plt45.svg.png'; break;
    }
    if (url.isEmpty) return const SizedBox();
    return Padding(padding: const EdgeInsets.all(4.0), child: Image.network(url, fit: BoxFit.contain));
  }

  Future<String?> _mostrarDialogoPromocao() async {
    bool isWhiteTeam = myRole != null && myRole!.startsWith('w');
    String q = isWhiteTeam ? 'Q' : 'q';
    String r = isWhiteTeam ? 'R' : 'r';
    String b = isWhiteTeam ? 'B' : 'b';
    String n = isWhiteTeam ? 'N' : 'n';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Promover Peão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: SizedBox(width: 40, height: 40, child: _obterWidgetPeca(q)), title: const Text('Rainha'), onTap: () => Navigator.pop(context, 'q')),
            ListTile(leading: SizedBox(width: 40, height: 40, child: _obterWidgetPeca(r)), title: const Text('Torre'), onTap: () => Navigator.pop(context, 'r')),
            ListTile(leading: SizedBox(width: 40, height: 40, child: _obterWidgetPeca(b)), title: const Text('Bispo'), onTap: () => Navigator.pop(context, 'b')),
            ListTile(leading: SizedBox(width: 40, height: 40, child: _obterWidgetPeca(n)), title: const Text('Cavalo'), onTap: () => Navigator.pop(context, 'n')),
          ],
        ),
      ),
    );
  }

  void _aoClicarNaCasa(String nomeDaCasa) async {
    // 👉 TRAVA: Só envia movimento se for o SEU turno exato (ex: w2)
    if (myRole != activeRole) return;

    setState(() {
      if (casaSelecionada == null) {
        bool temMovimento = movimentosValidos.any((m) => m.startsWith(nomeDaCasa));
        if (temMovimento) casaSelecionada = nomeDaCasa; 
      } else {
        String jogadaBase = "$casaSelecionada$nomeDaCasa";
        bool ehValida = movimentosValidos.any((m) => m.startsWith(jogadaBase));
        
        if (ehValida) {
          // Lógica de pegar a letra da peça
          int col = casaSelecionada!.codeUnitAt(0) - 97;
          int row = 8 - int.parse(casaSelecionada![1]);
          String peca = gerarListaDoTabuleiro()[row * 8 + col];
          
          if ((peca == 'P' && nomeDaCasa.endsWith('8')) || (peca == 'p' && nomeDaCasa.endsWith('1'))) {
            _mostrarDialogoPromocao().then((escolha) {
              if (escolha != null) _channel.sink.add(jsonEncode({"move": "$jogadaBase$escolha"}));
              setState(() => casaSelecionada = null);
            });
            return; 
          } else {
            _channel.sink.add(jsonEncode({"move": jogadaBase}));
          }
        }
        casaSelecionada = null; 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> casasVisuais = gerarListaDoTabuleiro();

    if (playerCount < maxPlayers) {
      return Scaffold(
        appBar: AppBar(title: Text('Aguardando Jogadores ($playerCount/$maxPlayers)')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    bool souEquipePretas = myRole != null && myRole!.startsWith('b');
    
    // 👉 MONTA AS FILEIRAS DEPENDENDO DO MODO E DA SUA COR
    List<Widget> topRow = [];
    List<Widget> bottomRow = [];

    if (widget.mode == "2v2") {
      topRow = souEquipePretas ? [_buildPlayerBadge('w1'), _buildPlayerBadge('w2')] : [_buildPlayerBadge('b1'), _buildPlayerBadge('b2')];
      bottomRow = souEquipePretas ? [_buildPlayerBadge('b1'), _buildPlayerBadge('b2')] : [_buildPlayerBadge('w1'), _buildPlayerBadge('w2')];
    } else {
      topRow = souEquipePretas ? [_buildPlayerBadge('w1')] : [_buildPlayerBadge('b1')];
      bottomRow = souEquipePretas ? [_buildPlayerBadge('b1')] : [_buildPlayerBadge('w1')];
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.mode == "2v2" ? "Modo Duplas - Sala: ${widget.roomCode}" : "1v1 - Sala: ${widget.roomCode}")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BARRA DO TOPO (Adversários)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: topRow),

            const SizedBox(height: 20),

            SizedBox(
              width: 400,
              height: 400,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 64,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                itemBuilder: (context, index) {
                  int boardIndex = souEquipePretas ? 63 - index : index;
                  int linha = boardIndex ~/ 8;
                  int coluna = boardIndex % 8;
                  
                  String pecaFen = casasVisuais[boardIndex];
                  String nomeDaCasa = '${String.fromCharCode(97 + coluna)}${8 - linha}'; 
                  
                  bool estaSelecionada = casaSelecionada == nomeDaCasa;
                  bool ehDestinoValido = false;
                  if (casaSelecionada != null) {
                    ehDestinoValido = movimentosValidos.any((m) => m.startsWith(casaSelecionada!) && m.substring(2, 4) == nomeDaCasa);
                  }

                  Color corDaCasa = estaSelecionada ? Colors.yellow.withOpacity(0.7) 
                      : ehDestinoValido ? Colors.green.withOpacity(0.6) 
                      : (linha + coluna) % 2 == 0 ? Colors.brown[200]! : Colors.brown[600]!;

                  return GestureDetector(
                    onTap: () => _aoClicarNaCasa(nomeDaCasa),
                    child: Container(
                      decoration: BoxDecoration(color: corDaCasa),
                      child: Center(child: _obterWidgetPeca(pecaFen)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // BARRA DE BAIXO (Você e seu Parceiro)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: bottomRow),

          ],
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
