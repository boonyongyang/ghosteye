import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/script_provider.dart';
import '../providers/session_controls_provider.dart';
import 'script_line_widget.dart';
import 'typewriter_text.dart';

class ScriptScrollView extends ConsumerStatefulWidget {
  const ScriptScrollView({super.key});

  @override
  ConsumerState<ScriptScrollView> createState() => _ScriptScrollViewState();
}

class _ScriptScrollViewState extends ConsumerState<ScriptScrollView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      scriptProvider.select((state) => state.scrollTick),
      (previous, next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) {
            return;
          }
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
        });
      },
    );

    final scriptState = ref.watch(scriptProvider);
    final captureEnabled = ref.watch(captureEnabledProvider);
    final hasLiveResponse = scriptState.liveResponse.isNotEmpty;
    final itemCount =
        scriptState.entries.length + (hasLiveResponse ? 1 : 0) + 1;

    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < scriptState.entries.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ScriptLineWidget(entry: scriptState.entries[index]),
          );
        }

        if (hasLiveResponse && index == scriptState.entries.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: TypewriterText(targetText: scriptState.liveResponse),
          );
        }

        if (scriptState.errorMessage case final message?) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.redAccent),
            ),
          );
        }

        if (scriptState.entries.isEmpty && !hasLiveResponse) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              captureEnabled
                  ? 'Scene is live — screenplay will appear here.'
                  : 'Capture paused.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          );
        }

        return const SizedBox(height: 40);
      },
    );
  }
}
