import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/quotes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/quote_card.dart';
import '../../models/habit.dart';
import '../../services/firebase_service.dart';
import '../../screens/profile_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = Habit.predefinedCategories.first;
  Set<String> favoriteQuoteIds = {};
  bool favoriteLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final habits = Provider.of<HabitsProvider>(context, listen: false);
    if (auth.user != null) habits.setUser(auth.user!.uid);
    final quotesProvider = Provider.of<QuotesProvider>(context, listen: false);
    quotesProvider.loadInitialQuotes();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (uid != null) {
      favoriteQuoteIds = await FirebaseService().getFavoriteQuoteIds(uid);
    }
    setState(() => favoriteLoading = false);
  }

  void _showAddDialog() {
    final habitsProvider = Provider.of<HabitsProvider>(context, listen: false);
    final nameCtrl = TextEditingController();
    String category = Habit.predefinedCategories.first;
    String frequency = 'daily';
    DateTime? startDate;
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Habit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: Habit.predefinedCategories
                    .map((c) => DropdownMenuItem(
                  value: c,
                  child: Row(children: [Icon(Habit.defaultIcon(c)), const SizedBox(width: 8), Text(c)]),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) category = val;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (val) {
                  if (val != null) frequency = val;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Start Date:'),
                  const SizedBox(width: 12),
                  Text(startDate != null
                      ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                      : 'Not selected'),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => startDate = picked);
                    },
                    child: const Text('Select'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              final h = Habit(
                id: id,
                name: name,
                category: category,
                frequency: frequency,
                createdAt: startDate ?? DateTime.now(),
                notes: notesCtrl.text.trim(),
              );
              await habitsProvider.addHabit(h);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final habitsProvider = Provider.of<HabitsProvider>(context);
    final quotesProvider = Provider.of<QuotesProvider>(context);

    final filteredHabits = habitsProvider.habits.where((h) => h.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 36, width: 36, fit: BoxFit.contain),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Hi, ${auth.user?.displayName ?? auth.user?.email ?? 'User'}', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.settings),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
              ),
              PopupMenuItem(
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    double opacity = 1.0;
                    return StatefulBuilder(
                      builder: (context, setState) => AnimatedOpacity(
                        opacity: opacity,
                        duration: const Duration(milliseconds: 150),
                        child: ListTile(
                          leading: const Icon(Icons.brightness_6),
                          title: const Text('Dark Mode'),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (val) {
                              setState(() => opacity = 0);
                              Future.delayed(const Duration(milliseconds: 150), () {
                                Navigator.pop(context);
                                themeProvider.toggleTheme();
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    Navigator.pop(context);
                    await auth.logout();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE6F4EA), Color(0xFFD0F0C0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await quotesProvider.fetchQuotes();
            await _loadFavorites();
          },
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Your Habits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items: Habit.predefinedCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (filteredHabits.isEmpty)
                const Center(child: Text('No habits yet. Add one!'))
              else
                Column(children: filteredHabits.map((h) => HabitCard(habit: h)).toList()),
              const SizedBox(height: 16),
              const Text('Motivational Quotes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (quotesProvider.isLoading || favoriteLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: quotesProvider.quotes.take(2).map((q) {
                    final isFav = favoriteQuoteIds.contains(q.id);
                    return QuoteCard(
                      quote: q,
                      isFavorite: isFav,
                      onFavorite: () async {
                        final uid = auth.user?.uid;
                        if (uid == null) return;
                        if (isFav) {
                          await FirebaseService().removeFavoriteQuote(uid, q.id);
                        } else {
                          await FirebaseService().saveFavoriteQuote(uid, q);
                        }
                        await _loadFavorites();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isFav ? 'Removed from favorites' : 'Saved to favorites')),
                        );
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: _selectedIndex == 0 ? Colors.green : Colors.blueGrey,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
        ],
      ),
    );
  }
}
