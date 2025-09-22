import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'journal_providers.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _notesCtrl = TextEditingController();
  double _hunger = 3, _energy = 3;
  final Set<String> _sensations = {};
  File? _photo;

  final _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _save() async {
    final repo = ref.read(journalRepoProvider);
    await repo.createEntry(
      occurredAt: DateTime.now(),
      sensations: _sensations.toList(),
      hungerSatiety: _hunger.round(),
      energy: _energy.round(),
      contextText: _notesCtrl.text.trim(),
      photoFile: _photo,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entrada guardada')));
      setState(() {
        _notesCtrl.clear();
        _hunger = 3;
        _energy = 3;
        _sensations.clear();
        _photo = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(journalStreamProvider);
    final dateFormatter = DateFormat('dd/MM HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Diario de sensaciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        label: const Text('Guardar'),
        icon: const Icon(Icons.check),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Formulario ---
          const Text(
            'Como te sientes?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children:
                [
                      'satisfecho',
                      'energizado',
                      'con_culpa',
                      'ansioso',
                      'tranquilo',
                    ]
                    .map(
                      (s) => FilterChip(
                        selected: _sensations.contains(s),
                        onSelected: (v) {
                          setState(
                            () =>
                                v ? _sensations.add(s) : _sensations.remove(s),
                          );
                        },
                        label: Text(s),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          Text('Hambre/Saciedad: ${_hunger.round()}'),
          Slider(
            value: _hunger,
            min: 1,
            max: 5,
            divisions: 4,
            label: _hunger.round().toString(),
            onChanged: (v) => setState(() => _hunger = v),
          ),
          const SizedBox(height: 8),
          Text('Energia: ${_energy.round()}'),
          Slider(
            value: _energy,
            min: 1,
            max: 5,
            divisions: 4,
            label: _energy.round().toString(),
            onChanged: (v) => setState(() => _energy = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cuentanos el contexto (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                label: const Text('Agregar foto'),
                icon: const Icon(Icons.photo_camera),
              ),
              const SizedBox(width: 12),
              if (_photo != null)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          const Divider(height: 32),

          // --- Lista de entradas ---
          const Text(
            'Tus ultimas entradas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          entriesAsync.when(
            data: (items) => Column(
              children: items.map((e) {
                final formattedDate = dateFormatter.format(
                  e.occurredAt.toLocal(),
                );
                final subtitle =
                    '$formattedDate - Energia: ${e.energy} - Hambre/Saciedad: ${e.hungerSatiety}\n${e.contextText}';
                final titleText = e.sensations.isEmpty
                    ? 'Sin sensaciones registradas'
                    : e.sensations.join(' | ');
                return ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: Text(titleText),
                  subtitle: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: e.photoUrl != null ? const Icon(Icons.image) : null,
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }
}
