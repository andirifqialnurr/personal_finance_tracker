import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({
    super.key,
    required this.categories,
    required this.onChanged,
  });

  final List<Category> categories;
  final Future<List<Category>> Function(List<Category>) onChanged;

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  late List<Category> _categories = List.of(widget.categories);
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage categories'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _addCategory,
            tooltip: 'Add category',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FlowSpacing.md),
        children: [
          if (_isSaving) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: FlowSpacing.md),
          ],
          Text(
            'Archived categories stay available for old transactions.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: FlowSpacing.md),
          for (final category in _categories) ...[
            FlowCard(
              variant: FlowCardVariant.action,
              density: FlowCardDensity.standard,
              child: Row(
                children: [
                  FlowIconContainer(
                    icon: Icons.category_outlined,
                    variant: FlowIconContainerVariant.category,
                  ),
                  const SizedBox(width: FlowSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '${_typeLabel(category.transactionType)}${category.isArchived ? ' · Archived' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => _rename(category),
                    tooltip: 'Rename category',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: _isSaving
                        ? null
                        : () => _toggleArchive(category),
                    tooltip: category.isArchived
                        ? 'Restore category'
                        : 'Archive category',
                    icon: Icon(
                      category.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FlowSpacing.sm),
          ],
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    final category = await _showAddCategoryDialog();
    if (category == null) return;
    await _commit([..._categories, category]);
  }

  Future<Category?> _showAddCategoryDialog() async {
    return showDialog<Category>(
      context: context,
      builder: (context) => _AddCategoryDialog(nameError: _nameError),
    );
  }

  Future<void> _rename(Category category) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenameCategoryDialog(
        initialName: category.name,
        nameError: (name) => _nameError(name, ignoring: category),
      ),
    );
    if (name == null || name.isEmpty) return;
    await _update(category, name: name);
  }

  Future<void> _toggleArchive(Category category) =>
      _update(category, isArchived: !category.isArchived);

  Future<void> _update(
    Category category, {
    String? name,
    bool? isArchived,
  }) async {
    final index = _categories.indexWhere(
      (item) => _isSameCategory(item, category),
    );
    if (index == -1) return;
    final updated = Category(
      id: category.id,
      name: name ?? category.name,
      transactionType: category.transactionType,
      icon: category.icon,
      color: category.color,
      isDefault: category.isDefault,
      isArchived: isArchived ?? category.isArchived,
    );
    final categories = List<Category>.of(_categories);
    categories[index] = updated;
    await _commit(categories);
  }

  Future<void> _commit(List<Category> categories) async {
    setState(() {
      _isSaving = true;
    });
    try {
      final savedCategories = await widget.onChanged(
        List.unmodifiable(categories),
      );
      if (!mounted) return;
      setState(() {
        _categories = List.of(savedCategories);
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save categories.')),
      );
    }
  }

  String? _nameError(String name, {Category? ignoring}) {
    if (name.isEmpty) return 'Enter a category name.';
    final normalized = _normalizeName(name);
    for (final category in _categories) {
      if (ignoring != null && _isSameCategory(category, ignoring)) continue;
      if (_normalizeName(category.name) == normalized) {
        return 'A category with this name already exists.';
      }
    }
    return null;
  }

  static bool _isSameCategory(Category left, Category right) {
    if (left.id != null && right.id != null) return left.id == right.id;
    return identical(left, right);
  }

  static String _normalizeName(String value) => value.trim().toLowerCase();

  static String _defaultIcon(TransactionType type) => switch (type) {
    TransactionType.income => 'payments',
    TransactionType.expense => 'category',
    TransactionType.transfer => 'sync_alt',
  };

  static String _defaultColor(TransactionType type) => switch (type) {
    TransactionType.income => '#168C78',
    TransactionType.expense => '#C96B6B',
    TransactionType.transfer => '#5A6ACF',
  };

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
  };
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.nameError});

  final String? Function(String name) nameError;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _controller = TextEditingController();
  var _type = TransactionType.expense;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: FlowSpacing.md),
          FlowSegmentedControl(
            labels: const ['Expense', 'Income'],
            selectedIndex: _type == TransactionType.expense ? 0 : 1,
            onChanged: (index) {
              setState(() {
                _type = index == 0
                    ? TransactionType.expense
                    : TransactionType.income;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    final error = widget.nameError(name);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(
      context,
      Category(
        name: name,
        transactionType: _type,
        icon: _ManageCategoriesPageState._defaultIcon(_type),
        color: _ManageCategoriesPageState._defaultColor(_type),
      ),
    );
  }
}

class _RenameCategoryDialog extends StatefulWidget {
  const _RenameCategoryDialog({
    required this.initialName,
    required this.nameError,
  });

  final String initialName;
  final String? Function(String name) nameError;

  @override
  State<_RenameCategoryDialog> createState() => _RenameCategoryDialogState();
}

class _RenameCategoryDialogState extends State<_RenameCategoryDialog> {
  late final _controller = TextEditingController(text: widget.initialName);
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(errorText: _errorText),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    final error = widget.nameError(name);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(context, name);
  }
}
