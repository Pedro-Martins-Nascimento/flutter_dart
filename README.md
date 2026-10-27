# Correção de Provas

Aplicativo Flutter de uso exclusivo do professor para **gerar provas embaralhadas por aluno e corrigi-las pela câmera**, a partir de um QR code impresso em cada versão.

Projeto acadêmico desenvolvido em grupo. Esta é a entrega **N2**: o app agora tem **login real (Firebase Authentication)** e **guarda os dados no Cloud Firestore**, separados por professor. Turmas, alunos, matérias, questões, provas e correções continuam salvos depois que o app é fechado.

---

## Vídeo de demonstração

**[▶ Assistir à demonstração](https://youtu.be/ahXdrW6j_UQ)** (gravado na N1)

---

## Objetivo

Eliminar o trabalho manual de corrigir provas de múltipla escolha e, de quebra, dificultar a cola em sala.

O professor monta a prova a partir de um banco de questões, o app gera várias versões embaralhadas — cada uma com um QR code próprio ligado ao seu gabarito —, exporta tudo em PDF pronto para impressão e, depois da aplicação, corrige as folhas apontando a câmera do celular.

O aluno não usa o aplicativo: existe apenas como cadastro dentro de uma turma.

---

## Escopo delimitado

### Dentro da N2

- Login com e-mail e senha ou com conta Google (Firebase Authentication).
- Dados salvos no Cloud Firestore, em `professores/{uid}/...`: cada professor só enxerga os próprios dados.
- Fluxo completo de montagem da prova: turmas → alunos → banco de questões → criar prova → gerar versões → exportar PDF.
- Correção: leitura do QR pela câmera, revisão das alternativas pelo professor, nota calculada e salva.
- Resultado por aluno, estatística da turma, boletim em PDF e relatório de notas em Excel.
- Layout responsivo: navegação inferior no celular e menu lateral em telas largas.

### Fora da N2

- Reconhecimento real das marcações da folha (OMR). Hoje as alternativas aparecem **pré-preenchidas por sorteio** e o professor confere cada uma antes de confirmar (veja RF14).
- Recuperação de senha: o botão "Esqueci minha senha" avisa que ainda não está disponível.
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

### O que a N2 entrega de cada requisito

Legenda: ✅ implementado · 🟡 parcial ou simulado · ⏳ previsto para as próximas entregas

| Cód. | Onde está | Status na N2 |
|---|---|---|
| RF01 | Login | ✅ e-mail e senha ou conta Google, pelo Firebase Authentication |
| RF02 | — | ✅ por construção: não existe fluxo de aluno no app |
| RF03 | Turmas | ✅ salvas no Firestore |
| RF04 | Turmas › Importar lista | 🟡 lê planilhas `.xlsx` (nome e matrícula); arquivos `.csv` ainda não são lidos |
| RF05 | Turmas › detalhe da turma | ✅ criar, editar e remover aluno |
| RF06 | Questões | ✅ matérias com criação e exclusão (a exclusão leva junto as questões da matéria) |
| RF07 | Questões › formulário | ✅ enunciado, alternativas, gabarito e exclusão |
| RF08 | Provas › Nova prova | ✅ também permite criar matéria e turma sem sair da tela |
| RF09 | Provas › Nova prova | ✅ mesma prova embaralhada ou conjuntos diferentes |
| RF10 | Provas › Gerar versões | ✅ QR próprio por versão, impresso no PDF |
| RF11 | Provas › Gerar versões | ✅ vínculo opcional com aluno da turma |
| RF12 | Provas › Gerar versões / Editor de layout | ✅ PDF gerado e enviado para impressão/compartilhamento |
| RF13 | Corrigir | ✅ câmera real lendo o QR da folha e localizando a versão |
| RF14 | Corrigir › versão | 🟡 **simulado**: as alternativas aparecem sorteadas, algumas como "não identificada"; a imagem da folha ainda não é processada |
| RF15 | Corrigir › versão | ✅ o professor confere e corrige cada alternativa antes de confirmar |
| RF16 | Corrigir › versão | ✅ nota de 0 a 10 calculada ao confirmar e salva no Firestore |
| RF17 | Corrigir › Resultado | ✅ por questão: alternativa marcada, gabarito e acerto |
| RF18 | Início › Estatística completa | ✅ acerto por matéria, questões com mais erros, média por prova e ranking de alunos |
| RF19 | Provas geradas | ✅ exporta as notas da prova em `.xlsx` |
| RNF07 | Firestore | ✅ regras em `firestore.rules`: cada professor só lê e grava em `professores/{uid}` |

---

## Telas principais

O app abre no **Login**. Depois de entrar, a navegação acontece por cinco abas (barra inferior no celular, menu lateral em telas largas). A aba **Corrigir** mostra um selo com a quantidade de versões geradas que ainda não foram corrigidas.

| Tela | Rota | O que faz |
|---|---|---|
| **Login** | `/login` | Entrar com e-mail e senha ou com conta Google |
| **Início** | `/inicio` | Painel do professor: corrigidas, pendentes e média; atalhos "Corrigir agora" e "Nova prova"; erro por matéria; últimas provas geradas |
| **Estatística completa** | `/inicio/estatistica` | Acerto por matéria, questões que mais derrubam a turma, média por prova e ranking de alunos |
| **Turmas** | `/turmas` | Lista das turmas |
| **Nova turma** | `/turmas/nova` | Cadastro de turma |
| **Detalhe da turma** | `/turmas/:id` | Alunos da turma: criar, editar, remover; editar ou excluir a turma |
| **Importar alunos** | `/turmas/:id/importar` | Importa nome e matrícula dos alunos de uma planilha `.xlsx` |
| **Questões** | `/questoes` | Banco de questões organizado por matéria |
| **Questões da matéria** | `/questoes/:materiaId` | Lista as questões daquela matéria |
| **Formulário de questão** | `/questoes/:materiaId/questao` | Enunciado, alternativas e marcação do gabarito |
| **Provas geradas** | `/provas-geradas` | Histórico das provas geradas; exporta as notas em Excel |
| **Nova prova** | `/criar-prova` | Nome, turma, matérias, seleção de questões, modo de geração e quantidade de versões |
| **Gerar versões** | `/gerar-provas` | Gera as versões embaralhadas, cada uma com seu QR; permite vincular aluno e exportar o PDF |
| **Editor de layout** | `/gerar-provas/preview` | Ajusta a aparência da prova impressa antes de exportar |
| **Corrigir** | `/corrigir` | Câmera com marcadores de canto e lanterna; lê o QR da folha e mostra quantas versões já foram corrigidas |
| **Corrigir versão** | `/corrigir/versao` | Revisão das alternativas da folha e confirmação da nota |
| **Resultado** | `/corrigir/resultado` | Nota, acertos e gabarito por questão; exporta o boletim em PDF |
| **Corrigidas** | `/corrigir/historico` | Lista das folhas já corrigidas; exporta os boletins de todos em PDF |

---

## Como rodar

### Pré-requisitos

- Flutter SDK 3.x com Dart SDK ^3.13.1 (`flutter --version`)
- Acesso ao projeto Firebase `correcao-provas-grupo` (veja [Configurar o Firebase](#configurar-o-firebase))
- Para rodar em Android: Android Studio com o SDK instalado
- Para rodar no navegador: Google Chrome

### Passos

```bash
git clone https://github.com/Pedro-Martins-Nascimento/flutter_dart.git
cd flutter_dart
flutter pub get
# gere os arquivos do Firebase antes de rodar (seção abaixo)
flutter run
```

Com mais de um dispositivo disponível, escolha o alvo:

```bash
flutter devices          # lista os dispositivos
flutter run -d chrome    # navegador
flutter run -d <id>      # emulador ou celular Android
```

O Firebase está configurado para **Android e Web**. No macOS, iOS, Windows e Linux o app não inicia.

A tela de Correção usa a câmera: no navegador, aceite a permissão quando o Chrome pedir; no Android, a permissão é solicitada na primeira abertura da tela.

### Verificar o projeto

```bash
flutter analyze
flutter test
```

Os testes não dependem do Firebase: usam `fake_cloud_firestore` e `firebase_auth_mocks`.

### Configurar o Firebase

O projeto usa `firebase_core`, `firebase_auth` e `cloud_firestore`. Os arquivos gerados pelo FlutterFire **não são versionados**:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Cada integrante gera esses arquivos na própria máquina. Não é necessário enviá-los por mensagem nem adicioná-los ao GitHub.

#### O que cada integrante precisa ter

- Flutter e Dart instalados e funcionando (`flutter doctor`)
- Uma conta Google com acesso ao projeto Firebase `correcao-provas-grupo`
- Firebase CLI instalado e autenticado
- FlutterFire CLI instalado
- Android Studio e Android SDK, caso vá compilar para Android
- Google Chrome, caso vá rodar na Web

#### Configuração inicial da máquina

```bash
firebase login
dart pub global activate flutterfire_cli
```

Depois de clonar o repositório, dentro da pasta do projeto, execute:

```bash
flutter pub get
flutterfire configure --project=correcao-provas-grupo --platforms=android,web
```

Durante o comando, confirme o aplicativo Android do projeto (`com.example.flutter_dart`). O FlutterFire gera localmente `lib/firebase_options.dart` e `android/app/google-services.json`; eles já estão protegidos pelo `.gitignore`.

Se alguém não tiver permissão no projeto Firebase, um integrante com acesso deve adicioná-lo no Firebase Console. Não compartilhe senhas, tokens ou chaves privadas; compartilhe apenas o nome do projeto e o acesso autorizado.

#### Login com Google no Android

No Android, o login com Google é feito pelo login nativo (`google_sign_in`), e o Firebase só aceita o app se a **SHA-1 da chave que assinou o APK** estiver cadastrada no projeto.

1. Veja a SHA-1 da sua chave de debug:

   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
   ```

2. Confira se ela já está cadastrada; se não estiver, cadastre:

   ```bash
   firebase apps:android:sha:list 1:184286969361:android:cde5f2bdad65325b303bb0 --project correcao-provas-grupo
   firebase apps:android:sha:create 1:184286969361:android:cde5f2bdad65325b303bb0 <SHA-1> --project correcao-provas-grupo
   ```

3. Gere de novo o `google-services.json` (com `flutterfire configure` ou baixando pelo Firebase Console) para ele trazer os clientes OAuth.

Na Web, o login com Google abre um popup. Se nada acontecer ao clicar, verifique se o navegador bloqueou o popup.

#### Regras do Firestore

As regras ficam em `firestore.rules` e são publicadas com:

```bash
firebase deploy --only firestore:rules --project correcao-provas-grupo
```

### Gerar o APK

```bash
flutter build apk --release
```

O arquivo sai em `build/app/outputs/flutter-apk/app-release.apk`. Para distribuir, renomeie com a versão do `pubspec.yaml` — por exemplo, `correcao-de-provas-v1.0.0.apk`.

O build de release ainda é assinado com a chave de debug de quem gerou o APK. Por isso, o login com Google só funciona se a SHA-1 dessa máquina estiver cadastrada no Firebase (veja acima).

Ao instalar uma versão nova por cima da antiga, o Android pode manter o app anterior porque o número da versão é o mesmo. Se isso acontecer, desinstale o app antes de instalar o APK novo, ou aumente o `version` no `pubspec.yaml`.

---

## Estrutura do projeto

```
lib/
├── main.dart                  # ponto de entrada: inicializa o Firebase e os repositórios
├── router/                    # rotas do go_router e shell das abas
├── theme/                     # cores, espaçamentos, tipografia e breakpoints
├── models/                    # turma, aluno, questão, versão de prova, correção, linha de nota
├── services/                  # autenticação, repositórios (Firestore e memória), mappers, PDF, Excel e estatística
├── widgets/                   # componentes reutilizáveis (cards, navegação)
└── screens/                   # uma pasta por área do app
    ├── auth/                  # login
    ├── inicio/                # painel inicial e estatística completa
    ├── turmas/                # turmas, alunos e importação
    ├── questoes/              # banco de questões
    ├── provas/                # criar, gerar, layout e histórico
    ├── corrigir/              # câmera, correção da versão, resultado e corrigidas
    └── shell/                 # casca com a navegação principal
test/                          # testes de repositórios, telas e serviços
firestore.rules                # regras de segurança do Firestore
docs/                          # documento do cliente, requisitos e protótipo
```

Cada repositório tem duas implementações: uma no **Firestore**, usada pelo app, e uma **em memória**, usada nos testes.

### Principais dependências

| Pacote | Para quê |
|---|---|
| `go_router` | navegação e rotas aninhadas |
| `provider` | injeção dos repositórios nas telas |
| `firebase_core` / `firebase_auth` / `cloud_firestore` | login e banco de dados |
| `google_sign_in` | login com Google nativo no Android |
| `pdf` / `printing` | montagem e exportação da prova e do boletim em PDF |
| `mobile_scanner` | leitura do QR code pela câmera |
| `file_picker` / `excel` | importação da lista de alunos e exportação das notas |
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
