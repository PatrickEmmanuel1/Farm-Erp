import 'package:flutter/material.dart';

import '../../data/model/farm_employee.dart';
import '../../data/model/employee.dart';
import '../../data/repository/employee_repository.dart';
import '../../data/user_facing_error.dart';

class _EmployeeFormInput {
  const _EmployeeFormInput({
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeNumber,
    required this.password,
  });

  final String role;
  final String name;
  final String email;
  final String phone;
  final String employeeNumber;
  final String password;
}

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({
    required this.farmId,
    required this.repository,
    required this.canManage,
    super.key,
  });

  final String farmId;
  final EmployeeRepository repository;
  final bool canManage;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<List<FarmEmployee>> _employees;
  bool _busy = false;
  String _roleFilter = 'Supervisor';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _employees = _loadEmployees();
  }

  Future<List<FarmEmployee>> _loadEmployees() {
    return widget.repository.getEmployeesForFarm(
      widget.farmId,
      includeAccountDetails: widget.canManage,
    );
  }

  Future<void> _refresh() async {
    setState(() => _employees = _loadEmployees());
    await _employees;
  }

  Future<void> _addEmployee() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final numberController = TextEditingController();
    final passwordController = TextEditingController();
    var role = _roleFilter;
    var showPassword = false;
    final input = await showDialog<_EmployeeFormInput>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, _) {
          return Dialog(
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: const Color(0xFFF7F5F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 24, color: Color(0xFF1E1E1E)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add $role',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                Text(
                                  'Register a new ${role.toLowerCase()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5F5F5F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCED0CF)),
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF6F6F5),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.contact_page_outlined,
                                  color: Color(0xFF6B6B6B)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pick from Contacts',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF2F2F2F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DialogField(
                        controller: nameController,
                        icon: Icons.person_outline_rounded,
                        hintText: 'Full Name *',
                        validator: (value) =>
                            (value?.trim().isNotEmpty ?? false)
                                ? null
                                : 'Enter the employee name.',
                      ),
                      const SizedBox(height: 12),
                      _DialogField(
                        controller: emailController,
                        icon: Icons.email_outlined,
                        hintText: 'Email Address *',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value?.contains('@') ?? false)
                            ? null
                            : 'Enter a valid email.',
                      ),
                      const SizedBox(height: 12),
                      _DialogField(
                        controller: phoneController,
                        icon: Icons.phone_outlined,
                        hintText: 'Phone Number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _DialogField(
                        controller: numberController,
                        icon: Icons.badge_outlined,
                        hintText: 'Employee Number (Optional)',
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Account Credentials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StatefulBuilder(
                        builder: (context, setPasswordState) => _DialogField(
                          controller: passwordController,
                          icon: Icons.lock_outline_rounded,
                          hintText: 'Initial Password *',
                          obscureText: !showPassword,
                          validator: (value) => (value?.length ?? 0) >= 6
                              ? null
                              : 'Password must be at least 6 characters.',
                          suffix: TextButton(
                            onPressed: () => setPasswordState(
                                () => showPassword = !showPassword),
                            child: Text(showPassword ? 'Hide' : 'Show'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1C7DD8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pop(
                              context,
                              _EmployeeFormInput(
                                role: role,
                                name: nameController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                                employeeNumber: numberController.text,
                                password: passwordController.text,
                              ),
                            );
                          },
                          icon: const Icon(Icons.save_alt_rounded),
                          label: Text(
                            'Save $role',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    numberController.dispose();
    passwordController.dispose();
    if (input == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final request = CreateEmployeeRequest(
        fullName: input.name,
        email: input.email,
        phoneNumber: input.phone,
        employeeNumber: input.employeeNumber,
        password: input.password,
        farmId: widget.farmId,
      );
      if (input.role == 'Supervisor') {
        await widget.repository.createSupervisor(request);
      } else {
        await widget.repository.createWorker(request);
      }
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${input.role} account created.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editEmployee(FarmEmployee employee) async {
    final formKey = GlobalKey<FormState>();
    final numberController =
        TextEditingController(text: employee.employeeNumber ?? '');
    final input = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${employee.role.toLowerCase()} employee number'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Employee number'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, numberController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    numberController.dispose();
    if (input == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.updateEmployeeNumber(
        employee,
        employeeNumber: input,
      );
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeEmployee(FarmEmployee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove employee?'),
        content: Text(
          'Remove ${employee.fullName} from this farm? Their account may still '
          'exist if it is not removed by the configured database procedure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.repository.removeEmployeeProfile(employee);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${employee.fullName} removed from the farm.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showEmployeeDetails(FarmEmployee employee) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(employee.fullName,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(employee.role),
              if (employee.email?.isNotEmpty == true) Text(employee.email!),
              if (employee.phoneNumber?.isNotEmpty == true)
                Text(employee.phoneNumber!),
              if (employee.employeeNumber?.isNotEmpty == true)
                Text('Employee #${employee.employeeNumber}'),
              if (widget.canManage) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          Navigator.pop(context);
                          _editEmployee(employee);
                        },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit employee number'),
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          Navigator.pop(context);
                          _removeEmployee(employee);
                        },
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Remove from farm'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchEmployees() async {
    final controller = TextEditingController(text: _query);
    try {
      final query = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Search employees'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Name or email'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Search'),
            ),
          ],
        ),
      );
      if (query != null && mounted) setState(() => _query = query);
    } finally {
      controller.dispose();
    }
  }

  Widget _roleTabs() {
    const roles = ['Supervisor', 'Worker'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (final role in roles)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => _roleFilter = role),
                child: Container(
                  decoration: BoxDecoration(
                    color: _roleFilter == role
                        ? const Color(0xFF1B5E20)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        role == 'Supervisor'
                            ? Icons.supervisor_account
                            : Icons.groups,
                        size: 16,
                        color: _roleFilter == role
                            ? Colors.white
                            : const Color(0xFF1B5E20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${role}s',
                        style: TextStyle(
                          color: _roleFilter == role
                              ? Colors.white
                              : const Color(0xFF1B5E20),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF277A3C), Color(0xFF1B5E20)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _roleFilter == 'Supervisor'
                    ? Icons.supervisor_account
                    : Icons.groups,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Total ${_roleFilter.toLowerCase()}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _employeeCard(FarmEmployee employee) {
    final initials = employee.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showEmployeeDetails(employee),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1A1D1A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          employee.email ?? 'No email registered',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6E7068),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Color(0xFF2E7D32), size: 7),
                        SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
              ),
              Row(
                children: [
                  Expanded(
                    child: _EmployeeDetail(
                      icon: Icons.work,
                      label: 'Employee #',
                      value: employee.employeeNumber,
                    ),
                  ),
                  Expanded(
                    child: _EmployeeDetail(
                      icon: Icons.call,
                      label: 'Contact',
                      value: employee.phoneNumber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF7F6F0);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1D1A)),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employees',
              style: TextStyle(
                color: Color(0xFF1A1D1A),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Manage supervisors and workers',
              style: TextStyle(
                color: Color(0xFF6E7068),
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'search') _searchEmployees();
              if (value == 'refresh') _refresh();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'search', child: Text('Search employees')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<FarmEmployee>>(
        future: _employees,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userFacingError(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          final allEmployees = snapshot.data ?? const [];
          final employees = allEmployees.where((employee) {
            final matchesRole =
                employee.role.toLowerCase() == _roleFilter.toLowerCase();
            final search = _query.trim().toLowerCase();
            final matchesQuery = search.isEmpty ||
                employee.fullName.toLowerCase().contains(search) ||
                (employee.email?.toLowerCase().contains(search) ?? false) ||
                (employee.employeeNumber?.toLowerCase().contains(search) ??
                    false);
            return matchesRole && matchesQuery;
          }).toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                _roleTabs(),
                const SizedBox(height: 14),
                _summaryCard(employees.length),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_roleFilter}s',
                        style: const TextStyle(
                          color: Color(0xFF1A1D1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.canManage)
                      FilledButton.icon(
                        onPressed: _busy ? null : _addEmployee,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(62, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Add',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (employees.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No ${_roleFilter.toLowerCase()}s registered yet.'
                            : 'No employees match your search.',
                        style: const TextStyle(
                          color: Color(0xFF6E7068),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else
                  for (final employee in employees) _employeeCard(employee),
                if (widget.canManage)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _addEmployee,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
                      side: const BorderSide(color: Color(0xFF81C784)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: Text(
                      'Add another ${_roleFilter.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmployeeDetail extends StatelessWidget {
  const _EmployeeDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6E7068),
                    fontSize: 9,
                  ),
                ),
                if (value?.trim().isNotEmpty == true)
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A1D1A),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'Not set',
                      style: TextStyle(
                        color: Color(0xFFE65100),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF7A7A7A)),
        prefixIcon: Icon(icon, color: const Color(0xFF6F6F6F)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF6F6F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCED0CF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCED0CF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1C7DD8), width: 1.5),
        ),
      ),
    );
  }
}
