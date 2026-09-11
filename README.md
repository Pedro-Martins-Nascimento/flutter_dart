# Correção de Provas

Aplicativo Flutter de uso exclusivo do professor para **gerar provas embaralhadas por aluno e corrigi-las pela câmera**, a partir de um QR code impresso em cada versão.

Projeto acadêmico desenvolvido em grupo. Esta é a entrega **N1**: telas principais navegáveis, construídas em Flutter/Dart e populadas com **dados fictícios (mock)**, sem banco de dados.

---

## Vídeo de demonstração

**[▶ Assistir à demonstração](ADICIONAR-LINK-AQUI)**

> Substituir pelo link do YouTube (não listado) ou do Drive com acesso liberado.

---

## Objetivo

Eliminar o trabalho manual de corrigir provas de múltipla escolha e, de quebra, dificultar a cola em sala.

O professor monta a prova a partir de um banco de questões, o app gera várias versões embaralhadas — cada uma com um QR code próprio ligado ao seu gabarito —, exporta tudo em PDF pronto para impressão e, depois da aplicação, corrige as folhas apontando a câmera do celular.

O aluno não usa o aplicativo: existe apenas como cadastro dentro de uma turma.

---

## Escopo delimitado

### Dentro da N1

- Telas principais construídas em Flutter/Dart e navegáveis por botão.
- Dados **mock**, mantidos em memória durante a execução.
- Fluxo completo de montagem da prova: turmas → alunos → banco de questões → criar prova → gerar versões → exportar PDF.
- Leitura de QR code pela câmera do dispositivo na tela de Correção.
- Layout responsivo: navegação inferior no celular e menu lateral em telas largas.

### Fora da N1

- Banco de dados e persistência entre execuções — os dados somem ao fechar o app.
- Autenticação real: a tela de Login valida os campos, mas não verifica credenciais.
- Reconhecimento das marcações da folha (OMR) e cálculo de nota a partir da imagem.
- Tela de resultado por aluno e exportação de relatório em Excel.
- Modo offline (o cliente já declarou que não haverá).

---

## Requisitos

### Funcionais

| Cód. | Requisito |
|---|---|
| RF01 | O professor deve conseguir se autenticar |
| RF02 | Alunos não possuem acesso ao sistema |
| RF03 | Criar e listar turmas |
| RF04 | Importar lista de alunos via CSV/Excel |
| RF05 | Cadastrar, editar e remover aluno manualmente |
| RF06 | Organizar questões por matéria |
| RF07 | Criar, editar e excluir questões |
| RF08 | Criar prova selecionando matéria(s) e questões do banco |
| RF09 | Escolher o modo de geração da prova |
| RF10 | Gerar QR code único por versão |
| RF11 | Vincular opcionalmente uma versão a um aluno importado |
| RF12 | Exportar a prova em PDF pronta para impressão |
| RF13 | Ler o QR code para identificar a versão/gabarito |
| RF14 | Reconhecer automaticamente as alternativas marcadas na folha |
| RF15 | Permitir revisão/correção manual quando a leitura falhar |
| RF16 | Calcular a nota automaticamente |
| RF17 | Mostrar, por questão, qual alternativa cada aluno marcou |
| RF18 | Gerar estatística agregada da turma por questão |
| RF19 | Exportar relatório de notas em Excel |

### Não funcionais

| Cód. | Requisito |
|---|---|
| RNF01 | Interface minimalista e com poucos toques |
| RNF02 | Leitura e cálculo praticamente instantâneos |
| RNF03 | Validar a qualidade da imagem antes de processar |
| RNF04 | Layout impresso consistente, sem cortar questão |
| RNF05 | Sem suporte a modo offline |
| RNF06 | Funcionar em dispositivos Android comuns |
| RNF07 | Dados vinculados somente ao professor autenticado |

### O que a N1 entrega de cada requisito

Legenda: ✅ implementado com mock · 🟡 parcial ou simulado · ⏳ previsto para as próximas entregas

| Cód. | Onde está | Status na N1 |
|---|---|---|
| RF01 | Login | 🟡 formulário com validação de e-mail e senha; não há verificação de credenciais |
| RF02 | — | ✅ por construção: não existe fluxo de aluno no app |
| RF03 | Turmas | ✅ |
| RF04 | Turmas › Importar lista | ✅ leitura real de arquivo `.xlsx` escolhido pelo usuário |
| RF05 | Turmas › detalhe da turma | ✅ criar, editar e remover aluno |
| RF06 | Questões | ✅ matérias com criação e exclusão |
| RF07 | Questões › formulário | ✅ enunciado, alternativas, gabarito e exclusão |
| RF08 | Provas › Nova prova | ✅ |
| RF09 | Provas › Nova prova | ✅ mesma prova embaralhada ou conjuntos diferentes |
| RF10 | Provas › Gerar versões | ✅ QR próprio por versão, impresso no PDF |
| RF11 | Provas › Gerar versões | ✅ vínculo opcional com aluno da turma |
| RF12 | Provas › Gerar versões / Editor de layout | ✅ PDF gerado e enviado para impressão/compartilhamento |
| RF13 | Corrigir | ✅ câmera real lendo o QR da folha |
| RF14 | Corrigir | 🟡 a folha é marcada como corrigida após a leitura do QR; a imagem ainda não é processada |
| RF15 | — | ⏳ |
| RF16 | Início | 🟡 média e contagem exibidas a partir de dados mock |
| RF17 | — | ⏳ |
| RF18 | Início | 🟡 erro por matéria da turma, com dados mock |
| RF19 | — | ⏳ |

---

## Telas principais

O app abre no **Login**. Depois de entrar, a navegação acontece por cinco abas (barra inferior no celular, menu lateral em telas largas).

| Tela | Rota | O que faz |
|---|---|---|
| **Login** | `/login` | E-mail e senha com validação; "Esqueci minha senha" avisa que ainda não está disponível |
| **Início** | `/inicio` | Painel do professor: corrigidas, pendentes e média; atalhos "Corrigir agora" e "Nova prova"; erro por matéria da turma; últimas provas geradas |
| **Turmas** | `/turmas` | Lista das turmas |
| **Nova turma** | `/turmas/nova` | Cadastro de turma |
| **Detalhe da turma** | `/turmas/:id` | Alunos da turma: criar, editar, remover; editar ou excluir a turma |
| **Importar alunos** | `/turmas/:id/importar` | Importa a lista de alunos de uma planilha escolhida pelo usuário |
| **Questões** | `/questoes` | Banco de questões organizado por matéria |
| **Questões da matéria** | `/questoes/:materiaId` | Lista as questões daquela matéria |
| **Formulário de questão** | `/questoes/:materiaId/questao` | Enunciado, alternativas e marcação do gabarito |
| **Nova prova** | `/criar-prova` | Nome, turma, matérias, seleção de questões, modo de geração e quantidade de versões |
| **Gerar versões** | `/gerar-provas` | Gera as versões embaralhadas, cada uma com seu QR; permite vincular aluno e exportar o PDF |
| **Editor de layout** | `/gerar-provas/preview` | Ajusta a aparência da prova impressa antes de exportar |
| **Provas geradas** | `/provas-geradas` | Histórico das provas já geradas na sessão |
| **Corrigir** | `/corrigir` | Câmera com marcadores de canto e lanterna; lê o QR da folha, avisa quando ela já foi corrigida e acompanha o progresso da turma |

---

## Como rodar

### Pré-requisitos

- Flutter SDK 3.x com Dart SDK ^3.13.1 (`flutter --version`)
- Para rodar em Android: Android Studio com o SDK instalado
- Para rodar no navegador: Google Chrome

### Passos

```bash
git clone https://github.com/Pedro-Martins-Nascimento/flutter_dart.git
cd flutter_dart
flutter pub get
flutter run
```

Com mais de um dispositivo disponível, escolha o alvo:

```bash
flutter devices          # lista os dispositivos
flutter run -d chrome    # navegador
flutter run -d <id>      # emulador ou celular Android
```

A tela de Correção usa a câmera: no navegador, aceite a permissão quando o Chrome pedir; no Android, a permissão é solicitada na primeira abertura da tela.

### Verificar o projeto

```bash
flutter analyze
```

### Gerar o APK

```bash
flutter build apk --release
```

O arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`. É necessário ter o SDK do Android configurado — confira com `flutter doctor`.

---

## Estrutura do projeto

```
lib/
├── main.dart                  # ponto de entrada (MaterialApp.router)
├── router/                    # rotas do go_router e shell das abas
├── theme/                     # cores, espaçamentos, tipografia e breakpoints
├── models/                    # modelos de domínio (questão, matéria)
├── services/                  # geração de PDF e repositório de provas em memória
├── widgets/                   # componentes reutilizáveis (cards, navegação)
└── screens/                   # uma pasta por área do app
    ├── auth/                  # login
    ├── inicio/                # painel inicial
    ├── turmas/                # turmas, alunos e importação
    ├── questoes/              # banco de questões
    ├── provas/                # criar, gerar, layout e histórico
    ├── corrigir/              # leitura da folha pela câmera
    └── shell/                 # casca com a navegação principal
docs/                          # documento do cliente, requisitos e protótipo
```

### Principais dependências

| Pacote | Para quê |
|---|---|
| `go_router` | navegação e rotas aninhadas |
| `pdf` / `printing` | montagem e exportação da prova em PDF |
| `mobile_scanner` | leitura do QR code pela câmera |
| `file_picker` / `excel` | importação da lista de alunos |
| `google_fonts` | tipografia da interface |

---

## Como o grupo trabalha

Nada vai direto para a `main`: cada tarefa vira uma branch, que só entra no projeto por **commit → Pull Request → code review de um colega → merge**.

### Equipe

| Aluno | GitHub |
|---|---|
| Kelcia Antiuk | [@KelciaAntiuk](https://github.com/KelciaAntiuk) |
| Pedro Martins do Nascimento | [@Pedro-Martins-Nascimento](https://github.com/Pedro-Martins-Nascimento) |
| Karen Amancio | [@KarenAmancio](https://github.com/KarenAmancio) |
| Letícia Parpineli | [@leparpineli](https://github.com/leparpineli) |
| Eduardo | [@Eduardoszz](https://github.com/Eduardoszz) |

---

## Documentação de apoio

- [docs/correcao-de-provas-docs.md](docs/correcao-de-provas-docs.md) — requisitos e decisões fechadas com o cliente
- [docs/Relato do cliente.pdf](docs/Relato%20do%20cliente.pdf) — pedido original do cliente
- [docs/Escopo do Projeto.pdf](docs/Escopo%20do%20Projeto.pdf) — escopo e critérios da disciplina
- [docs/appProvas.html](docs/appProvas.html) — protótipo navegável usado como referência visual
