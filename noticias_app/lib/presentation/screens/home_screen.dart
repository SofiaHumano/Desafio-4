import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../domain/entities/post.dart';
import 'detalle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Post>> _postsFuture;

  bool _buscando = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _postsFuture = _apiService.getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buscando
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar por título...',
                  border: InputBorder.none,
                ),
                onChanged: (texto) => setState(() => _query = texto),
              )
            : const Text('Noticias'),
        actions: [
          IconButton(
            icon: Icon(_buscando ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _buscando = !_buscando;
                _query = ''; 
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando noticias...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text('Error al cargar los datos'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _postsFuture = _apiService.getPosts();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data!
              .where((p) => p.title.toLowerCase().contains(_query.toLowerCase()))
              .toList();

          if (posts.isEmpty) {
            return const Center(child: Text('No se encontraron resultados'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${post.id}')),
                title: Text(post.title),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleScreen(post: post),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}