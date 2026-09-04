# Diário de Bordo

Registro de commits, PRs e merges do projeto, como prova de andamento para a
N1/N2 (ver `docs/correcao-de-provas-docs.md`, seção "Para fechar a N1").

Cada entrada é por data, com o que foi feito, por quem/com quem e as
PRs/commits envolvidos.

---

## 2026-09-04

**Contexto:** havia 3 PRs abertas (`#3` banco de questões, `#4` tela de
login, `#5` main-shell) esperando merge na `main`, que já tinha a PR `#1`
(fluxo de provas) e a `#6` (docs) mergeadas.

**O que foi feito:**

- Conta do GitHub CLI trocada para `Pedro-Martins-Nascimento` (owner do
  repositório) antes de mexer nas PRs.
- **PR #4 (Tela-Login):** mergeada. Descoberto durante o processo que a PR
  estava aberta contra a branch `feature/tela-provas` como base, e não
  contra `main` — então esse merge só atualizou `feature/tela-provas`, sem
  efeito direto na `main`. Isso também fez a PR `#5` fechar sozinha (o
  GitHub fecha automaticamente uma PR quando a branch base dela é
  deletada).
- **PR #5 (main-shell):** recriada como **PR #7**, agora com base correta
  (`main`). Como a branch `feature/main-shell` já continha os commits do
  login (era uma branch empilhada sobre `feature/tela-login`), o conteúdo
  do login acabou entrando junto por aqui mesmo sem a PR #4 ter ido pra
  `main`.
- Resolvido conflito real de merge entre `feature/main-shell` e `main` em
  `lib/main.dart` e `lib/router/app_router.dart` (histórico divergente:
  `feature/main-shell` foi criada antes do squash-merge da PR #1). Mantida
  a versão mais completa (login + shell com bottom nav + rotas de provas).
- Atualizado o smoke test (`test/widget_test.dart`), que checava a tela de
  Criar Prova como tela inicial — agora aponta para a tela de Login,
  seguindo o TODO que já estava anotado no próprio teste.
- **PR #3 (banco de questões):** conflito grande resolvido em 5 arquivos
  (`app_router.dart`, `criar_prova_screen.dart`, `gerar_provas_screen.dart`,
  `preview_layout_screen.dart`, `pdf_service.dart`). A branch `feature/
  questoes` continha uma evolução das telas de prova já integrada ao
  modelo `Questao` real (com alternativas e gabarito), então essa versão
  foi mantida no lugar da versão mock que estava na `main`.
- Validado com `flutter analyze` (sem apontamentos) e `flutter test` (smoke
  test passando) depois de cada merge de conflito, antes de subir.
- Descoberto que o repositório usa uma **ruleset** (não é branch protection
  clássica) na `main` exigindo **1 review aprovada** e permitindo **apenas
  squash merge** — nem privilégio de admin (`--admin`) contorna isso.
  Review solicitada para `KelciaAntiuk` nas PRs `#7` e `#3`.

**Pendente:**

- Aguardando aprovação de `KelciaAntiuk` para mergear `#7` (main-shell +
  login) e `#3` (banco de questões) — nessa ordem, via squash.
- Depois que `#7` for mergeada, revalidar `#3` contra a `main` atualizada
  (pode surgir conflito novo por causa do `app_router.dart`, já que os
  dois PRs mexem nesse arquivo).
- PR #4 ficou registrada como "merged" no GitHub, mas apontando pra
  `feature/tela-provas` em vez de `main` — sem efeito prático (o conteúdo
  dela chega na `main` de qualquer forma via a `#7`), mas vale registrar
  pra não confundir quem olhar o histórico depois.
