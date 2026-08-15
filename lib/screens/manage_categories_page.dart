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
  final ValueChanged<List<Category>> onChanged;

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  late final List<Category> _categories = List.of(widget.categories);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage categories')),
      body: ListView(
        padding: const EdgeInsets.all(FlowSpacing.md),
        children: [
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_typeLabel(category.transactionType)}${category.isArchived ? ' · Archived' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _rename(category),
                    tooltip: 'Rename category',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () => _toggleArchive(category),
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

  Future<void> _rename(Category category) async {
    final controller = TextEditingController(text: category.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    _update(category, name: name);
  }

  void _toggleArchive(Category category) =>
      _update(category, isArchived: !category.isArchived);

  void _update(Category category, {String? name, bool? isArchived}) {
    final updated = Category(
      id: category.id,
      name: name ?? category.name,
      transactionType: category.transactionType,
      icon: category.icon,
      color: category.color,
      isDefault: category.isDefault,
      isArchived: isArchived ?? category.isArchived,
    );
    setState(() {
      _categories[_categories.indexOf(category)] = updated;
    });
    widget.onChanged(List.unmodifiable(_categories));
  }

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
  };
}
