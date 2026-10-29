import 'package:flutter/material.dart';

import '../providers/user_provider.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _favoriteController = TextEditingController();
  bool _controllersInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;
    final provider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.user.name);
    _emailController = TextEditingController(text: provider.user.email);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // 1. Validasi karakter berbahaya
    final dangerousPattern = RegExp(r'[<>]|script', caseSensitive: false);
    if (dangerousPattern.hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Nama mengandung karakter berbahaya / skrip!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ambil provider & messenger sebelum async gap
    final provider = Provider.of<UserProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    // 2. Cek email duplikat via SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final existingEmail = prefs.getString('user_email') ?? '';
    if (existingEmail.isNotEmpty && email == existingEmail) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Peringatan: Email ini sudah pernah Anda daftarkan!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 3. Simpan data
    final updatedUser = provider.user.copyWith(
      name: name,
      email: email,
      isLoggedIn: true,
    );

    await provider.updateUser(updatedUser);
    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Daftar Favorit / Hobi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _favoriteController,
                              decoration: const InputDecoration(
                                hintText: 'Tambah hobi baru...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (_favoriteController.text.trim().isNotEmpty) {
                                provider.addFavorite(
                                  _favoriteController.text.trim(),
                                );
                                _favoriteController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.favorites.isEmpty)
                        const Text(
                          'Belum ada favorit.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: provider.favorites.map((item) {
                            return Chip(
                              label: Text(item),
                              onDeleted: () => provider.removeFavorite(item),
                              deleteIconColor: Colors.red,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.amber[800]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan Keamanan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Data disimpan di SharedPreferences (plaintext). '
                                'Jangan simpan password atau data sensitif di sini. '
                                'Gunakan secure storage untuk data sensitif.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
