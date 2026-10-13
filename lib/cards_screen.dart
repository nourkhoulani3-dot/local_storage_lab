import 'package:flutter/material.dart';
import 'database_helper.dart';

class CardsScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  const CardsScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final DatabaseHelper database = DatabaseHelper();

  List<CardRecord> cards = [];
  bool loading = true;
  String? errorMessage;

  static const brown = Color(0xFF7B4935);
  static const cinnamon = Color(0xFFB86B42);

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  Future<void> loadCards() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await database.init();
      final result = await database.getCardsByFolder(widget.folderId);

      if (!mounted) return;
      setState(() {
        cards = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'Could not load cards: $e';
      });
    }
  }

  String suitSymbol(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
        return '♥';
      case 'diamonds':
        return '♦';
      case 'clubs':
        return '♣';
      case 'spades':
        return '♠';
      default:
        return '🃏';
    }
  }

  Future<void> showCardForm({CardRecord? existing}) async {
    final titleController = TextEditingController(
      text: existing?.title ?? '',
    );
    final notesController = TextEditingController(
      text: existing?.notes ?? '',
    );
    final imageController = TextEditingController(
      text: existing?.imageRef ?? '',
    );

    String selectedSuit = existing?.suit ?? 'Hearts';
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Card' : 'Edit Card',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Card title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a card title'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSuit,
                        decoration: const InputDecoration(
                          labelText: 'Suit',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Hearts', 'Diamonds', 'Clubs', 'Spades']
                            .map(
                              (suit) => DropdownMenuItem(
                                value: suit,
                                child: Text(
                                  '${suitSymbol(suit)} $suit',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedSuit = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Image reference (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final card = CardRecord(
        id: existing?.id,
        title: titleController.text.trim(),
        suit: selectedSuit,
        notes: notesController.text.trim(),
        imageRef: imageController.text.trim().isEmpty
            ? null
            : imageController.text.trim(),
        folderId: widget.folderId,
      );

      try {
        if (existing == null) {
          await database.insertCard(card);
        } else {
          await database.updateCard(card);
        }

        await loadCards();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save card: $e')),
          );
        }
      }
    }

    titleController.dispose();
    notesController.dispose();
    imageController.dispose();
  }

  Future<void> deleteCard(CardRecord card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Card?'),
        content: Text('Delete "${card.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await database.deleteCard(card.id!);
      await loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete card: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EBDD),
      appBar: AppBar(
        title: Text(widget.folderName),
        backgroundColor: const Color(0xFFF6EBDD),
        foregroundColor: brown,
        actions: [
          IconButton(
            onPressed: loadCards,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCardForm(),
        backgroundColor: cinnamon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : cards.isEmpty
                  ? const Center(
                      child: Text(
                        'No cards in this folder yet.\nTap Add Card!',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];

                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFFE8D3BD),
                              child: Text(
                                suitSymbol(card.suit),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            title: Text(
                              card.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${card.suit}\n'
                              '${card.notes.isEmpty ? "No notes" : card.notes}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit card',
                                  onPressed: () =>
                                      showCardForm(existing: card),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete card',
                                  onPressed: () => deleteCard(card),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
