import 'package:flutter/material.dart';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _opponentController = TextEditingController();
  final _myScoreController = TextEditingController();
  final _opponentScoreController = TextEditingController();

  String? _selectedOpponent;

  // Mock list of players
  final List<String> _players = [
    'Thomas',
    'Lucas',
    'Maxime',
    'Antoine',
    'Nicolas',
    'Julien',
  ];

  @override
  void dispose() {
    _opponentController.dispose();
    _myScoreController.dispose();
    _opponentScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Match'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Détails de la rencontre',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF14241D),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF203229)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Adversaire',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: _players.map((player) {
                        return DropdownMenuItem(value: player, child: Text(player));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedOpponent = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un adversaire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Mon Score',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _myScoreController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: const InputDecoration(hintText: '0'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Requis';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Nombre valide requis';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 36),
                          child: Text(
                            '-',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Adversaire',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _opponentScoreController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: const InputDecoration(hintText: '0'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Requis';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Nombre valide requis';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          debugPrint(
                            'Match: Moi vs $_selectedOpponent, Score: ${_myScoreController.text}-${_opponentScoreController.text}',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Match enregistré avec succès !'),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Enregistrer le match'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
