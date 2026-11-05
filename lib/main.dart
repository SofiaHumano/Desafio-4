import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tarea {
  final String titulo;
  final bool completada;
  final String prioridad; // 'alta', 'media' o 'baja'

  const Tarea({
    required this.titulo,
    this.completada = false,
    this.prioridad = 'media',
  });

  Tarea copyWith({bool? completada}) => Tarea(
        titulo: titulo,
        completada: completada ?? this.completada,
        prioridad: prioridad,
      );
}

class TasksState {
  final List<Tarea> tareas;
  const TasksState({this.tareas = const []});

  int get pendientes => tareas.where((t) => !t.completada).length;
  int get completadas => tareas.length - pendientes;
}

class TasksNotifier extends Notifier<TasksState> {
  @override
  TasksState build() => const TasksState();

  void agregar(String titulo, String prioridad) {
    state = TasksState(
      tareas: [...state.tareas, Tarea(titulo: titulo, prioridad: prioridad)],
    );
  }

  void eliminar(int indice) {
    final nuevas = [...state.tareas];
    nuevas.removeAt(indice);
    state = TasksState(tareas: nuevas);
  }

  void toggleCompletada(int indice) {
    final nuevas = [...state.tareas];
    nuevas[indice] =
        nuevas[indice].copyWith(completada: !nuevas[indice].completada);
    state = TasksState(tareas: nuevas);
  }
}

final tasksProvider =
    NotifierProvider<TasksNotifier, TasksState>(TasksNotifier.new);

void main() {
  runApp(
    // ProviderScope va POR ENCIMA de todo: sin esto Riverpod no funciona
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _seccion = 0;
  final _titulos = ['Inicio', 'Tareas', 'Perfil'];
  final _pantallas = const [InicioScreen(), TareasScreen(), PerfilScreen()];

  void _irA(int i) {
    setState(() => _seccion = i);
    Navigator.pop(context); // cerrar el drawer
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pendientes = ref.watch(tasksProvider).pendientes;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_seccion]),
        backgroundColor: cs.primaryContainer,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: cs.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.onPrimary,
                    child: Icon(Icons.person, size: 36, color: cs.primary),
                  ),
                  const SizedBox(height: 10),
                  Text('Sofía Humano', // ← tu nombre
                      style: TextStyle(color: cs.onPrimary, fontSize: 16)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              selected: _seccion == 0,
              onTap: () => _irA(0),
            ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Tareas'),
              selected: _seccion == 1,
              onTap: () => _irA(1),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              selected: _seccion == 2,
              onTap: () => _irA(2),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Mis Tareas',
                  applicationVersion: '1.0',
                );
              },
            ),
          ],
        ),
      ),

      body: _pantallas[_seccion],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _seccion,
        onDestinationSelected: (i) => setState(() => _seccion = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$pendientes'),
              isLabelVisible: pendientes > 0,
              child: const Icon(Icons.task_outlined),
            ),
            selectedIcon: const Icon(Icons.task_alt),
            label: 'Tareas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    // ref.watch: lee el estado Y redibuja esta pantalla cuando cambia
    final state = ref.watch(tasksProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '${state.pendientes}',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                Text(
                  state.pendientes == 1
                      ? 'tarea pendiente'
                      : 'tareas pendientes',
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Completadas: ${state.completadas}'),
          Text('Total: ${state.tareas.length}'),
        ],
      ),
    );
  }
}

class TareasScreen extends ConsumerStatefulWidget {
  const TareasScreen({super.key});

  @override
  ConsumerState<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends ConsumerState<TareasScreen> {
  final _ctrl = TextEditingController();
  String _prioridad = 'media'; 

  @override
  void dispose() {
    _ctrl.dispose(); 
    super.dispose();
  }

  void _agregar() {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return; // no agregar tareas vacías
    // ref.read: ejecuta una ACCIÓN (no redibuja por sí solo)
    ref.read(tasksProvider.notifier).agregar(texto, _prioridad);
    _ctrl.clear();
  }

  Color _color(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _agregar(),
                  decoration: const InputDecoration(
                    labelText: 'Nueva tarea',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _prioridad,
                items: const [
                  DropdownMenuItem(value: 'alta', child: Text('Alta')),
                  DropdownMenuItem(value: 'media', child: Text('Media')),
                  DropdownMenuItem(value: 'baja', child: Text('Baja')),
                ],
                onChanged: (v) => setState(() => _prioridad = v!),
              ),
              IconButton.filled(
                onPressed: _agregar,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),

        Expanded(
          child: state.tareas.isEmpty
              ? const Center(child: Text('No hay tareas. ¡Agregá una!'))
              : ListView.builder(
                  itemCount: state.tareas.length,
                  itemBuilder: (context, i) {
                    final t = state.tareas[i];
                    return ListTile(
                      leading: Checkbox(
                        value: t.completada,
                        onChanged: (_) => ref
                            .read(tasksProvider.notifier)
                            .toggleCompletada(i),
                      ),
                      title: Text(
                        t.titulo,
                        style: TextStyle(
                          decoration: t.completada
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text('Prioridad: ${t.prioridad}'),
                      // Puntito de color según prioridad
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 14, color: _color(t.prioridad)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                ref.read(tasksProvider.notifier).eliminar(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.person, size: 56, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          const Text('Sofía Humano',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}