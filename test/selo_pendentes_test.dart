import 'package:flutter/material.dart';
import 'package:flutter_dart/services/pendentes.dart';
import 'package:flutter_dart/services/prova_repository.dart';
import 'package:flutter_dart/widgets/app_bottom_nav.dart';
import 'package:flutter_test/flutter_test.dart';

import 'correcao_fixtures.dart';

ProvaResumo prova(String id, int versoes) => ProvaResumo(
  id: id,
  nome: 'Prova $id',
  materia: 'Matemática',
  turma: null,
  criadoEm: DateTime(2026, 5, 10),
  totalVersoes: versoes,
);

void main() {
  group('contarPendentes', () {
    test('soma as versões das provas e desconta as já corrigidas', () {
      final pendentes = contarPendentes(
        [prova('a', 4), prova('b', 2)],
        [correcao('c1'), correcao('c2')],
      );

      expect(pendentes, 4);
    });

    test('sem provas ou sem correções', () {
      expect(contarPendentes(const [], const []), 0);
      expect(contarPendentes([prova('a', 3)], const []), 3);
    });

    test('nunca fica negativo', () {
      expect(
        contarPendentes([prova('a', 1)], [correcao('c1'), correcao('c2')]),
        0,
      );
    });
  });

  group('selo no menu', () {
    Widget menu(Widget filho) => MaterialApp(home: Scaffold(body: filho));

    testWidgets('barra inferior mostra a quantidade na aba Corrigir', (
      tester,
    ) async {
      await tester.pumpWidget(
        menu(
          AppBottomNav(indiceAtual: 0, aoTocar: (_) {}, selos: const {4: 7}),
        ),
      );

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('sem pendentes não mostra selo', (tester) async {
      await tester.pumpWidget(
        menu(
          AppBottomNav(indiceAtual: 0, aoTocar: (_) {}, selos: const {4: 0}),
        ),
      );

      expect(find.text('0'), findsNothing);
    });

    testWidgets('mais de 99 vira 99+', (tester) async {
      await tester.pumpWidget(
        menu(
          AppBottomNav(indiceAtual: 0, aoTocar: (_) {}, selos: const {4: 150}),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('menu lateral também mostra o selo', (tester) async {
      await tester.pumpWidget(
        menu(AppNavRail(indiceAtual: 0, aoTocar: (_) {}, selos: const {4: 3})),
      );

      expect(find.text('3'), findsOneWidget);
    });
  });
}
