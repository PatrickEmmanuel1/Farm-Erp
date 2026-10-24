import 'package:flutter/material.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/farm_repository.dart';
import '../../data/user_facing_error.dart';

class CreateFarmScreen extends StatefulWidget {
  const CreateFarmScreen({
    required this.farmRepository,
    required this.user,
    required this.onFarmCreated,
    required this.onSignOut,
    super.key,
  });

  final FarmRepository farmRepository;
  final FarmUser user;
  final ValueChanged<FarmSummary> onFarmCreated;
  final Future<void> Function() onSignOut;

  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countyController = TextEditingController();
  final _subCountyController = TextEditingController();
  final _sizeController = TextEditingController();
  String _unit = 'Acres';
  bool _busy = false;
  String? _error;

  Future<void> _signOut() async {
    try {
      await widget.onSignOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countyController.dispose();
    _subCountyController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _createFarm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final farm = await widget.farmRepository.createFarm(
        accountId: widget.user.id,
        name: _nameController.text,
        county: _countyController.text,
        subCounty: _subCountyController.text,
        size: double.parse(_sizeController.text.trim()),
        unit: _unit,
      );
      if (mounted) widget.onFarmCreated(farm);
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateSize(String? value) {
    final size = double.tryParse(value?.trim() ?? '');
    if (size == null || size < 1 || size > 10000) {
      return 'Enter a farm size between 1 and 10,000 $_unit.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your farm'),
        actions: [
          TextButton(onPressed: _signOut, child: const Text('Sign out')),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome, ${widget.user.fullName}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('Add your farm details to continue.'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Farm name'),
                      validator: (value) => (value?.trim().isNotEmpty ?? false)
                          ? null
                          : 'Enter your farm name.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _countyController,
                      decoration: const InputDecoration(labelText: 'County'),
                      validator: (value) => (value?.trim().isNotEmpty ?? false)
                          ? null
                          : 'Enter your county.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subCountyController,
                      decoration: const InputDecoration(
                        labelText: 'Sub-county (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sizeController,
                            decoration:
                                const InputDecoration(labelText: 'Farm size'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _validateSize,
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _unit,
                          items: const [
                            DropdownMenuItem(
                                value: 'Acres', child: Text('Acres')),
                            DropdownMenuItem(
                              value: 'Hectares',
                              child: Text('Hectares'),
                            ),
                          ],
                          onChanged: _busy
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _unit = value);
                                  }
                                },
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _createFarm,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create farm'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
