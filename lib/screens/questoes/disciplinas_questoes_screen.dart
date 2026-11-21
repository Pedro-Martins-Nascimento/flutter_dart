import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/questoes_repository.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/cartoes_quadrados.dart' show pedirNome;

/// Id usado na rota para o grupo das questões antigas que ainda não estão em
/// nenhuma disciplina.
const semDisciplina = 'sem-disciplina';

/// Raiz do banco de questões: as disciplinas e, se houver, o grupo
/// "Sem disciplina". Cada uma abre as suas questões.
class DisciplinasQuestoesScreen extends StatelessWidget {
  const DisciplinasQuestoesScreen({super.key});

  Future<void> _novaDisciplina(BuildContext context) async {
    final nome = await pedirNome(
      context,
      titulo: 'Nova disciplina',
      rotulo: 'Nome da disciplina',
      dica: 'Matemática',
    );
    if (nome == null || !context.mounted) return;
    context.read<TurmasRepository>().criarDisciplina(nome);
  }

  static String _resumo(int total) => total == 0
      ? 'Nenhuma questão'
      : '$total ${total == 1 ? 'questão' : 'questões'}';

  @override
  Widget build(BuildContext context) {
    final disciplinas = context.watch<TurmasRepository>().disciplinas;
    final questoes = context.watch<QuestoesRepository>();
    final semDisciplinaTotal = questoes.questoesDaDisciplina(null).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              kicker: 'Banco de questões',
              titulo: 'Disciplinas',
              acao: AppNovoButton(
                rotulo: 'Nova disciplina',
                onPressed: () => _novaDisciplina(context),
              ),
            ),
            Expanded(
              child: AppMaxWidth(
                child: disciplinas.isEmpty && semDisciplinaTotal == 0
                    ? AppEstadoVazio(
                        icone: Icons.class_outlined,
                        titulo: 'Nenhuma disciplina ainda',
                        mensagem:
                            'Crie uma disciplina e, dentro dela, as questões.',
                        acao: AppNovoButton(
                          rotulo: 'Nova disciplina',
                          onPressed: () => _novaDisciplina(context),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s4,
                          AppSpacing.s2,
                          AppSpacing.s4,
                          AppSpacing.s8,
                        ),
                        children: [
                          AppListGroup(
                            children: [
                              for (final disciplina in disciplinas)
                                AppListRow(
                                  titulo: disciplina.nome,
                                  subtitulo: _resumo(
                                    questoes
                                        .questoesDaDisciplina(disciplina.id)
                                        .length,
                                  ),
                                  onTap: () => context.push(
                                    '/questoes/disciplina/${disciplina.id}',
                                  ),
                                ),
                              if (semDisciplinaTotal > 0)
                                AppListRow(
                                  titulo: 'Sem disciplina',
                                  subtitulo:
                                      '${_resumo(semDisciplinaTotal)} · '
                                      'mova para uma disciplina',
                                  onTap: () => context.push(
                                    '/questoes/disciplina/$semDisciplina',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
