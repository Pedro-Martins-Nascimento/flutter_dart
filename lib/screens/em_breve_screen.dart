import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmBreveScreen extends StatelessWidget {
  final String titulo;

  const EmBreveScreen({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: const Center(
        child: Text(
          'Em construção',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
