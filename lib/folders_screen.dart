import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final DatabaseHelper database = DatabaseHelper();

  List<Map<String, dynamic>> folders = [];
  bool loading = true;
  String? errorMessage;

  static const brown = Color(0xFF7B4935);
  static const cinnamon = Color(0xFFB86B42);

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  Future<void> loadFolders() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await database.init();
      final rows = await database.getFoldersWithCounts();

      if (!mounted) return;

      setState(() {
        folders = rows;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not load folders: $e';
        loading = false;
      });
    }
  }

  Future<void> addFolder() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            hintText: 'Example: Favorite Cards',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();

              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || !mounted) return;

    try {
      await database.insertFolder(name);
      await loadFolders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create folder: $e'),
        ),
      );
    }
  }

  Future<void> deleteFolder(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
          'Delete "$name" and all cards inside it? '
          'This cannot be undone.',
        ),
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
      await database.deleteFolder(id);
      await loadFolders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete folder: $e'),
        ),
      );
    }
  }

  Future<void> openFolder(int id, String name) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardsScreen(
          folderId: id,
          folderName: name,
        ),
      ),
    );

    if (mounted) {
      await loadFolders();
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
        title: const Text('🍂 My Card Folders'),
        backgroundColor: const Color(0xFFF6EBDD),
        foregroundColor: brown,
        actions: [
          IconButton(
            onPressed: loadFolders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh folders',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: cinnamon,
        foregroundColor: Colors.white,
        onPressed: addFolder,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('New Folder'),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : folders.isEmpty
                  ? const Center(
                      child: Text(
                        'No folders yet.\nTap New Folder to begin!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: folders.length,

                      itemBuilder: (context, index) {
                        final folder = folders[index];

                        final id = folder['id'] as int;
                        final name = folder['name'] as String;
                        final count = folder['card_count'] as int;

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,

                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),

                            leading: const Icon(
                              Icons.folder,
                              color: cinnamon,
                              size: 36,
                            ),

                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: brown,
                                fontSize: 17,
                              ),
                            ),

                            subtitle: Text(
                              '$count ${count == 1 ? "card" : "cards"}',
                            ),

                            onTap: () => openFolder(id, name),

                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: brown,
                              ),
                              tooltip: 'Delete folder',
                              onPressed: () => deleteFolder(id, name),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
