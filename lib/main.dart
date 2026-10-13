

import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'folders_screen.dart';



void main() {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SweaterWeatherApp());

}



class SweaterWeatherApp extends StatelessWidget {

  const SweaterWeatherApp({super.key});



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Sweater Weather Guestbook',

      theme: ThemeData(

        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFF6EBDD),

        colorScheme: ColorScheme.fromSeed(

          seedColor: const Color(0xFFB86B42),

        ),

      ),

      home: const GuestbookScreen(),

    );

  }

}



class GuestbookScreen extends StatefulWidget {

  const GuestbookScreen({super.key});



  @override

  State<GuestbookScreen> createState() => _GuestbookScreenState();

}



class _GuestbookScreenState extends State<GuestbookScreen> {

  final DatabaseHelper database = DatabaseHelper();

  final nameController = TextEditingController();

  final ageController = TextEditingController();

  final formKey = GlobalKey<FormState>();



  List<Map<String, dynamic>> guests = [];

  int guestCount = 0;

  int? editingId;

  bool loading = true;

  bool saving = false;

  String? errorMessage;



  static const brown = Color(0xFF7B4935);

  static const cinnamon = Color(0xFFB86B42);



  @override

  void initState() {

    super.initState();

    initializeDatabase();

  }



  Future<void> initializeDatabase() async {

    try {

      await database.init();

      await refreshGuests();

    } catch (e) {

      if (!mounted) return;

      setState(() {

        loading = false;

        errorMessage = 'Could not open the database: $e';

      });

    }

  }



  Future<void> refreshGuests() async {

    if (!mounted) return;



    setState(() {

      loading = true;

      errorMessage = null;

    });



    try {

      final rows = await database.queryAllRows();

      final count = await database.queryRowCount();



      if (!mounted) return;

      setState(() {

        guests = rows;

        guestCount = count;

        loading = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        loading = false;

        errorMessage = 'Could not load guests: $e';

      });

    }

  }



  void showMessage(String message) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(message)),

    );

  }



  void cancelEdit() {

    setState(() {

      editingId = null;

      nameController.clear();

      ageController.clear();

      formKey.currentState?.reset();

    });

  }



  Future<void> saveGuest() async {

    if (saving || loading) return;

    if (!(formKey.currentState?.validate() ?? false)) return;



    final name = nameController.text.trim();

    final age = int.parse(ageController.text.trim());



    setState(() => saving = true);



    try {

      if (editingId == null) {

        await database.insert(name, age);

        if (mounted) showMessage('Guest added! 🍂');

      } else {

        final changed = await database.update(

          editingId!,

          name,

          age,

        );



        if (changed == 0) {

          throw Exception('Guest was not found');

        }



        if (mounted) showMessage('Guest updated!');

      }



      if (!mounted) return;

      cancelEdit();

      await refreshGuests();

    } catch (e) {

      if (mounted) showMessage('Save failed: $e');

    } finally {

      if (mounted) setState(() => saving = false);

    }

  }



  void editGuest(Map<String, dynamic> guest) {

    setState(() {

      editingId = guest[DatabaseHelper.columnId] as int;

      nameController.text =

          guest[DatabaseHelper.columnName] as String;

      ageController.text =

          (guest[DatabaseHelper.columnAge] as int).toString();

    });

  }



  Future<void> confirmDelete(Map<String, dynamic> guest) async {

    final id = guest[DatabaseHelper.columnId] as int;

    final name = guest[DatabaseHelper.columnName] as String;



    final confirmed = await showDialog<bool>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: const Text('Remove guest?'),

        content: Text('Remove $name from the guestbook?'),

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

      final deleted = await database.delete(id);



      if (deleted == 0) {

        throw Exception('Guest was not found');

      }



      if (!mounted) return;



      if (editingId == id) cancelEdit();



      showMessage('Guest removed');

      await refreshGuests();

    } catch (e) {

      if (mounted) showMessage('Delete failed: $e');

    }

  }



  @override

  void dispose() {

    nameController.dispose();

    ageController.dispose();

    database.close();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor: const Color(0xFFF6EBDD),

        foregroundColor: brown,

        title: const Text(

          '🍂 Sweater Weather',

          style: TextStyle(fontWeight: FontWeight.bold),

        ),
        actions: [
          IconButton(
            tooltip: 'Open Card Folders',
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FoldersScreen(),
                ),
              );
            },
          ),
        ],

      ),

      body: ListView(

        padding: const EdgeInsets.all(18),

        children: [

          const Text(

            'Fall Festival Guestbook ☕',

            style: TextStyle(

              color: brown,

              fontSize: 25,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 6),

          const Text(

            'Warm welcomes & cozy memories.',

            style: TextStyle(

              color: brown,

              fontSize: 15,

            ),

          ),

          const SizedBox(height: 20),



          // Guest counter

          Card(

            color: const Color(0xFFE8D3BD),

            child: Padding(

              padding: const EdgeInsets.all(20),

              child: Column(

                children: [

                  const Text('🧣 Guests Registered'),

                  Text(

                    '$guestCount',

                    style: const TextStyle(

                      color: brown,

                      fontSize: 42,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

          ),



          const SizedBox(height: 16),



          // Add and edit guest form

          Card(

            color: Colors.white,

            child: Padding(

              padding: const EdgeInsets.all(18),

              child: Form(

                key: formKey,

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    Text(

                      editingId == null

                          ? '🍁 Welcome a Guest'

                          : '✏️ Edit Guest #$editingId',

                      style: const TextStyle(

                        color: brown,

                        fontSize: 19,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    const SizedBox(height: 14),

                    TextFormField(

                      controller: nameController,

                      decoration: const InputDecoration(

                        labelText: 'Guest name',

                        border: OutlineInputBorder(),

                      ),

                      validator: (value) {

                        if (value == null ||

                            value.trim().isEmpty) {

                          return 'Please enter a name';

                        }

                        return null;

                      },

                    ),

                    const SizedBox(height: 12),

                    TextFormField(

                      controller: ageController,

                      keyboardType: TextInputType.number,

                      decoration: const InputDecoration(

                        labelText: 'Age',

                        border: OutlineInputBorder(),

                      ),

                      validator: (value) {

                        final age =

                            int.tryParse(value?.trim() ?? '');



                        if (age == null ||

                            age < 0 ||

                            age > 120) {

                          return 'Enter a whole-number age from 0 to 120';

                        }

                        return null;

                      },

                    ),

                    const SizedBox(height: 14),

                    FilledButton(

                      onPressed:

                          saving || loading ? null : saveGuest,

                      style: FilledButton.styleFrom(

                        backgroundColor: cinnamon,

                        padding: const EdgeInsets.all(14),

                      ),

                      child: Text(

                        saving

                            ? 'Saving...'

                            : editingId == null

                                ? 'Add Guest'

                                : 'Save Changes',

                      ),

                    ),

                    if (editingId != null)

                      TextButton(

                        onPressed: saving ? null : cancelEdit,

                        child: const Text('Cancel Edit'),

                      ),

                  ],

                ),

              ),

            ),

          ),



          const SizedBox(height: 20),



          // Saved guest list

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              const Text(

                'Our Cozy Guest List',

                style: TextStyle(

                  color: brown,

                  fontSize: 19,

                  fontWeight: FontWeight.bold,

                ),

              ),

              IconButton(

                tooltip: 'Refresh',

                onPressed:

                    loading || saving ? null : refreshGuests,

                icon: const Icon(Icons.refresh),

              ),

            ],

          ),



          if (loading)

            const Center(

              child: CircularProgressIndicator(),

            )

          else if (errorMessage != null)

            Text(

              errorMessage!,

              style: const TextStyle(color: Colors.red),

            )

          else if (guests.isEmpty)

            const Padding(

              padding: EdgeInsets.all(24),

              child: Center(

                child: Text(

                  'No guests yet. Be the first! 🍁',

                ),

              ),

            )

          else

            ...guests.map((guest) {

              final id =

                  guest[DatabaseHelper.columnId] as int;

              final name =

                  guest[DatabaseHelper.columnName] as String;

              final age =

                  guest[DatabaseHelper.columnAge] as int;



              return Card(

                color: const Color(0xFFFFFAF3),

                margin: const EdgeInsets.only(bottom: 10),

                child: ListTile(

                  leading: const CircleAvatar(

                    backgroundColor: Color(0xFFE8D3BD),

                    child: Text('🍂'),

                  ),

                  title: Text(

                    name,

                    style: const TextStyle(

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  subtitle: Text(

                    'Guest #$id  •  Age $age',

                  ),

                  trailing: Wrap(

                    spacing: 0,

                    children: [

                      IconButton(

                        tooltip: 'Edit',

                        icon: const Icon(

                          Icons.edit_outlined,

                        ),

                        onPressed: saving

                            ? null

                            : () => editGuest(guest),

                      ),

                      IconButton(

                        tooltip: 'Delete',

                        icon: const Icon(

                          Icons.delete_outline,

                        ),

                        onPressed: saving

                            ? null

                            : () => confirmDelete(guest),

                      ),

                    ],

                  ),

                ),

              );

            }),

        ],

      ),

    );

  }

}
