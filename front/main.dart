import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'gamescreen.dart';
//import 'lobby_screen.dart';
import 'room.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xadrez Multiplayer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/dashboard': (context) => const MainMenuScreen(),
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _message = '';
  bool _isSuccessMessage = false;
  bool _isLoading = false;

  final String apiUrl = 'https://xadrez-a8qm.onrender.com/api';

  Future<void> _enviarRequisicao(String tipo) async {
    final String username = _userController.text.trim();
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _mostrarMensagem('Preencha todos os campos.', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/$tipo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      Map<String, dynamic> dados;
      try {
        dados = jsonDecode(response.body);
      } catch (e) {
        dados = {'message': 'Erro ao processar resposta do servidor.'};
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        _mostrarMensagem(dados['message'] ?? 'Erro na requisição.', false);
        return;
      }

      if (tipo == 'login') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        _mostrarMensagem('Cadastro realizado! Agora clique em Entrar.', true);
      }
    } catch (e) {
      _mostrarMensagem('Não foi possível conectar ao servidor.', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarMensagem(String msg, bool isSuccess) {
    setState(() {
      _message = msg;
      _isSuccessMessage = isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Acessar Sistema',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _enviarRequisicao('login'),
                      child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _enviarRequisicao('register'),
                      child: const Text('Cadastrar Novo', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isSuccessMessage ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum GameMode { umContraUm, doisContraDois, tresContraTres, contraIA }

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentTab = 0;
  GameMode _selectedMode = GameMode.umContraUm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Xadrez Multiplayer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _currentTab == 0 ? _buildPlayTab() : _buildHistoryTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Jogar'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }

  Widget _buildPlayTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecione o Modo de Jogo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildModeSelector(),
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_box),
                  label: const Text('Criar Nova Sala', style: TextStyle(fontSize: 16)),
                  onPressed: () => _handleAction('criar'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar em uma Sala', style: TextStyle(fontSize: 16)),
                  onPressed: () => _handleAction('entrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Center(
      // Envolvendo com SingleChildScrollView para evitar quebra de layout em telas menores
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<GameMode>(
          segments: const [
            ButtonSegment(value: GameMode.umContraUm, label: Text('1v1')),
            ButtonSegment(value: GameMode.doisContraDois, label: Text('2v2')),
            ButtonSegment(value: GameMode.tresContraTres, label: Text('3v3')),
            ButtonSegment(value: GameMode.contraIA, label: Text('VS IA')),
          ],
          selected: {_selectedMode},
          onSelectionChanged: (Set<GameMode> selection) {
            setState(() => _selectedMode = selection.first);
          },
          style: ButtonStyle(
            // Atualizado para WidgetStateProperty, que é o padrão atual do Flutter
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final List<Map<String, dynamic>> historico = [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historico.length,
      itemBuilder: (context, index) {
        final partida = historico[index];
        final bool? isWin = partida['win'];
        
        Color iconColor = Colors.grey;
        IconData iconData = Icons.remove_circle_outline;
        
        if (isWin == true) {
          iconColor = Colors.green;
          iconData = Icons.emoji_events;
        } else if (isWin == false) {
          iconColor = Colors.red;
          iconData = Icons.cancel;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(iconData, color: iconColor),
            ),
            title: Text('Modo: ${partida['modo']} - ${partida['resultado']}'),
            subtitle: Text(partida['data']),
            trailing: Text(
              partida['elo'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isWin == true ? Colors.green : (isWin == false ? Colors.red : Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }
 void _handleAction(String acao) {
    if (acao == 'criar') {
      // Gera um código aleatório alfanumérico para a sala (invisível para o usuário)
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      String novoCodigo = String.fromCharCodes(Iterable.generate(
          4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

      // Descobre qual modo de jogo está selecionado para mostrar no Lobby
      String nomeDoModo;
      switch (_selectedMode) {
        case GameMode.umContraUm: nomeDoModo = '1v1'; break;
        case GameMode.doisContraDois: nomeDoModo = '2v2'; break;
        case GameMode.tresContraTres: nomeDoModo = '3v3'; break;
        case GameMode.contraIA: nomeDoModo = 'VS IA'; break;
      }

      // Agora vai para o Lobby de Espera aguardar alguém da lista conectar!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChessBoardScreen(
            //modoDeJogo: nomeDoModo,
            roomCode: novoCodigo,
          ),
        ),
      );
    } else if (acao == 'entrar') {
      // Abre o "Server Browser" (lista de salas públicas)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const JoinRoomScreen()),
      );
    }
  }
}
