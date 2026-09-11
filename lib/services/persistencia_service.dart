// lib/services/persistencia_service.dart
//
// Persistência local (N1 — ainda sem Firebase). Hoje o app inteiro vive
// em memória: matérias, questões, turmas, provas geradas e correções.
// Um F5 (ou fechar o app) apaga tudo. Este serviço guarda um snapshot de
// todo esse estado no armazenamento local do dispositivo/navegador
// (shared_preferences) e restaura na próxima abertura — sem mudar em
// nada a forma como as telas leem/escrevem esses dados hoje.
//
// Quando integrar o Firebase de verdade (N2), este arquivo é o ponto
// único a trocar — as telas continuam lendo os mesmos repositórios/listas.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/questao.dart';
import '../screens/turmas/criar_turma_screen.dart';
import 'correcoes_repository.dart';
import 'provas_repository.dart';

class PersistenciaService {
  PersistenciaService._();
  static final PersistenciaService instance = PersistenciaService._();

  static const _chave = 'correcao_provas_estado_v1';

  SharedPreferences? _prefs;

  // Lê o snapshot salvo (se existir) e substitui o conteúdo inicial dos
  // repositórios/listas mock por ele. Chamar uma vez, antes do runApp.
  Future<void> carregar() async {
    _prefs = await SharedPreferences.getInstance();
    final bruto = _prefs?.getString(_chave);
    if (bruto == null) return;

    try {
      final mapa = jsonDecode(bruto) as Map<String, dynamic>;

      final materias = (mapa['materias'] as List?)
          ?.map((m) => Materia.fromJson(m as Map<String, dynamic>))
          .toList();
      if (materias != null) {
        materiasMock
          ..clear()
          ..addAll(materias);
      }

      final questoes = (mapa['questoes'] as List?)
          ?.map((q) => Questao.fromJson(q as Map<String, dynamic>))
          .toList();
      if (questoes != null) {
        questoesMock
          ..clear()
          ..addAll(questoes);
      }

      final turmas = (mapa['turmas'] as List?)
          ?.map((t) => Turma.fromJson(t as Map<String, dynamic>))
          .toList();
      if (turmas != null) {
        turmasMock
          ..clear()
          ..addAll(turmas);
      }

      final provas = (mapa['provas'] as List?)
          ?.map((p) => ProvaGerada.fromJson(p as Map<String, dynamic>))
          .toList();
      if (provas != null) {
        ProvasRepository.instance.importarDePersistencia(provas);
      }

      final correcoes = (mapa['correcoes'] as List?)
          ?.map((c) => Correcao.fromJson(c as Map<String, dynamic>))
          .toList();
      if (correcoes != null) {
        CorrecoesRepository.instance.importarDePersistencia(correcoes);
      }
    } catch (_) {
      // Snapshot corrompido ou de um formato antigo — melhor ignorar e
      // seguir com os dados mock padrão do que travar o app no início.
    }
  }

  // Tira uma foto de tudo e salva. Chamado depois de qualquer mudança
  // (criar/editar/excluir matéria, questão, turma, prova ou correção).
  // Não precisa ser aguardado pelas telas — roda em segundo plano.
  void salvar() {
    final prefs = _prefs;
    if (prefs == null) return;

    final mapa = {
      'materias': materiasMock.map((m) => m.toJson()).toList(),
      'questoes': questoesMock.map((q) => q.toJson()).toList(),
      'turmas': turmasMock.map((t) => t.toJson()).toList(),
      'provas': ProvasRepository.instance
          .exportarParaPersistencia()
          .map((p) => p.toJson())
          .toList(),
      'correcoes': CorrecoesRepository.instance
          .exportarParaPersistencia()
          .map((c) => c.toJson())
          .toList(),
    };

    prefs.setString(_chave, jsonEncode(mapa));
  }
}
