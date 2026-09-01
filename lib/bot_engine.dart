import 'package:chess/chess.dart' as chess_lib;

class BotEngine {
  static const Map<String, int> _pieceValues = {
    'p': 100,
    'n': 320,
    'b': 330,
    'r': 500,
    'q': 900,
    'k': 20000,
  };

  static const List<int> _pawnTable = [
    0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0
  ];

  static const List<int> _knightTable = [
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  5, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  0,-30,
    -30,  5, 10, 15, 15, 10,  5,-30,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50,
  ];

  static int evaluateBoard(chess_lib.Chess game) {
    int total = 0;
    for (int i = 0; i < 64; i++) {
      final piece = game.board[i];
      if (piece == null) continue;

      int val = _pieceValues[piece.type.name] ?? 0;
      int posBonus = 0;

      if (piece.type.name == 'p') {
        posBonus = piece.color == chess_lib.Color.WHITE ? _pawnTable[i] : _pawnTable[63 - i];
      } else if (piece.type.name == 'n') {
        posBonus = piece.color == chess_lib.Color.WHITE ? _knightTable[i] : _knightTable[63 - i];
      }

      int score = val + posBonus;
      total += (piece.color == chess_lib.Color.WHITE) ? score : -score;
    }
    return total;
  }

  static int _minimax(chess_lib.Chess game, int depth, int alpha, int beta, bool isMaximizing) {
    if (depth == 0 || game.in_checkmate || game.in_draw) {
      return evaluateBoard(game);
    }

    final moves = game.moves();
    if (isMaximizing) {
      int maxEval = -999999;
      for (var move in moves) {
        game.move(move);
        int eval = _minimax(game, depth - 1, alpha, beta, false);
        game.undo_move();
        if (eval > maxEval) maxEval = eval;
        if (eval > alpha) alpha = eval;
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (var move in moves) {
        game.move(move);
        int eval = _minimax(game, depth - 1, alpha, beta, true);
        game.undo_move();
        if (eval < minEval) minEval = eval;
        if (eval < beta) beta = eval;
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  static dynamic getBestMove(chess_lib.Chess game, int depth) {
    final moves = game.moves({'verbose': true});
    if (moves.isEmpty) return null;

    dynamic bestMove;
    bool isBlack = game.turn == chess_lib.Color.BLACK;
    int bestValue = isBlack ? 999999 : -999999;

    for (var move in moves) {
      game.move(move['san']);
      int boardValue = _minimax(game, depth - 1, -999999, 999999, isBlack);
      game.undo_move();

      if (isBlack) {
        if (boardValue < bestValue) {
          bestValue = boardValue;
          bestMove = move;
        }
      } else {
        if (boardValue > bestValue) {
          bestValue = boardValue;
          bestMove = move;
        }
      }
    }
    return bestMove;
  }
}
