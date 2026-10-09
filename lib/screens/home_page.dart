import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentfix/writing/writing_cubit.dart';
import 'package:sentfix/writing/writing_task.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _input = TextEditingController();
  late final FocusNode _inputFocus = FocusNode(
    onKeyEvent: (node, event) {
      final enter =
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter;
      if (event is! KeyDownEvent || !enter) {
        return KeyEventResult.ignored;
      }
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      context.read<WritingCubit>().submit(_input.text);
      return KeyEventResult.handled;
    },
  );

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sentfix')),
      body: BlocBuilder<WritingCubit, WritingState>(
        builder: (context, state) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  if (state.models.length > 1)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            initialValue: state.model,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              for (final name in state.models)
                                DropdownMenuItem(
                                  value: name,
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: state.busy
                                ? null
                                : (value) {
                                    if (value != null) {
                                      context.read<WritingCubit>().selectModel(
                                        value,
                                      );
                                    }
                                  },
                          ),
                        ),
                      ),
                    ),
                  TextField(
                    controller: _input,
                    focusNode: _inputFocus,
                    minLines: 6,
                    maxLines: 12,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Sentence or paragraph',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SegmentedButton<WritingTask>(
                        showSelectedIcon: false,
                        segments: [
                          for (final task in WritingTask.values)
                            ButtonSegment(
                              value: task,
                              label: Text(task.shortLabel),
                            ),
                        ],
                        selected: {state.task},
                        onSelectionChanged: state.busy
                            ? null
                            : (selected) => context
                                  .read<WritingCubit>()
                                  .selectTask(selected.first),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Teach me'),
                          Switch(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            value: state.teach,
                            onChanged: state.busy
                                ? null
                                : context.read<WritingCubit>().setTeach,
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton.filled(
                        tooltip: 'Enter',
                        onPressed: state.busy
                            ? null
                            : () => context.read<WritingCubit>().submit(
                                _input.text,
                              ),
                        icon: state.busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.keyboard_return),
                      ),
                    ],
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(state.error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (state.history.isEmpty)
                    Text(
                      'Nothing yet.',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    )
                  else
                    for (final entry in state.history) ...[
                      _HistoryCard(entry: entry),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({required this.entry});

  final WritingEntry entry;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  Timer? _ticker;
  var _copied = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final scheme = Theme.of(context).colorScheme;
    final mode = entry.teach
        ? '${entry.task.label} · Teach me'
        : entry.task.label;
    final lifetime = context.read<WritingCubit>().historyLifetime;
    final remaining = entry.createdAt.add(lifetime).difference(DateTime.now());
    final left = remaining.isNegative ? Duration.zero : remaining;
    final minutes = left.inMinutes.remainder(60).toString();
    final seconds = left.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mode,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Original',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(entry.input, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 4, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Revised',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: scheme.primary),
                          ),
                        ),
                        IconButton(
                          tooltip: _copied ? 'Copied' : 'Copy',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: entry.output),
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() => _copied = true);
                            await Future<void>.delayed(
                              const Duration(seconds: 2),
                            );
                            if (mounted) {
                              setState(() => _copied = false);
                            }
                          },
                          icon: Icon(
                            _copied ? Icons.check : Icons.copy,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SelectableText(
                      entry.output,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: scheme.onSurface, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            if (entry.lesson != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lesson',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        entry.lesson!,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
