import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- DATA MODELS ---
enum Difficulty { easy, medium, hard }

class GameWord {
  final String word;
  final String hint;
  final String category;

  GameWord({required this.word, required this.hint, required this.category});
}

// --- MAIN SCREEN ---
class HangmanGameScreen extends StatefulWidget {
  const HangmanGameScreen({super.key});

  @override
  State<HangmanGameScreen> createState() => _HangmanGameScreenState();
}

class _HangmanGameScreenState extends State<HangmanGameScreen> {
  // --- WORD BANKS ---
  final Map<Difficulty, List<GameWord>>
  _wordBanks = <Difficulty, List<GameWord>>{
    Difficulty.easy: <GameWord>[
      GameWord(word: 'CAT', hint: 'Small pet that meows', category: 'Animals'),
      GameWord(word: 'BLUE', hint: 'Color of the sky', category: 'Colors'),
      GameWord(word: 'MOON', hint: 'Night sky object', category: 'Space'),
      GameWord(word: 'BOOK', hint: 'Read pages', category: 'Objects'),
      GameWord(word: 'LION', hint: 'King of the jungle', category: 'Animals'),
      GameWord(word: 'MILK', hint: 'White drink from cows', category: 'Food'),
    ],
    Difficulty.medium: <GameWord>[
      GameWord(word: 'FLUTTER', hint: 'UI toolkit by Google', category: 'Tech'),
      GameWord(
        word: 'PYTHON',
        hint: 'Coding language & snake',
        category: 'Tech',
      ),
      GameWord(word: 'GALAXY', hint: 'System of stars', category: 'Space'),
      GameWord(word: 'SUMMER', hint: 'Warmest season', category: 'Nature'),
      GameWord(word: 'DOCTOR', hint: 'Treats sick people', category: 'Jobs'),
      GameWord(word: 'GUITAR', hint: 'String instrument', category: 'Music'),
    ],
    Difficulty.hard: <GameWord>[
      GameWord(
        word: 'HYPOTHESIS',
        hint: 'Proposed explanation',
        category: 'Science',
      ),
      GameWord(
        word: 'ARCHAEOLOGY',
        hint: 'Study of history',
        category: 'History',
      ),
      GameWord(
        word: 'ORCHESTRA',
        hint: 'Group of musicians',
        category: 'Music',
      ),
      GameWord(
        word: 'KALEIDOSCOPE',
        hint: 'Toy with patterns',
        category: 'Objects',
      ),
      GameWord(
        word: 'ENTREPRENEUR',
        hint: 'Business starter',
        category: 'Business',
      ),
      GameWord(
        word: 'PHILOSOPHY',
        hint: 'Study of fundamental questions',
        category: 'Education',
      ),
    ],
  };

  Difficulty _currentDifficulty = Difficulty.medium;
  late GameWord currentLevel;
  List<String> guessedLetters = <String>[];
  List<int> highScores = <int>[];
  int lives = 6;
  int score = 0;
  int streak = 0;
  bool gameOver = false;
  bool gameWon = false;

  @override
  void initState() {
    super.initState();
    _loadHighScores();
    _startNewGame();
  }

  // --- LOGIC ---
  Future<void> _loadHighScores() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String>? saved = prefs.getStringList('leaderboard');
      if (saved != null) {
        highScores = saved.map((String e) => int.parse(e)).toList();
        highScores.sort((int a, int b) => b.compareTo(a));
      }
    });
  }

  Future<void> _saveScore(int newScore) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    highScores.add(newScore);
    highScores.sort((int a, int b) => b.compareTo(a));
    if (highScores.length > 10) highScores = highScores.sublist(0, 10);
    await prefs.setStringList(
      'leaderboard',
      highScores.map((int e) => e.toString()).toList(),
    );
    setState(() {});
  }

  void _startNewGame() {
    setState(() {
      List<GameWord> bank = _wordBanks[_currentDifficulty]!;
      currentLevel = bank[Random().nextInt(bank.length)];
      guessedLetters.clear();
      lives = 6;
      score = 0;
      streak = 0;
      gameOver = false;
      gameWon = false;
    });
  }

  // New: Confirmation Dialog for Reset
  void _confirmReset() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restart Game?'),
        content: const Text('This will reset your current score to 0.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('RESTART'),
          ),
        ],
      ),
    );
  }

  void _changeDifficulty(Difficulty? newDifficulty) {
    if (newDifficulty != null) {
      setState(() {
        _currentDifficulty = newDifficulty;
        _startNewGame();
      });
    }
  }

  void _guessLetter(String letter) {
    if (gameOver || gameWon || guessedLetters.contains(letter)) return;

    setState(() {
      guessedLetters.add(letter);
      if (currentLevel.word.contains(letter)) {
        streak++;
        int multiplier = _currentDifficulty == Difficulty.easy
            ? 1
            : _currentDifficulty == Difficulty.medium
            ? 2
            : 3;
        score += (50 * multiplier) + (streak * 10);
      } else {
        streak = 0;
        lives--;
      }
      _checkGameStatus();
    });
  }

  void _checkGameStatus() {
    bool allLettersGuessed = true;
    for (int i = 0; i < currentLevel.word.length; i++) {
      if (!guessedLetters.contains(currentLevel.word[i])) {
        allLettersGuessed = false;
        break;
      }
    }

    if (allLettersGuessed) {
      gameWon = true;
      score += 500 + (lives * 100);
      _saveScore(score);
      _showEndDialog(true);
    } else if (lives <= 0) {
      gameOver = true;
      _showEndDialog(false);
    }
  }

  void _showEndDialog(bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: success ? Colors.green.shade50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.emoji_events_rounded : Icons.cancel_rounded,
                size: 48,
                color: success ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'VICTORY' : 'GAME OVER',
              style: TextStyle(
                color: success ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$score Points',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              success ? 'New High Score!' : 'Better luck next time',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (!success) ...<Widget>[
              const Text(
                'The word was:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentLevel.word,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewGame();
              },
              child: const Text(
                'PLAY AGAIN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.leaderboard, color: Colors.amber),
            ),
            const SizedBox(width: 12),
            const Text(
              'Leaderboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          height: 300,
          child: highScores.isEmpty
              ? const Center(
                  child: Text(
                    'No scores yet. Play now!',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  itemCount: highScores.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final bool isTop = index < 3;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isTop
                            ? const Color(0xFF6C63FF)
                            : Colors.grey.shade200,
                        foregroundColor: isTop ? Colors.white : Colors.black54,
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        '${highScores[index]} pts',
                        style: TextStyle(
                          fontWeight: isTop ? FontWeight.w900 : FontWeight.bold,
                          color: isTop ? Colors.black87 : Colors.black54,
                          fontSize: isTop ? 18 : 16,
                        ),
                      ),
                      trailing: isTop
                          ? const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                bool isWide = constraints.maxWidth > 800;

                if (isWide) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(flex: 4, child: _buildVisualCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: _buildGameCard()),
                      ],
                    ),
                  );
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        _buildVisualCard(),
                        const SizedBox(height: 16),
                        _buildGameCard(),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.videogame_asset, color: Color(0xFF6C63FF)),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'HANGMAN PRO',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Difficulty>(
                value: _currentDifficulty,
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  fontSize: 13,
                ),
                onChanged: _changeDifficulty,
                items: Difficulty.values.map((Difficulty level) {
                  Color color = level == Difficulty.easy
                      ? Colors.green
                      : level == Difficulty.medium
                      ? Colors.orange
                      : Colors.red;
                  return DropdownMenuItem<Difficulty>(
                    value: level,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.circle, size: 8, color: color),
                        const SizedBox(width: 6),
                        Text(level.name.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // NEW: Reset Button
        IconButton(
          onPressed: _confirmReset,
          icon: const Icon(Icons.refresh, color: Colors.black87),
          tooltip: 'Restart Game',
        ),

        IconButton(
          onPressed: _showLeaderboard,
          icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
          tooltip: 'Leaderboard',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildVisualCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.favorite, size: 18, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '$lives',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              width: 220,
              child: CustomPaint(painter: HangmanPainter(lives: lives)),
            ),
            const SizedBox(height: 20),
            if (streak > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$streak x STREAK!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    currentLevel.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentLevel.hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: currentLevel.word.split('').map((String char) {
                bool isGuessed = guessedLetters.contains(char);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 40,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 3,
                        color: isGuessed
                            ? const Color(0xFF6C63FF)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Text(
                    isGuessed ? char : '',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((
                  String letter,
                ) {
                  bool isGuessed = guessedLetters.contains(letter);
                  return SizedBox(
                    width: 36,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: isGuessed || gameOver || gameWon
                          ? null
                          : () => _guessLetter(letter),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isGuessed
                            ? Colors.grey.shade200
                            : Colors.white,
                        foregroundColor: isGuessed
                            ? Colors.grey
                            : Colors.black87,
                        elevation: isGuessed ? 0 : 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: isGuessed
                              ? Colors.transparent
                              : Colors.grey.shade200,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HangmanPainter extends CustomPainter {
  final int lives;
  HangmanPainter({required this.lives});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    double w = size.width, h = size.height;

    canvas.drawLine(Offset(w * 0.1, h * 0.9), Offset(w * 0.9, h * 0.9), paint);
    canvas.drawLine(Offset(w * 0.2, h * 0.9), Offset(w * 0.2, h * 0.1), paint);
    canvas.drawLine(Offset(w * 0.2, h * 0.1), Offset(w * 0.6, h * 0.1), paint);
    canvas.drawLine(Offset(w * 0.6, h * 0.1), Offset(w * 0.6, h * 0.25), paint);

    if (lives < 6) canvas.drawCircle(Offset(w * 0.6, h * 0.3), 20, paint);
    if (lives < 5)
      canvas.drawLine(
        Offset(w * 0.6, h * 0.3 + 20),
        Offset(w * 0.6, h * 0.6),
        paint,
      );
    if (lives < 4)
      canvas.drawLine(
        Offset(w * 0.6, h * 0.4),
        Offset(w * 0.5, h * 0.5),
        paint,
      );
    if (lives < 3)
      canvas.drawLine(
        Offset(w * 0.6, h * 0.4),
        Offset(w * 0.7, h * 0.5),
        paint,
      );
    if (lives < 2)
      canvas.drawLine(
        Offset(w * 0.6, h * 0.6),
        Offset(w * 0.5, h * 0.8),
        paint,
      );
    if (lives < 1)
      canvas.drawLine(
        Offset(w * 0.6, h * 0.6),
        Offset(w * 0.7, h * 0.8),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant HangmanPainter oldDelegate) =>
      oldDelegate.lives != lives;
}
