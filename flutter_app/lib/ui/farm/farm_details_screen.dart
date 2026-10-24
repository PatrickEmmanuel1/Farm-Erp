import 'package:flutter/material.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/farm_repository.dart';
import '../../data/user_facing_error.dart';

class FarmDetailsScreen extends StatefulWidget {
  const FarmDetailsScreen({
    required this.farm,
    required this.repository,
    this.onSaved,
    super.key,
  });

  final FarmSummary farm;
  final FarmRepository repository;
  final ValueChanged<FarmSummary>? onSaved;

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sizeController;
  late final TextEditingController _countyController;
  late final TextEditingController _soilPhController;
  late final TextEditingController _soilHealthController;
  late String _unit;
  bool _saving = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.farm.name);
    _sizeController = TextEditingController(text: widget.farm.size.toString());
    _countyController = TextEditingController(text: widget.farm.county);
    _soilPhController = TextEditingController();
    _soilHealthController = TextEditingController();
    _unit = widget.farm.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _countyController.dispose();
    _soilPhController.dispose();
    _soilHealthController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    final size = num.parse(_sizeController.text.trim());
    final soilPh = num.tryParse(_soilPhController.text.trim());
    try {
      await widget.repository.updateFarmDetails(
        farmId: widget.farm.id,
        name: _nameController.text.trim(),
        totalSize: size.toDouble(),
        unit: _unit,
        county: _countyController.text.trim(),
        soilPh: soilPh?.toDouble(),
        soilHealth: _soilHealthController.text,
      );
      widget.onSaved?.call(
        FarmSummary(
          id: widget.farm.id,
          name: _nameController.text.trim(),
          county: _countyController.text.trim(),
          size: size.toDouble(),
          unit: _unit,
        ),
      );
      if (mounted) setState(() => _message = 'Farm details updated.');
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farm details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Farm name'),
              validator: (value) => (value?.trim().isNotEmpty ?? false)
                  ? null
                  : 'Enter the farm name.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countyController,
              decoration: const InputDecoration(labelText: 'County'),
              validator: (value) => (value?.trim().isNotEmpty ?? false)
                  ? null
                  : 'Enter the county.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sizeController,
                    decoration: const InputDecoration(labelText: 'Farm size'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final size = num.tryParse(value?.trim() ?? '');
                      return size == null || size <= 0
                          ? 'Enter a positive farm size.'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _unit,
                  items: const [
                    DropdownMenuItem(value: 'Acres', child: Text('Acres')),
                    DropdownMenuItem(
                        value: 'Hectares', child: Text('Hectares')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _unit = value);
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _soilPhController,
              decoration:
                  const InputDecoration(labelText: 'Soil pH (optional)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => (value?.trim().isEmpty ?? true) ||
                      num.tryParse(value!.trim()) != null
                  ? null
                  : 'Enter a valid soil pH.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _soilHealthController,
              decoration:
                  const InputDecoration(labelText: 'Soil health (optional)'),
              minLines: 3,
              maxLines: 5,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save farm details'),
            ),
          ],
        ),
      ),
    );
  }
}
