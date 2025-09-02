import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quotes_provider.dart';
import '../../widgets/quote_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});
  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuotesProvider>(context, listen: false).fetchQuotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final qp = Provider.of<QuotesProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Quotes')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F4EA), Color(0xFFD0F0C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: qp.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: qp.quotes.length,
          itemBuilder: (c, i) {
            final quote = qp.quotes[i];
            return QuoteCard(
              quote: quote,
              onFavorite: () async {
                final uid = Provider.of<AuthProvider>(context, listen: false)
                    .user
                    ?.uid;
                if (uid == null) return;

                final messenger = ScaffoldMessenger.of(context);
                await FirebaseService().saveFavoriteQuote(uid, quote);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Saved to favorites')),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
