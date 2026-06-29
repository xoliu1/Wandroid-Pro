import 'package:flutter/material.dart';
import 'dart:convert';

import '../core/diagnostics.dart';

class AIDiagnosticsPage extends StatefulWidget {
  const AIDiagnosticsPage({super.key});

  @override
  State<AIDiagnosticsPage> createState() => _AIDiagnosticsPageState();
}

class _AIDiagnosticsPageState extends State<AIDiagnosticsPage> {
  @override
  Widget build(BuildContext context) {
    final entries = AIDiagnosticsStore.instance.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnostics'),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '刷新',
          ),
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('AI Diagnostics JSON'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ')
                          .convert(AIDiagnosticsStore.instance.dumpJson()),
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.data_object_rounded),
            tooltip: '查看 JSON',
          ),
          IconButton(
            onPressed: () {
              AIDiagnosticsStore.instance.clear();
              setState(() {});
            },
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '清空',
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('暂无 AI 诊断记录'),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    AIDiagnosticsStore.instance.dumpText(),
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        dense: true,
                        title: Text('[${entry.level}] ${entry.scene}'),
                        subtitle: Text(
                          '${entry.timestamp.toIso8601String()}\n${entry.message}\n${entry.metadata}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
