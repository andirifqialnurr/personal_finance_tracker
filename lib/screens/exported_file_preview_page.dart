import 'dart:io';

import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_file_access.dart';

class ExportedFilePreviewPage extends StatefulWidget {
  const ExportedFilePreviewPage({super.key, required this.path});

  final String path;

  static Future<void> open(BuildContext context, String path) async {
    final lowerPath = path.toLowerCase();
    if (!lowerPath.endsWith('.csv') && !lowerPath.endsWith('.json')) {
      await FlowFileAccess.open(path);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExportedFilePreviewPage(path: path),
      ),
    );
  }

  @override
  State<ExportedFilePreviewPage> createState() =>
      _ExportedFilePreviewPageState();
}

class _ExportedFilePreviewPageState extends State<ExportedFilePreviewPage> {
  late final Future<String> _content = File(widget.path).readAsString();

  @override
  Widget build(BuildContext context) {
    final fileName = widget.path.replaceAll('\\', '/').split('/').last;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: FlowControlSize.minTouchTarget,
        title: Text(
          'Exported file',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 15),
        ),
      ),
      body: FutureBuilder<String>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(FlowSpacing.md),
              child: FlowEmptyState(
                icon: Icons.file_open_outlined,
                title: 'Could not open file',
                message: '${snapshot.error}',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              FlowSpacing.md,
              FlowSpacing.xxs,
              FlowSpacing.md,
              FlowSpacing.md,
            ),
            children: [
              Text(fileName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: FlowSpacing.gapTight),
              SelectableText(
                widget.path,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: FlowSpacing.gapBlock),
              FlowCard(
                density: FlowCardDensity.standard,
                child: SelectableText(
                  snapshot.data ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
