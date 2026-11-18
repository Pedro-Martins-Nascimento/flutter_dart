# Formato do relatório de notas (.xlsx)

O sistema acadêmico da escola não informou um formato de importação. Este é o
formato definido pelo grupo (RF19). Se o sistema passar a exigir outro, o único
lugar a mudar é `lib/services/relatorio_excel.dart`.

## Como exportar

Provas geradas → menu `⋮` da prova → **Exportar notas (.xlsx)**.

O arquivo se chama `notas_<nome da prova>.xlsx` e traz as notas de **uma prova**.

## Estrutura

- Uma aba, chamada `Notas`.
- Linha 1: cabeçalho, em negrito.
- Uma linha por aluno, a partir da linha 2.

| Coluna | Cabeçalho | Tipo | Conteúdo |
| ------ | --------- | ---- | -------- |
| A | Matrícula | texto | Matrícula do aluno na turma. Fica como texto para não perder zeros à esquerda (`000123`). |
| B | Nome | texto | Nome do aluno. |
| C | Nota | número, formato `0.00` | Nota de 0 a 10, arredondada para 2 casas. |
| D | Data | data, formato `dd/mm/aaaa` | Dia em que a folha foi corrigida. |

## Quem aparece e em que ordem

1. Todos os alunos da turma da prova, na ordem da turma.
2. Depois, quem foi corrigido mas não está na turma (matrícula vazia).
3. Por último, folhas corrigidas sem aluno vinculado, com o nome
   `Sem aluno vinculado (<código da versão>)` e matrícula vazia.

## Regras

- **Aluno ainda não corrigido (ou que faltou):** `Nota` e `Data` ficam **vazias**.
  Não é gravado 0, porque 0 é uma nota válida.
- **Mais de uma correção do mesmo aluno na prova:** vale a mais recente.
- **Nota:** acertos ÷ total de questões × 10. Ex.: 1 de 3 questões = `3.33`.
- **Texto que começa com `=`** (nome ou matrícula) é gravado como texto e não é
  calculado como fórmula pelo Excel.
- Prova sem turma e sem correções não gera arquivo: o app avisa que não há
  nada para exportar.

## Exemplo

| Matrícula | Nome | Nota | Data |
| --------- | ---- | ---- | ---- |
| 2026001 | Ana Souza | 8.50 | 10/05/2026 |
| 2026002 | Bruno Lima | 6.00 | 11/05/2026 |
| 2026003 | Carla Dias | | |
