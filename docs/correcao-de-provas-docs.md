# Correção de Provas - Notion Checklist

Baseado na página "Correção de Provas — Dashboard" do Notion.

## Visão geral

O app é um projeto Flutter de uso exclusivo do professor para:

- gerar provas embaralhadas por aluno;
- corrigir provas automaticamente via QR code + OMR;
- mostrar estatística por questão;
- exportar resultados e provas.

## Requisitos funcionais

### Autenticação

- RF01 - O professor deve conseguir se autenticar.
- RF02 - Alunos não possuem acesso ao sistema.

### Turmas e alunos

- RF03 - Criar e listar turmas.
- RF04 - Importar lista de alunos via CSV/Excel.
- RF05 - Cadastrar, editar e remover aluno manualmente.

### Banco de questões

- RF06 - Organizar questões por matéria.
- RF07 - Criar, editar e excluir questões.

### Geração de prova

- RF08 - Criar prova selecionando matéria(s) e questões do banco.
- RF09 - Escolher modo de geração da prova.
- RF10 - Gerar QR code único por versão.
- RF11 - Vincular opcionalmente uma versão a um aluno importado.
- RF12 - Exportar a prova em PDF pronta para impressão.

### Correção

- RF13 - Ler o QR code para identificar a versão/gabarito.
- RF14 - Reconhecer automaticamente as alternativas marcadas na folha.
- RF15 - Permitir revisão/correção manual quando a leitura falhar.
- RF16 - Calcular a nota automaticamente.

### Resultado

- RF17 - Mostrar, por questão, qual alternativa cada aluno marcou.
- RF18 - Gerar estatística agregada da turma por questão.
- RF19 - Exportar relatório de notas em Excel.

## Requisitos não funcionais

- RNF01 - Interface minimalista e com poucos toques.
- RNF02 - Leitura e cálculo praticamente instantâneos.
- RNF03 - Validar qualidade da imagem antes de processar.
- RNF04 - Layout impresso consistente, sem cortar questão.
- RNF05 - Sem suporte a modo offline.
- RNF06 - Funcionar em dispositivos Android comuns.
- RNF07 - Dados vinculados somente ao professor autenticado.

## Itens já declarados como fechados no Notion

- Cadastro de aluno é opcional.
- O QR code sempre aponta para a VersaoProva.
- O app não terá suporte offline.
- A folha de resposta precisa ter layout fixo.

## Tela prevista para a N1

Login -> Turmas -> Alunos da turma -> Banco de questões -> Criar prova -> Gerar provas -> Correção -> Resultado.

## Protótipo das telas

Arquivo local de protótipo: [docs/appProvas.html](docs/appProvas.html)

O protótipo serve como referência visual e de navegação para a N1. Ele ajuda a fechar a ordem do fluxo e o aspecto das telas antes da implementação real.

### Fluxo esperado no protótipo

- Login do professor;
- lista de turmas;
- alunos da turma;
- banco de questões;
- criar prova;
- gerar provas;
- correção;
- resultado.

### O que o protótipo não substitui

- autenticação real;
- banco de dados real;
- providers/estado;
- serviços de correção, PDF e exportação;
- integração com Firebase;
- APK final.

## Status inicial no repositório local

### Ainda ausente ou no template inicial

- app de entrada principal ainda está no template padrão do Flutter;
- rotas e telas do dashboard do Notion ainda não existem no código atual;
- modelos, providers e serviços de domínio ainda não foram criados.

### Ainda não verificável no código atual

- login do professor;
- turmas;
- alunos;
- banco de questões;
- fluxo de criar prova;
- geração de prova em PDF;
- correção por QR code/OMR;
- resultado e estatísticas.

## O que ainda falta para ficar completo

### Para fechar a N1

- estruturar o app em telas navegáveis de verdade no Flutter;
- substituir o template inicial por uma base com router e shell do app;
- criar os models de domínio;
- organizar as telas mock conforme o fluxo do protótipo;
- gerar o APK final da N1;
- preparar o zip do projeto completo;
- manter o diário de bordo com provas de commits, PRs e merge.

### Para a N2

- integrar Firebase Firestore;
- trocar mock por leitura e escrita reais;
- manter a mesma navegação da N1;
- atualizar o README para a versão 2;
- garantir PRs revisados e mergeados;
- provar a integração no APK.

### Para a N3

- concluir o fluxo inteiro de correção automatizada;
- implementar leitura de QR code;
- implementar OMR/revisão manual;
- calcular nota automaticamente;
- exportar Excel;
- fechar o relatório final e o pitch.

## Leitura consolidada do escopo

Depois de cruzar o Notion, o relato do cliente e o protótipo:

- o foco principal é correção automatizada de provas;
- a geração da prova é parte importante, mas serve ao fluxo de correção;
- estatística por questão é diferencial relevante;
- importação de alunos é opcional/suporte;
- o protótipo visual ajuda a N1, mas a entrega só conta quando estiver implementada, revisada e integrada ao APK.

## Análise das PRs

### PR #1 - fluxo de provas

Entrega descrita na PR:

- tela de criar prova;
- tela de gerar provas;
- preview em PDF;
- gerador de PDF real;
- go_router;
- MaterialApp.router;
- tema centralizado;
- widgets compartilhados para o fluxo.

Status no repositório atual:

- não implementado neste checkout local;
- o repo ainda está com o template padrão do Flutter em [lib/main.dart](../lib/main.dart);
- os arquivos citados pela PR ainda não existem aqui.

Ligação com Notion:

- cobre principalmente RF08, RF09, RF10, RF11, RF12 e parte do RNF04.

### PR #3 - banco de questões com alternativas e gabarito

Entrega descrita na PR:

- banco de questões com alternativas;
- gabarito;
- base para CRUD de questões.

Status no repositório atual:

- não implementado neste checkout local;
- não há modelagem, telas ou serviços de questões no código atual.

Ligação com Notion:

- cobre principalmente RF06 e RF07.

### PR #4 - tela de login

Entrega descrita na PR:

- tela de login;
- entrada do professor;
- navegação para o fluxo principal.

Status no repositório atual:

- não implementado neste checkout local;
- não há login, autenticação nem router configurado no código atual.

Ligação com Notion:

- cobre RF01 e apoia a restrição do RF02.

### PR #5 - main shell

Entrega descrita na PR:

- shell principal do app;
- bottom navigation;
- abas para Início, Turmas, Questões, Provas e Corrigir;
- rotas aninhadas para navegação principal.

Status no repositório atual:

- não implementado neste checkout local;
- a navegação ainda não foi migrada para shell principal;
- as telas de turmas, questões, provas e correção ainda não existem.

Ligação com Notion:

- cobre a navegação da N1 inteira e parte de RF03, RF06, RF08 e RF13.

### PR #2 - limpeza do template

Entrega descrita na PR:

- remoção dos comentários padrão do Flutter;
- ajuste de README e descrição do projeto.

Status no repositório atual:

- esta é a única linha já consolidada no histórico, junto com a atualização do README;
- não altera a estrutura funcional das telas.

Ligação com Notion:

- ajuda no setup/documentação da N1, mas não entrega RFs funcionais.

## Próximo passo sugerido

Converter este checklist em uma matriz de rastreabilidade, marcando para cada RF/RNF:

- o arquivo/feature responsável;
- o status atual;
- a PR ou commit que implementa cada parte.