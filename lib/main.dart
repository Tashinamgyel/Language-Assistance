import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BackgroundScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const BackgroundScaffold({
    Key? key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image covering the entire screen.
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.jpeg',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
        ),
      ],
    );
  }
}

class Vocabulary {
  String id;
  String word;
  String meaning;
  String sampleSentence;

  Vocabulary({
    required this.id,
    required this.word,
    required this.meaning,
    required this.sampleSentence,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "word": word,
    "meaning": meaning,
    "sampleSentence": sampleSentence,
  };

  factory Vocabulary.fromJson(Map<String, dynamic> json) => Vocabulary(
    id: json["id"],
    word: json["word"],
    meaning: json["meaning"],
    sampleSentence: json["sampleSentence"],
  );
}

// Convert MyApp to a StatefulWidget to hold the current locale.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define custom red-themed UI colors.
    const Color primaryColor = Color.fromARGB(255, 63, 161, 188);
    // Background is provided by the image so we use transparent here.
    const Color scaffoldBackground = Colors.transparent;
    final Color cardColor = const Color.fromARGB(255, 63, 161, 188);
    const Color textColor = Colors.white70;

    return MaterialApp(
      title: 'LULU',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: scaffoldBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: cardColor,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: Color.fromARGB(255, 239, 201, 73),
          unselectedItemColor: Color.fromARGB(255, 239, 201, 73),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
        useMaterial3: false,
      ),
      // Localization delegates and supported locales.
      localizationsDelegates: const [
        AppLocalizations.delegate, // Generated from ARB files.
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      // Pass the locale change callback to HomeScreen.
      home: HomeScreen(onLocaleChange: _changeLocale),
    );
  }
}

// HomeScreen holds two tabs: Vocabulary list and Quiz.
class HomeScreen extends StatefulWidget {
  final void Function(Locale locale) onLocaleChange;

  const HomeScreen({super.key, required this.onLocaleChange});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Vocabulary> vocabularies = [];

  @override
  void initState() {
    super.initState();
    _loadVocabularyFromPrefs();
  }

  Future<void> _loadVocabularyFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? vocabString = prefs.getString('vocabList');
    if (vocabString != null) {
      List decoded = jsonDecode(vocabString);
      setState(() {
        vocabularies =
            decoded.map((e) => Vocabulary.fromJson(e)).toList().cast<Vocabulary>();
      });
    }
  }

  Future<void> _saveVocabulariesToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encoded =
    jsonEncode(vocabularies.map((v) => v.toJson()).toList());
    await prefs.setString('vocabList', encoded);
  }

  void _addVocabulary(Vocabulary vocab) {
    setState(() {
      vocabularies.add(vocab);
    });
    _saveVocabulariesToPrefs();
  }

  void _updateVocabulary(Vocabulary vocab) {
    setState(() {
      int index = vocabularies.indexWhere((v) => v.id == vocab.id);
      if (index != -1) {
        vocabularies[index] = vocab;
      }
    });
    _saveVocabulariesToPrefs();
  }

  void _deleteVocabulary(String id) {
    setState(() {
      vocabularies.removeWhere((v) => v.id == id);
    });
    _saveVocabulariesToPrefs();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _widgetOptions() => [
    VocabularyListScreen(
      vocabularies: vocabularies,
      onAdd: _addVocabulary,
      onUpdate: _updateVocabulary,
      onDelete: _deleteVocabulary,
    ),
    QuizScreen(vocabularies: vocabularies),
  ];

  @override
  Widget build(BuildContext context) {
    // Retrieve the current locale from the BuildContext.
    Locale currentLocale = Localizations.localeOf(context);

    return WillPopScope(
      onWillPop: () async {
        // If in the quiz tab, go back to vocabulary tab instead of exiting.
        if (_selectedIndex == 1) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: BackgroundScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.appTitle),
            ],
          ),
          actions: [
            // Dropdown to change language between English and Chinese.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<Locale>(
                value: currentLocale,
                underline: const SizedBox(), // Remove underline for cleaner look.
                icon: const Icon(Icons.language, color: Colors.white),
                dropdownColor: const Color.fromARGB(255, 63, 161, 188),
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    widget.onLocaleChange(newLocale);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: Locale('en'),
                    child:
                    Text('English', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: Locale('zh'),
                    child: Text('中文', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _widgetOptions().elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.list),
              label: AppLocalizations.of(context)!.vocabulary,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.quiz),
              label: AppLocalizations.of(context)!.quiz,
            ),
          ],
        ),
      ),
    );
  }
}

class VocabularyListScreen extends StatelessWidget {
  final List<Vocabulary> vocabularies;
  final Function(Vocabulary) onAdd;
  final Function(Vocabulary) onUpdate;
  final Function(String) onDelete;

  const VocabularyListScreen({
    required this.vocabularies,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content: either display an empty state or list of vocabularies.
        vocabularies.isEmpty
            ? Center(
          child: Text(
            AppLocalizations.of(context)!.noVocabulary,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vocabularies.length,
          itemBuilder: (context, index) {
            final vocab = vocabularies[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                title: Text(
                  vocab.word,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meaning: ${vocab.meaning}',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('Example: ${vocab.sampleSentence}',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button.
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditVocabularyScreen(
                              vocabulary: vocab,
                              onSave: onUpdate,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onLongPress: () {
                  // Confirm deletion.
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete "${vocab.word}"?',
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor:
                      const Color.fromARGB(255, 63, 161, 188),
                      content: const Text(
                        'Are you sure you want to delete this vocabulary?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onDelete(vocab.id);
                            Navigator.pop(context);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.delete,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
        // Floating plus button positioned over the list.
        Positioned(
          bottom: 20,
          right: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddEditVocabularyScreen(onSave: onAdd),
                ),
              );
            },
            child: Image.asset(
              'assets/images/plus.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

// Screen for adding or editing a vocabulary entry.
class AddEditVocabularyScreen extends StatefulWidget {
  final Vocabulary? vocabulary;
  final Function(Vocabulary) onSave;

  const AddEditVocabularyScreen({super.key, this.vocabulary, required this.onSave});

  @override
  _AddEditVocabularyScreenState createState() => _AddEditVocabularyScreenState();
}

class _AddEditVocabularyScreenState extends State<AddEditVocabularyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wordController;
  String generatedMeaning = '';
  String generatedSentence = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.vocabulary?.word ?? '');
    if (widget.vocabulary != null) {
      generatedMeaning = widget.vocabulary!.meaning;
      generatedSentence = widget.vocabulary!.sampleSentence;
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  // Calls OpenAI API endpoints to generate meaning and example sentence.
  Future<void> _generateData() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;
    setState(() {
      _isGenerating = true;
      generatedMeaning = '';
      generatedSentence = '';
    });
    try {
      final responses = await Future.wait([
        fetchMeaning(word),
        fetchSentence(word),
      ]);
      setState(() {
        generatedMeaning = responses[0];
        generatedSentence = responses[1];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch data from API')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _saveVocabulary() {
    if (_formKey.currentState!.validate()) {
      if (generatedMeaning.isEmpty || generatedSentence.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please generate data before saving.')),
        );
        return;
      }
      final vocab = Vocabulary(
        id: widget.vocabulary?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        word: _wordController.text.trim(),
        meaning: generatedMeaning,
        sampleSentence: generatedSentence,
      );
      widget.onSave(vocab);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vocabulary != null;
    return BackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(isEditing
            ? AppLocalizations.of(context)!.editVocabulary
            : AppLocalizations.of(context)!.addVocabulary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _wordController,
                style: const TextStyle(color: Colors.yellow),
                decoration: const InputDecoration(
                  labelText: 'Word',
                  labelStyle: TextStyle(color: Colors.yellow),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    generatedMeaning = '';
                    generatedSentence = '';
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a word';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isGenerating ? null : _generateData,
                child: _isGenerating
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Generating...')
                  ],
                )
                    : Text(AppLocalizations.of(context)!.generateData),
              ),
              const SizedBox(height: 24),
              if (generatedMeaning.isNotEmpty || generatedSentence.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meaning & Example:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: const Color.fromARGB(255, 63, 161, 188),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: const Text('Meaning', style: TextStyle(color: Colors.white)),
                        subtitle: Text(generatedMeaning, style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: const Color.fromARGB(255, 63, 161, 188),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: const Text('Example Sentence', style: TextStyle(color: Colors.white)),
                        subtitle: Text(generatedSentence, style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveVocabulary,
                child: Text(isEditing
                    ? AppLocalizations.of(context)!.updateVocabulary
                    : AppLocalizations.of(context)!.addVocabulary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quiz screen that presents a fill-in-the-blank question.
class QuizScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;

  const QuizScreen({super.key, required this.vocabularies});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Vocabulary? currentVocab;
  TextEditingController _answerController = TextEditingController();
  String feedback = '';

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  void _loadNextQuestion() {
    setState(() {
      feedback = '';
      _answerController.text = '';
      if (widget.vocabularies.isNotEmpty) {
        final randomIndex = Random().nextInt(widget.vocabularies.length);
        currentVocab = widget.vocabularies[randomIndex];
      } else {
        currentVocab = null;
      }
    });
  }

  // Replace the vocabulary word in the sample sentence with a blank.
  String _getQuizSentence() {
    if (currentVocab == null) return '';
    String sentence = currentVocab!.sampleSentence;
    final pattern = RegExp(currentVocab!.word, caseSensitive: false);
    return sentence.replaceAll(pattern, '_____');
  }

  void _submitAnswer() {
    if (currentVocab == null) return;
    final userAnswer = _answerController.text.trim();
    if (userAnswer.toLowerCase() == currentVocab!.word.toLowerCase()) {
      setState(() {
        feedback = 'Correct!';
      });
    } else {
      setState(() {
        feedback = 'Incorrect. The correct word was "${currentVocab!.word}".';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentVocab == null) {
      return const Center(
        child: Text(
          'No vocabulary available for quiz.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Fill in the blank:',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color.fromARGB(255, 63, 161, 188),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _getQuizSentence(),
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Your Answer',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitAnswer,
            child: const Text('Submit Answer'),
          ),
          const SizedBox(height: 16),
          Text(
            feedback,
            style: const TextStyle(fontSize: 18, color: Colors.green),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _loadNextQuestion,
            child: const Text('Next Question'),
          ),
        ],
      ),
    );
  }
}

// Updated OpenAI API calls using GPT-3.5-turbo.
Future<String> fetchMeaning(String word) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  const apiKey = '';

  final body = jsonEncode({
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Provide a clear, short definition of the word \"$word\"."},
    ],
    "stream": false,
  });

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content']?.toString().trim() ?? 'Meaning not found';
    } else {
      return 'Meaning not available';
    }
  } catch (e) {
    print('Error fetching meaning: $e');
    return 'Meaning not available';
  }
}

Future<String> fetchSentence(String word) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  const apiKey = '';

  final body = jsonEncode({
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "system", "content": "You are a creative assistant."},
      {
        "role": "user",
        "content": "Provide a single, clear example sentence in English that uses the word \"$word\" in context. Return only the sentence with no additional commentary."
      },
    ],
    "stream": false,
  });

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content']?.toString().trim() ?? 'Sentence not found';
    } else {
      return 'Sentence not available';
    }
  } catch (e) {
    print('Error fetching sentence: $e');
    return 'Sentence not available';
  }
}

void main() {
  runApp(const MyApp());
}


// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// /// A common widget that wraps a Scaffold with a full-screen background image.
// class BackgroundScaffold extends StatelessWidget {
//   final PreferredSizeWidget? appBar;
//   final Widget body;
//   final Widget? bottomNavigationBar;
//   final Widget? floatingActionButton;
//
//   const BackgroundScaffold({
//     Key? key,
//     this.appBar,
//     required this.body,
//     this.bottomNavigationBar,
//     this.floatingActionButton,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // Background image covering the entire screen.
//         Positioned.fill(
//           child: Image.asset(
//             'assets/images/background.jpeg',
//             fit: BoxFit.cover,
//           ),
//         ),
//         // The main scaffold with a transparent background.
//         Scaffold(
//           backgroundColor: Colors.transparent,
//           appBar: appBar,
//           body: body,
//           bottomNavigationBar: bottomNavigationBar,
//           floatingActionButton: floatingActionButton,
//         ),
//       ],
//     );
//   }
// }
//
// // Model class for a vocabulary entry.
// class Vocabulary {
//   String id;
//   String word;
//   String meaning;
//   String sampleSentence;
//
//   Vocabulary({
//     required this.id,
//     required this.word,
//     required this.meaning,
//     required this.sampleSentence,
//   });
//
//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "word": word,
//     "meaning": meaning,
//     "sampleSentence": sampleSentence,
//   };
//
//   factory Vocabulary.fromJson(Map<String, dynamic> json) => Vocabulary(
//     id: json["id"],
//     word: json["word"],
//     meaning: json["meaning"],
//     sampleSentence: json["sampleSentence"],
//   );
// }
//
// // Convert MyApp to a StatefulWidget to hold the current locale.
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   Locale _locale = const Locale('en');
//
//   void _changeLocale(Locale locale) {
//     setState(() {
//       _locale = locale;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Define custom red-themed UI colors.
//     const Color primaryColor = Color.fromARGB(255, 63, 161, 188);
//     // Background is provided by the image so we use transparent here.
//     const Color scaffoldBackground = Colors.transparent;
//     final Color cardColor = Color.fromARGB(255, 63, 161, 188);
//     const Color textColor = Colors.white70;
//
//     return MaterialApp(
//       title: 'LULU',
//       debugShowCheckedModeBanner: false,
//       locale: _locale,
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         scaffoldBackgroundColor: scaffoldBackground,
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           centerTitle: true,
//           iconTheme: IconThemeData(color: Colors.white),
//           titleTextStyle: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         cardColor: cardColor,
//         bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//           backgroundColor: Colors.transparent,
//           selectedItemColor: Color.fromARGB(255, 239, 201, 73),
//           unselectedItemColor: Color.fromARGB(255, 239, 201, 73),
//         ),
//         floatingActionButtonTheme: const FloatingActionButtonThemeData(
//           // Not used here since we replace it with a custom image.
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: primaryColor,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//         textTheme: const TextTheme(
//           bodyMedium: TextStyle(color: Colors.white),
//           bodyLarge: TextStyle(color: Colors.white),
//         ),
//         useMaterial3: false,
//       ),
//       // Localization delegates and supported locales.
//       localizationsDelegates: const [
//         AppLocalizations.delegate, // Generated from ARB files.
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: const [
//         Locale('en'),
//         Locale('zh'),
//       ],
//       // Pass the locale change callback to HomeScreen.
//       home: HomeScreen(onLocaleChange: _changeLocale),
//     );
//   }
// }
//
// // HomeScreen holds two tabs: Vocabulary list and Quiz.
// class HomeScreen extends StatefulWidget {
//   final void Function(Locale locale) onLocaleChange;
//
//   const HomeScreen({super.key, required this.onLocaleChange});
//
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   List<Vocabulary> vocabularies = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadVocabularyFromPrefs();
//   }
//
//   Future<void> _loadVocabularyFromPrefs() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? vocabString = prefs.getString('vocabList');
//     if (vocabString != null) {
//       List decoded = jsonDecode(vocabString);
//       setState(() {
//         vocabularies = decoded.map((e) => Vocabulary.fromJson(e)).toList().cast<Vocabulary>();
//       });
//     }
//   }
//
//   Future<void> _saveVocabulariesToPrefs() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String encoded = jsonEncode(vocabularies.map((v) => v.toJson()).toList());
//     await prefs.setString('vocabList', encoded);
//   }
//
//   void _addVocabulary(Vocabulary vocab) {
//     setState(() {
//       vocabularies.add(vocab);
//     });
//     _saveVocabulariesToPrefs();
//   }
//
//   void _updateVocabulary(Vocabulary vocab) {
//     setState(() {
//       int index = vocabularies.indexWhere((v) => v.id == vocab.id);
//       if (index != -1) {
//         vocabularies[index] = vocab;
//       }
//     });
//     _saveVocabulariesToPrefs();
//   }
//
//   void _deleteVocabulary(String id) {
//     setState(() {
//       vocabularies.removeWhere((v) => v.id == id);
//     });
//     _saveVocabulariesToPrefs();
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   List<Widget> _widgetOptions() => [
//     VocabularyListScreen(
//       vocabularies: vocabularies,
//       onAdd: _addVocabulary,
//       onUpdate: _updateVocabulary,
//       onDelete: _deleteVocabulary,
//     ),
//     QuizScreen(vocabularies: vocabularies),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     // Retrieve the current locale from the BuildContext.
//     Locale currentLocale = Localizations.localeOf(context);
//
//     return WillPopScope(
//       onWillPop: () async {
//         // If in the quiz tab, go back to vocabulary tab instead of exiting.
//         if (_selectedIndex == 1) {
//           setState(() {
//             _selectedIndex = 0;
//           });
//           return false;
//         }
//         return true;
//       },
//       child: BackgroundScaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           title: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Logo image with appropriate size.
//               const SizedBox(width: 8),
//               Text(AppLocalizations.of(context)!.appTitle),
//             ],
//           ),
//           actions: [
//             // Dropdown to change language between English and Chinese.
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: DropdownButton<Locale>(
//                 value: currentLocale,
//                 underline: const SizedBox(), // Remove underline for cleaner look.
//                 icon: const Icon(Icons.language, color: Colors.white),
//                 dropdownColor: Color.fromARGB(255, 63, 161, 188),
//                 onChanged: (Locale? newLocale) {
//                   if (newLocale != null) {
//                     widget.onLocaleChange(newLocale);
//                   }
//                 },
//                 items: const [
//                   DropdownMenuItem(
//                     value: Locale('en'),
//                     child: Text('English', style: TextStyle(color: Colors.white)),
//                   ),
//                   DropdownMenuItem(
//                     value: Locale('zh'),
//                     child: Text('中文', style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         body: _widgetOptions().elementAt(_selectedIndex),
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: _onItemTapped,
//           items: [
//             BottomNavigationBarItem(
//               icon: const Icon(Icons.list),
//               label: AppLocalizations.of(context)!.vocabulary,
//             ),
//             BottomNavigationBarItem(
//               icon: const Icon(Icons.quiz),
//               label: AppLocalizations.of(context)!.quiz,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Screen that displays the list of vocabulary entries.
// class VocabularyListScreen extends StatelessWidget {
//   final List<Vocabulary> vocabularies;
//   final Function(Vocabulary) onAdd;
//   final Function(Vocabulary) onUpdate;
//   final Function(String) onDelete;
//
//   const VocabularyListScreen({
//     required this.vocabularies,
//     required this.onAdd,
//     required this.onUpdate,
//     required this.onDelete,
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return BackgroundScaffold(
//       body: vocabularies.isEmpty
//           ? Center(
//         child: Text(
//           AppLocalizations.of(context)!.noVocabulary,
//           style: const TextStyle(fontSize: 16, color: Colors.white70),
//         ),
//       )
//           : ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: vocabularies.length,
//         itemBuilder: (context, index) {
//           final vocab = vocabularies[index];
//           return Card(
//             elevation: 2,
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: ListTile(
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               title: Text(
//                 vocab.word,
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               subtitle: Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Meaning: ${vocab.meaning}',
//                         style: const TextStyle(color: Colors.white70)),
//                     const SizedBox(height: 4),
//                     Text('Example: ${vocab.sampleSentence}',
//                         style: const TextStyle(color: Colors.white70)),
//                   ],
//                 ),
//               ),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Edit button.
//                   IconButton(
//                     icon: const Icon(Icons.edit, color: Colors.white70),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => AddEditVocabularyScreen(
//                             vocabulary: vocab,
//                             onSave: onUpdate,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//               onLongPress: () {
//                 // Confirm deletion.
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: Text('Delete "${vocab.word}"?',
//                         style: const TextStyle(color: Colors.white)),
//                     backgroundColor: Color.fromARGB(255, 63, 161, 188),
//                     content: const Text(
//                       'Are you sure you want to delete this vocabulary?',
//                       style: TextStyle(color: Colors.white70),
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Cancel', style: TextStyle(color: Colors.white),),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           onDelete(vocab.id);
//                           Navigator.pop(context);
//                         },
//                         child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.white),),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//       // Use just the plus image without a circular background.
//       floatingActionButton: GestureDetector(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddEditVocabularyScreen(onSave: onAdd),
//             ),
//           );
//         },
//         child: Image.asset(
//           'assets/images/plus.png',
//           width: 80,
//           height: 80,
//           fit: BoxFit.contain,
//         ),
//       ),
//     );
//   }
// }
//
// // Screen for adding or editing a vocabulary entry.
// class AddEditVocabularyScreen extends StatefulWidget {
//   final Vocabulary? vocabulary;
//   final Function(Vocabulary) onSave;
//
//   const AddEditVocabularyScreen({super.key, this.vocabulary, required this.onSave});
//
//   @override
//   _AddEditVocabularyScreenState createState() => _AddEditVocabularyScreenState();
// }
//
// class _AddEditVocabularyScreenState extends State<AddEditVocabularyScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _wordController;
//   String generatedMeaning = '';
//   String generatedSentence = '';
//   bool _isGenerating = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _wordController = TextEditingController(text: widget.vocabulary?.word ?? '');
//     if (widget.vocabulary != null) {
//       generatedMeaning = widget.vocabulary!.meaning;
//       generatedSentence = widget.vocabulary!.sampleSentence;
//     }
//   }
//
//   @override
//   void dispose() {
//     _wordController.dispose();
//     super.dispose();
//   }
//
//   // Calls OpenAI API endpoints to generate meaning and example sentence.
//   Future<void> _generateData() async {
//     final word = _wordController.text.trim();
//     if (word.isEmpty) return;
//     setState(() {
//       _isGenerating = true;
//       generatedMeaning = '';
//       generatedSentence = '';
//     });
//     try {
//       final responses = await Future.wait([
//         fetchMeaning(word),
//         fetchSentence(word),
//       ]);
//       setState(() {
//         generatedMeaning = responses[0];
//         generatedSentence = responses[1];
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to fetch data from API')),
//       );
//     } finally {
//       setState(() {
//         _isGenerating = false;
//       });
//     }
//   }
//
//   void _saveVocabulary() {
//     if (_formKey.currentState!.validate()) {
//       if (generatedMeaning.isEmpty || generatedSentence.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please generate data before saving.')),
//         );
//         return;
//       }
//       final vocab = Vocabulary(
//         id: widget.vocabulary?.id ??
//             DateTime.now().millisecondsSinceEpoch.toString(),
//         word: _wordController.text.trim(),
//         meaning: generatedMeaning,
//         sampleSentence: generatedSentence,
//       );
//       widget.onSave(vocab);
//       Navigator.pop(context);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isEditing = widget.vocabulary != null;
//     return BackgroundScaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         title: Text(isEditing
//             ? AppLocalizations.of(context)!.editVocabulary
//             : AppLocalizations.of(context)!.addVocabulary),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 controller: _wordController,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: const InputDecoration(
//                   labelText: 'Word',
//                   labelStyle: TextStyle(color: Colors.yellow),
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     generatedMeaning = '';
//                     generatedSentence = '';
//                   });
//                 },
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Please enter a word';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _isGenerating ? null : _generateData,
//                 child: _isGenerating
//                     ? const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     Text('Generating...')
//                   ],
//                 )
//                     : Text(AppLocalizations.of(context)!.generateData),
//               ),
//               const SizedBox(height: 24),
//               if (generatedMeaning.isNotEmpty || generatedSentence.isNotEmpty)
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Meaning & Example:',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Card(
//                       color: Color.fromARGB(255, 63, 161, 188),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: ListTile(
//                         title: const Text('Meaning', style: TextStyle(color: Colors.white)),
//                         subtitle: Text(generatedMeaning, style: const TextStyle(color: Colors.white70)),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Card(
//                       color: Color.fromARGB(255, 63, 161, 188),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: ListTile(
//                         title: const Text('Example Sentence', style: TextStyle(color: Colors.white)),
//                         subtitle: Text(generatedSentence, style: const TextStyle(color: Colors.white70)),
//                       ),
//                     ),
//                   ],
//                 ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: _saveVocabulary,
//                 child: Text(isEditing
//                     ? AppLocalizations.of(context)!.updateVocabulary
//                     : AppLocalizations.of(context)!.addVocabulary),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Quiz screen that presents a fill-in-the-blank question.
// class QuizScreen extends StatefulWidget {
//   final List<Vocabulary> vocabularies;
//
//   const QuizScreen({super.key, required this.vocabularies});
//
//   @override
//   _QuizScreenState createState() => _QuizScreenState();
// }
//
// class _QuizScreenState extends State<QuizScreen> {
//   Vocabulary? currentVocab;
//   TextEditingController _answerController = TextEditingController();
//   String feedback = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadNextQuestion();
//   }
//
//   void _loadNextQuestion() {
//     setState(() {
//       feedback = '';
//       _answerController.text = '';
//       if (widget.vocabularies.isNotEmpty) {
//         final randomIndex = Random().nextInt(widget.vocabularies.length);
//         currentVocab = widget.vocabularies[randomIndex];
//       } else {
//         currentVocab = null;
//       }
//     });
//   }
//
//   // Replace the vocabulary word in the sample sentence with a blank.
//   String _getQuizSentence() {
//     if (currentVocab == null) return '';
//     String sentence = currentVocab!.sampleSentence;
//     final pattern = RegExp(currentVocab!.word, caseSensitive: false);
//     return sentence.replaceAll(pattern, '_____');
//   }
//
//   void _submitAnswer() {
//     if (currentVocab == null) return;
//     final userAnswer = _answerController.text.trim();
//     if (userAnswer.toLowerCase() == currentVocab!.word.toLowerCase()) {
//       setState(() {
//         feedback = 'Correct!';
//       });
//     } else {
//       setState(() {
//         feedback = 'Incorrect. The correct word was "${currentVocab!.word}".';
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (currentVocab == null) {
//       return const Center(
//         child: Text(
//           'No vocabulary available for quiz.',
//           style: TextStyle(color: Colors.white70),
//         ),
//       );
//     }
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const Text(
//             'Fill in the blank:',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
//           ),
//           const SizedBox(height: 16),
//           Card(
//             color: Color.fromARGB(255, 63, 161, 188),
//             elevation: 3,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Text(
//                 _getQuizSentence(),
//                 style: const TextStyle(fontSize: 20, color: Colors.white),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _answerController,
//             style: const TextStyle(color: Colors.white),
//             decoration: const InputDecoration(
//               labelText: 'Your Answer',
//               labelStyle: TextStyle(color: Colors.white),
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _submitAnswer,
//             child: const Text('Submit Answer'),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             feedback,
//             style: const TextStyle(fontSize: 18, color: Colors.green),
//           ),
//           const Spacer(),
//           ElevatedButton(
//             onPressed: _loadNextQuestion,
//             child: const Text('Next Question'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Updated OpenAI API calls using GPT-3.5-turbo.
// Future<String> fetchMeaning(String word) async {
//   final url = Uri.parse('https://api.openai.com/v1/chat/completions');
//   const apiKey = '';
//
//   final body = jsonEncode({
//     "model": "gpt-3.5-turbo",
//     "messages": [
//       {"role": "system", "content": "You are a helpful assistant."},
//       {"role": "user", "content": "Provide a clear, short definition of the word \"$word\"."},
//     ],
//     "stream": false,
//   });
//
//   try {
//     final response = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $apiKey",
//       },
//       body: body,
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['choices'][0]['message']['content']?.toString().trim() ?? 'Meaning not found';
//     } else {
//       return 'Meaning not available';
//     }
//   } catch (e) {
//     print('Error fetching meaning: $e');
//     return 'Meaning not available';
//   }
// }
//
// void main() {
//   runApp(const MyApp());
//
// }
//
// Future<String> fetchSentence(String word) async {
//   final url = Uri.parse('https://api.openai.com/v1/chat/completions');
//   const apiKey = '';
//
//   final body = jsonEncode({
//     "model": "gpt-3.5-turbo",
//     "messages": [
//       {"role": "system", "content": "You are a creative assistant."},
//       {
//         "role": "user",
//         "content": "Provide a single, clear example sentence in English that uses the word \"$word\" in context. Return only the sentence with no additional commentary."
//       },
//     ],
//     "stream": false,
//   });
//
//   try {
//     final response = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $apiKey",
//       },
//       body: body,
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['choices'][0]['message']['content']?.toString().trim() ?? 'Sentence not found';
//     } else {
//       return 'Sentence not available';
//     }
//   } catch (e) {
//     print('Error fetching sentence: $e');
//     return 'Sentence not available';
//   }
// }
//
