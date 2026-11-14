import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/conexao_service.dart';
import '../theme/app_theme.dart';

class AvisoSemConexao extends StatelessWidget {
  const AvisoSemConexao({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.select<ConexaoService, bool>((s) => s.offline);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1.0,
        child: child,
      ),
      child: offline
          ? Container(
              key: const ValueKey('aviso_sem_conexao_barra'),
              width: double.infinity,
              color: AppColors.neutral900,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: AppSpacing.s2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 16,
                    color: AppColors.surface,
                  ),
                  SizedBox(width: AppSpacing.s2),
                  Flexible(
                    child: Text(
                      'Sem conexão com a internet. Algumas ações podem não ser salvas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.surface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('aviso_sem_conexao_vazio')),
    );
  }
}

