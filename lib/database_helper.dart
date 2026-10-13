
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// A folder that can contain multiple cards.
class Folder {
  final int? id;
  final String name;
  final String createdAt;

  const Folder({
    this.id,
    required this.name,
    required this.createdAt,
  });

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'created_at': createdAt,
      };
}

// A card belonging to one folder.
class CardRecord {
  final int? id;
  final String title;
  final String suit;
  final String notes;
  final String? imageRef;
  final int folderId;

  const CardRecord({
    this.id,
    required this.title,
    required this.suit,
    this.notes = '',
    this.imageRef,
    required this.folderId,
  });

  factory CardRecord.fromMap(Map<String, dynamic> map) {
    return CardRecord(
      id: map['id'] as int,
      title: map['title'] as String,
      suit: map['suit'] as String,
      notes: map['notes'] as String? ?? '',
      imageRef: map['image_ref'] as String?,
      folderId: map['folder_id'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'suit': suit,
        'notes': notes,
        'image_ref': imageRef,
        'folder_id': folderId,
      };
}

class DatabaseHelper {
  // Original Activity 08 guestbook table.
  static const tableName = 'my_table';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnAge = 'age';

  // New Activity 09 tables.
  static const foldersTable = 'folders';
  static const cardsTable = 'cards';

  late Database _db;

  Future<void> init() async {
    final databaseDirectory = await getDatabasesPath();

    // IMPORTANT: Keep the original database filename.
    final databasePath = join(databaseDirectory, 'MyDatabase.db');

    _db = await openDatabase(
      databasePath,
      version: 2,

      // Enable foreign keys on every database connection.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      // Used when the database does not exist yet.
      onCreate: (db, version) async {
        await _createGuestTable(db);
        await _createActivity09Tables(db);
      },

      // Used when upgrading an existing version 1 database.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createActivity09Tables(db);
        }
      },
    );
  }

  // Keep the original Activity 08 schema unchanged.
  Future<void> _createGuestTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');
  }

  // Create folders, cards, and the folder lookup index.
  Future<void> _createActivity09Tables(Database db) async {
    await db.execute('''
      CREATE TABLE $foldersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $cardsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        suit TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        image_ref TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id)
          REFERENCES $foldersTable(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_cards_folder_id
      ON $cardsTable(folder_id)
    ''');
  }

  // ==================================================
  // ACTIVITY 08: ORIGINAL GUESTBOOK METHODS
  // ==================================================

  Future<int> insert(String name, int age) async {
    return await _db.insert(tableName, {
      columnName: name,
      columnAge: age,
    });
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(
      tableName,
      orderBy: '$columnId ASC',
    );
  }

  Future<int> queryRowCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS count FROM $tableName',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(int id, String name, int age) async {
    return await _db.update(
      tableName,
      {
        columnName: name,
        columnAge: age,
      },
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // ==================================================
  // ACTIVITY 09: FOLDER METHODS
  // ==================================================

  // Create a folder.
  Future<int> insertFolder(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Folder name cannot be empty');
    }

    return await _db.insert(
      foldersTable,
      {
        'name': trimmedName,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Retrieve folders with the number of cards in each.
  Future<List<Map<String, dynamic>>> getFoldersWithCounts() async {
    return await _db.rawQuery('''
      SELECT
        f.id,
        f.name,
        f.created_at,
        COUNT(c.id) AS card_count
      FROM $foldersTable f
      LEFT JOIN $cardsTable c
        ON c.folder_id = f.id
      GROUP BY f.id, f.name, f.created_at
      ORDER BY f.id ASC
    ''');
  }

  // Retrieve typed folders.
  Future<List<Folder>> getFolders() async {
    final rows = await _db.query(
      foldersTable,
      orderBy: 'id ASC',
    );

    return rows.map(Folder.fromMap).toList();
  }

  // Rename a folder.
  Future<int> updateFolder(int id, String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Folder name cannot be empty');
    }

    return await _db.update(
      foldersTable,
      {'name': trimmedName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Deleting a folder automatically deletes its cards.
  Future<int> deleteFolder(int id) async {
    return await _db.delete(
      foldersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================================================
  // ACTIVITY 09: CARD METHODS
  // ==================================================

  // Add a card to a folder.
  Future<int> insertCard(CardRecord card) async {
    _validateCard(card);

    return await _db.insert(
      cardsTable,
      card.toMap(),
    );
  }

  // Retrieve all cards in one folder.
  Future<List<CardRecord>> getCardsByFolder(int folderId) async {
    final rows = await _db.query(
      cardsTable,
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'id ASC',
    );

    return rows.map(CardRecord.fromMap).toList();
  }

  // Retrieve one card.
  Future<CardRecord?> getCard(int id) async {
    final rows = await _db.query(
      cardsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return CardRecord.fromMap(rows.first);
  }

  // Edit a card.
  Future<int> updateCard(CardRecord card) async {
    _validateCard(card);

    if (card.id == null) {
      throw ArgumentError('Card ID is required for updates');
    }

    return await _db.update(
      cardsTable,
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  // Delete a card.
  Future<int> deleteCard(int id) async {
    return await _db.delete(
      cardsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Count cards in a folder.
  Future<int> getCardCount(int folderId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) FROM $cardsTable WHERE folder_id = ?',
      [folderId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Validate required card fields before saving.
  void _validateCard(CardRecord card) {
    if (card.title.trim().isEmpty) {
      throw ArgumentError('Card title cannot be empty');
    }

    if (card.suit.trim().isEmpty) {
      throw ArgumentError('Card suit cannot be empty');
    }

    if (card.folderId <= 0) {
      throw ArgumentError('A valid folder is required');
    }
  }

  // ==================================================
  // DATABASE CHECKS FOR TESTING
  // ==================================================

  // Verify the database version.
  Future<int> getDatabaseVersion() async {
    return await _db.getVersion();
  }

  // Verify foreign key enforcement is enabled.
  Future<bool> areForeignKeysEnabled() async {
    final result = await _db.rawQuery('PRAGMA foreign_keys');

    return Sqflite.firstIntValue(result) == 1;
  }

  // Close the database.
  Future<void> close() async {
    if (_db.isOpen) {
      await _db.close();
    }
  }
}
