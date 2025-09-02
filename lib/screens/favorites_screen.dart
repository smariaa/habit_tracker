import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../models/quote.dart';
import '../../widgets/quote_card.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context).user?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Login required')));

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Quotes')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F4EA), Color(0xFFD0F0C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<List<Quote>>(
          stream: FirebaseService().favoriteQuotesStream(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = snap.data ?? [];
            if (list.isEmpty) return const Center(child: Text('No favorites yet'));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: list.map((q) {
                return QuoteCard(
                  quote: q,
                  isFavorite: true,
                  onFavorite: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await FirebaseService().removeFavoriteQuote(uid, q.id);
                    messenger.showSnackBar(const SnackBar(content: Text('Removed')));
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
