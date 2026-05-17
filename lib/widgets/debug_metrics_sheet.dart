import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inference_pipeline_metrics.dart';
import '../providers/camera_provider.dart';
import '../providers/gemma_provider.dart';
import '../providers/inference_pipeline_metrics_provider.dart';
import '../providers/inference_provider.dart';

class DebugMetricsSheet extends ConsumerWidget {
  const DebugMetricsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraSession = ref.watch(cameraProvider).valueOrNull;
    final gemmaState = ref.watch(gemmaProvider).valueOrNull;
    final metrics = ref.watch(inferencePipelineMetricsProvider);
    final inferenceStatus = ref.watch(inferenceStatusProvider);

    final rows = <_MetricRow>[
      _MetricRow(
        label: 'Sampler',
        value: cameraSession == null
            ? 'camera off'
            : '${cameraSession.sampleInterval.inMilliseconds} ms',
      ),
      _MetricRow(
        label: 'Preprocessor',
        value:
            '${metrics.settings.backend.name.toUpperCase()} ${metrics.settings.maxDimension}px Q${metrics.settings.jpegQuality}',
      ),
      if (gemmaState?.activeBackend case final backend?)
        _MetricRow(
          label: 'Model backend',
          value: gemmaState!.usedFallback
              ? '${backend.name.toUpperCase()} (fallback)'
              : backend.name.toUpperCase(),
          warning: gemmaState.usedFallback,
        ),
      if (_ms('Frame copy', metrics.frameCopy) case final r?) r,
      if (_ms('Preprocessing', metrics.preprocessing) case final r?) r,
      if (_ms('Model input', metrics.modelInput) case final r?) r,
      if (_ms('First token', metrics.firstToken) case final r?) r,
      if (_ms('Full response', metrics.fullResponse) case final r?) r,
      if (inferenceStatus.lastInferenceDuration case final d?)
        _MetricRow(
          label: 'Last inference',
          value: '${d.inMilliseconds} ms',
        ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1018),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Text(
                    'Pipeline Diagnostics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: Text(
                      'DEBUG',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Median latencies over the last sampling window.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                    ),
              ),
              const SizedBox(height: 16),
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white38,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        row.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: row.warning
                                  ? const Color(0xFFFFA726)
                                  : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _MetricRow? _ms(String label, DurationMetricSnapshot metric) {
    final median = metric.median;
    if (median == null) return null;
    return _MetricRow(label: label, value: '${median.inMilliseconds} ms med');
  }
}

class _MetricRow {
  const _MetricRow({
    required this.label,
    required this.value,
    this.warning = false,
  });
  final String label;
  final String value;
  final bool warning;
}
