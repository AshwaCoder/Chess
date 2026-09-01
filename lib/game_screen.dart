import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'bot_engine.dart';

class GameScreen extends StatefulWidget {
  final bool isVsBot;
  final int botDepth;
  final int initialMinutes;

  const GameScreen({
    super.key,
    required this.isVsBot,
    this.botDepth = 2,
    this.initialMinutes = 10,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final ChessBoardController _controller = ChessBoardController();
  late int _whiteTimeSeconds;
  late int _blackTimeSeconds;
  Timer? _gameTimer;
  bool _isBotThinking = false;

  @override
  void initState() {
    super.initState();
    _whiteTimeSeconds = widget.initialMinutes * 60;
    _blackTimeSeconds = widget.initialMinutes * 60;
    _controller.addListener(_handleGameStateChange);
    _startTimer();
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.isGameOver()) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_controller.game.turn == chess_lib.Color.WHITE) {
          if (_whiteTimeSeconds > 0) _whiteTimeSeconds--;
        } else {
          if (_blackTimeSeconds > 0) _blackTimeSeconds--;
        }
      });
    });
  }

  void _handleGameStateChange() {
    if (_controller.isGameOver()) {
      _showGameOverDialog();
      return;
    }

    if (widget.isVsBot &&
        _controller.game.turn == chess_lib.Color.BLACK &&
        !_isBotThinking) {
      _isBotThinking = true;
      Future.delayed(const Duration(milliseconds: 400), () {
        final bestMove = BotEngine.getBestMove(_controller.game, widget.botDepth);
        if (bestMove != null) {
          _controller.makeMove(
            from: bestMove['from'],
            to: bestMove['to'],
          );
        }
        _isBotThinking = false;
      });
    }
  }

  void _showGameOverDialog() {
    String message = "Game Over";
    if (_controller.isCheckMate()) {
      final winner = _controller.game.turn == chess_lib.Color.WHITE ? 'Black' : 'White';
      message = "Checkmate! $winner wins.";
    } else if (_controller.isDraw()) {
      message = "Draw!";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF272522),
        title: const Text('Result'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Rematch', style: TextStyle(color: Color(0xFF81B64C))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _whiteTimeSeconds = widget.initialMinutes * 60;
      _blackTimeSeconds = widget.initialMinutes * 60;
      _controller.resetBoard();
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isWhiteTurn = _controller.game.turn == chess_lib.Color.WHITE;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVsBot ? 'vs Computer' : 'Pass & Play'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPlayerHeader(
              name: widget.isVsBot ? 'Bot (Depth ${widget.botDepth})' : 'Player 2 (Black)',
              time: _formatTime(_blackTimeSeconds),
              isActive: !isWhiteTurn,
              isBot: widget.isVsBot,
            ),
            Center(
              child: ChessBoard(
                controller: _controller,
                boardColor: BoardColor.green,
                boardOrientation: PlayerColor.white,
              ),
            ),
            _buildPlayerHeader(
              name: 'Player 1 (White)',
              time: _formatTime(_whiteTimeSeconds),
              isActive: isWhiteTurn,
              isBot: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader({
    required String name,
    required String time,
    required bool isActive,
    required bool isBot,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF383531) : const Color(0xFF272522),
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: const Color(0xFF81B64C), width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isBot ? Icons.smart_toy : Icons.person, color: Colors.white70),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: isActive ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
