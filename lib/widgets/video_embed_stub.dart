import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget buildVideoEmbed({
  required BuildContext context,
  required String embedUrl,
  required String title,
  required String watchUrl,
}) {
  return Container(
    alignment: Alignment.center,
    color: const Color(0xffeef2ef),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: watchUrl));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Link copiado')));
            },
            icon: const Icon(Icons.link),
            label: const Text('Copiar link'),
          ),
        ],
      ),
    ),
  );
}
