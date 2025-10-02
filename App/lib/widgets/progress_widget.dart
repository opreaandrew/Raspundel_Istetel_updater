import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:lottie/lottie.dart';

enum ProgressState {
  idle,
  inProgress,
  completed,
  error
}

class ProgressWidget extends StatelessWidget {
  final String title;
  final double progress;
  final ProgressState state;
  final String? message;

  const ProgressWidget({
    Key? key,
    required this.title,
    this.progress = 0.0,
    this.state = ProgressState.idle,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (state == ProgressState.inProgress) ...[
          CircularPercentIndicator(
            radius: 30.0,
            lineWidth: 5.0,
            percent: progress,
            center: Text('${(progress * 100).toInt()}%'),
            progressColor: Theme.of(context).primaryColor,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ] else if (state == ProgressState.completed) ...[
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ] else if (state == ProgressState.error) ...[
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.red),
            ),
          ],
        ],
      ],
    );
  }
}