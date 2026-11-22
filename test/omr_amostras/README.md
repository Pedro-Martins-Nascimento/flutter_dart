# Amostras do leitor (OMR)

- `gabarito_40_questoes.png`: gabarito em branco de uma prova de 40 questões
  (a cada 7, uma tem 4 alternativas; as demais, 5), gerado pelo `PdfService` e
  convertido em imagem a 100 dpi. O teste faz X nele e simula a foto. Se o
  layout do gabarito mudar em `LayoutFolha`, gere de novo.

- `fotos/`: fotos reais de gabaritos impressos e marcados à mão (tarefa 3 do
  backlog). Para cada foto `nome.jpg` (ou `.png`), crie `nome.json`:

  ```json
  {
    "alternativas": [5, 5, 4, 5],
    "marcadas": [0, 3, null, 1],
    "pagina": 0
  }
  ```

  `alternativas` é quantas bolinhas tem cada questão da prova inteira,
  `marcadas` é o que o aluno marcou de verdade nas questões dessa página
  (índice: 0 = A; `null` = em branco) e `pagina` é a página do gabarito
  (0 = primeira; pode omitir). Rode:

  ```bash
  flutter test test/leitor_omr_fotos_test.dart
  ```

  O teste imprime a taxa de acerto do leitor e lista as questões que ele leu
  errado.
