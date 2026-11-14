import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/correcao.dart';
import '../../theme/app_theme.dart';
import '../../services/alunos_para_pdf.dart';
import '../../services/correcao_repository.dart';
import '../../services/localizar_versao.dart';
import '../../services/pendentes.dart';
import '../../services/prova_repository.dart';
import '../../services/qualidade_foto.dart';
import '../../services/turmas_repository.dart';
import '../../widgets/app_card.dart';

class CorrigirScreen extends StatefulWidget {
  final ProvaRepository provas;
  final CorrecaoRepository correcoes;

  const CorrigirScreen({
    super.key,
    required this.provas,
    required this.correcoes,
  });

  @override
  State<CorrigirScreen> createState() => _CorrigirScreenState();
}

/// O que o app sabe da folha que está na frente da câmera.
enum _SituacaoFolha { identificando, pronta, jaCorrigida, desconhecida }

class _FolhaEmFoco {
  final String qr;
  final _SituacaoFolha situacao;
  final VersaoEncontrada? encontrada;
  final String? alunoNome;

  const _FolhaEmFoco(this.qr, this.situacao, {this.encontrada, this.alunoNome});

  /// Nome do aluno, ou da prova quando a versão não tem aluno vinculado.
  String get titulo => alunoNome ?? encontrada?.prova.nome ?? 'Folha';

  String? get detalhe {
    final prova = encontrada?.prova;
    if (prova == null || alunoNome == null) return prova?.turma;
    return prova.turma == null ? prova.nome : '${prova.nome} · ${prova.turma}';
  }
}

bool get _verificaFoto =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

class _CorrigirScreenState extends State<CorrigirScreen> {
  static const _intervaloDeteccao = Duration(milliseconds: 500);
  static const _validadeFoto = Duration(milliseconds: 1500);

  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: _verificaFoto
        ? DetectionSpeed.normal
        : DetectionSpeed.noDuplicates,
    detectionTimeoutMs: _intervaloDeteccao.inMilliseconds,
    returnImage: _verificaFoto,
  );

  String? _qrEmFoco;
  _FolhaEmFoco? _folha;
  Uint8List? _ultimaFoto;
  DateTime? _vistaEm;
  bool _verificando = false;

  // Mesma conta do selo de pendentes da aba: versões geradas x correções salvas.
  List<ProvaResumo> _provas = const [];
  List<Correcao> _correcoes = const [];
  late final StreamSubscription<List<ProvaResumo>> _inscricaoProvas;
  late final StreamSubscription<List<Correcao>> _inscricaoCorrecoes;

  @override
  void initState() {
    super.initState();
    _inscricaoProvas = widget.provas.observar().listen(
      (provas) => setState(() => _provas = provas),
    );
    _inscricaoCorrecoes = widget.correcoes.observar().listen(
      (correcoes) => setState(() => _correcoes = correcoes),
    );
  }

  @override
  void dispose() {
    _inscricaoProvas.cancel();
    _inscricaoCorrecoes.cancel();
    _controller.dispose();
    super.dispose();
  }

  int get _totalFolhas => _provas.fold(0, (soma, p) => soma + p.totalVersoes);

  int get _corrigidas => _totalFolhas - contarPendentes(_provas, _correcoes);

  bool get _concluido => _totalFolhas > 0 && _corrigidas >= _totalFolhas;

  void _aoDetectar(BarcodeCapture captura) {
    for (final codigo in captura.barcodes) {
      final valor = codigo.rawValue;
      if (valor != null && valor.isNotEmpty) {
        _ultimaFoto = captura.image;
        _vistaEm = DateTime.now();
        if (valor != _qrEmFoco) {
          setState(() => _qrEmFoco = valor);
          _identificar(valor);
        }
        return;
      }
    }
  }

  /// Descobre de quem é a folha assim que o QR aparece, para o professor
  /// conferir o nome antes de capturar.
  Future<void> _identificar(String qr) async {
    setState(() => _folha = _FolhaEmFoco(qr, _SituacaoFolha.identificando));
    final folha = await _consultar(qr);
    if (!mounted || _qrEmFoco != qr) return;
    setState(() => _folha = folha);
  }

  Future<_FolhaEmFoco> _consultar(String qr) async {
    try {
      final encontrada = await localizarVersaoPorQr(widget.provas, qr);
      if (encontrada == null) {
        return _FolhaEmFoco(qr, _SituacaoFolha.desconhecida);
      }
      final jaCorrigida = await widget.correcoes.jaCorrigida(
        encontrada.prova.id,
        encontrada.versao.id,
      );
      return _FolhaEmFoco(
        qr,
        jaCorrigida ? _SituacaoFolha.jaCorrigida : _SituacaoFolha.pronta,
        encontrada: encontrada,
        alunoNome: _nomeDoAluno(encontrada),
      );
    } catch (_) {
      return _FolhaEmFoco(qr, _SituacaoFolha.desconhecida);
    }
  }

  String? _nomeDoAluno(VersaoEncontrada encontrada) {
    final alunoId = encontrada.versao.alunoId;
    if (alunoId == null) return null;
    final turmas = context.read<TurmasRepository>().turmas;
    for (final aluno in alunosDaTurma(encontrada.prova.turma, turmas)) {
      if (aluno.id == alunoId) return aluno.nome;
    }
    return null;
  }

  void _avisar(String mensagem, {SnackBarAction? acao}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem), action: acao));
  }

  SnackBarAction get _verCorrigidas => SnackBarAction(
    label: 'Ver',
    onPressed: () => context.push('/corrigir/historico'),
  );

  Future<void> _capturar() async {
    final qr = _qrEmFoco;
    if (qr == null || _verificando) return;

    if (_verificaFoto) {
      final vistaEm = _vistaEm;
      if (vistaEm == null ||
          DateTime.now().difference(vistaEm) > _validadeFoto) {
        setState(() => _qrEmFoco = null);
        _avisar(
          'Não estou vendo a folha. Aponte a câmera para ela e capture de novo.',
        );
        return;
      }
      final avaliacao = await _avaliarFoto(_ultimaFoto);
      if (!mounted) return;
      if (!avaliacao.aprovada) {
        await _pedirNovaFoto(avaliacao);
        _ultimaFoto = null;
        _vistaEm = null;
        return;
      }
    } else {
      _avisar(
        'Neste dispositivo a qualidade da foto não é verificada. Confira as respostas com atenção.',
      );
    }

    // Consulta de novo: outra correção pode ter sido salva nesse meio-tempo.
    final folha = await _consultar(qr);
    if (!mounted) return;
    setState(() => _folha = folha);

    switch (folha.situacao) {
      case _SituacaoFolha.desconhecida:
        _avisar('Esta folha não é de nenhuma prova gerada no app.');
      case _SituacaoFolha.jaCorrigida:
        _avisar(
          'A folha de ${folha.titulo} já foi corrigida.',
          acao: _verCorrigidas,
        );
      case _SituacaoFolha.identificando:
        break;
      case _SituacaoFolha.pronta:
        final encontrada = folha.encontrada!;
        context.push(
          '/corrigir/versao',
          extra: {'prova': encontrada.prova, 'versao': encontrada.versao},
        );
    }
  }

  Future<AvaliacaoFoto> _avaliarFoto(Uint8List? foto) async {
    if (foto == null) {
      return const AvaliacaoFoto([ProblemaFoto.naoAnalisada]);
    }
    setState(() => _verificando = true);
    try {
      return await compute(avaliarFotoCodificada, foto);
    } catch (_) {
      return const AvaliacaoFoto([ProblemaFoto.naoAnalisada]);
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _pedirNovaFoto(AvaliacaoFoto avaliacao) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.no_photography_outlined,
          color: AppColors.warning,
        ),
        title: const Text('Tire uma nova foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final problema in avaliacao.problemas)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(child: Text(problema.mensagem)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tirar nova foto'),
          ),
        ],
      ),
    );
  }

  Future<void> _alternarLanterna() async {
    try {
      await _controller.toggleTorch();
    } catch (_) {
      if (mounted) _avisar('Lanterna não disponível neste aparelho.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: _visor()),
            _barraInferior(),
          ],
        ),
      ),
    );
  }

  Widget _visor() {
    return ColoredBox(
      color: AppColors.neutral900,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _aoDetectar,
            placeholderBuilder: (context) => const _AvisoCamera(
              icone: Icons.photo_camera_outlined,
              mensagem: 'Abrindo a câmera…',
            ),
            errorBuilder: (context, erro) => _AvisoCamera(
              icone: Icons.no_photography_outlined,
              mensagem: _mensagemDeErro(erro),
            ),
          ),
          const _Escurecimento(),
          _sobreposicao(),
        ],
      ),
    );
  }

  String _mensagemDeErro(MobileScannerException erro) {
    return switch (erro.errorCode) {
      MobileScannerErrorCode.permissionDenied => 'Sem permissão de câmera.\nLibere o acesso nas configurações do aparelho.',
      MobileScannerErrorCode.unsupported =>
        'Este dispositivo não tem câmera disponível.',
      _ => 'Não foi possível abrir a câmera.',
    };
  }

  Widget _sobreposicao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s5,
            AppSpacing.s3,
            AppSpacing.s4,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Enquadre a folha nos 4 cantos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Ver corrigidas',
                icon: const Icon(
                  Icons.fact_check_outlined,
                  color: Colors.white,
                ),
                onPressed: () => context.push('/corrigir/historico'),
              ),
            ],
          ),
        ),
        Expanded(child: _alvo()),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s4,
            AppSpacing.s5,
            AppSpacing.s5,
          ),
          child: Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SeloFolha(_folha),
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: _controller,
                builder: (context, estado, _) {
                  if (estado.torchState == TorchState.unavailable) {
                    return const SizedBox.shrink();
                  }
                  final ligada = estado.torchState == TorchState.on;
                  return _BotaoLanterna(
                    ligada: ligada,
                    aoTocar: _alternarLanterna,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _alvo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        child: AspectRatio(
          aspectRatio: 0.7,
          child: Stack(
            clipBehavior: Clip.none,
            children: const [
              _Marcador(topo: true, esquerda: true),
              _Marcador(topo: true, esquerda: false),
              _Marcador(topo: false, esquerda: true),
              _Marcador(topo: false, esquerda: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barraInferior() {
    final situacao = _folha?.situacao;
    final habilitado =
        _qrEmFoco != null &&
        !_concluido &&
        !_verificando &&
        situacao == _SituacaoFolha.pronta;

    final rotulo = _concluido
        ? 'Tudo corrigido'
        : _verificando
        ? 'Verificando foto…'
        : switch (situacao) {
            null => 'Aponte para uma folha',
            _SituacaoFolha.identificando => 'Lendo a folha…',
            _SituacaoFolha.jaCorrigida => 'Folha já corrigida',
            _SituacaoFolha.desconhecida => 'Folha não reconhecida',
            _SituacaoFolha.pronta => 'Capturar folha',
          };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  disabledForegroundColor: Colors.white,
                ),
                onPressed: habilitado ? _capturar : null,
                child: Text(rotulo),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_corrigidas/$_totalFolhas',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const Text(
                'corrigidas',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Escurecimento extends StatelessWidget {
  const _Escurecimento();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.black54],
          stops: [0.0, 0.35, 1.0],
        ),
      ),
    );
  }
}

class _AvisoCamera extends StatelessWidget {
  final IconData icone;
  final String mensagem;

  const _AvisoCamera({required this.icone, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.neutral900,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 40, color: AppColors.neutral400),
              const SizedBox(height: AppSpacing.s4),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.neutral300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  static const _tamanho = 26.0;
  static const _recuo = -6.0;

  final bool topo;
  final bool esquerda;

  const _Marcador({required this.topo, required this.esquerda});

  @override
  Widget build(BuildContext context) {
    const lado = BorderSide(color: AppColors.accentLight, width: 4);

    return Positioned(
      top: topo ? _recuo : null,
      bottom: topo ? null : _recuo,
      left: esquerda ? _recuo : null,
      right: esquerda ? null : _recuo,
      child: Container(
        width: _tamanho,
        height: _tamanho,
        decoration: BoxDecoration(
          border: Border(
            top: topo ? lado : BorderSide.none,
            bottom: topo ? BorderSide.none : lado,
            left: esquerda ? lado : BorderSide.none,
            right: esquerda ? BorderSide.none : lado,
          ),
        ),
      ),
    );
  }
}

/// Pílula sobre a câmera dizendo de quem é a folha enquadrada.
class _SeloFolha extends StatelessWidget {
  final _FolhaEmFoco? folha;

  const _SeloFolha(this.folha);

  @override
  Widget build(BuildContext context) {
    final folha = this.folha;
    return switch (folha?.situacao) {
      null => const _Pilula(
        icone: Icons.radio_button_unchecked,
        texto: 'Procurando folha',
      ),
      _SituacaoFolha.identificando => const _Pilula(
        icone: Icons.more_horiz,
        texto: 'Lendo a folha…',
      ),
      _SituacaoFolha.desconhecida => const _Pilula(
        icone: Icons.warning_amber_rounded,
        corIcone: AppColors.warning,
        texto: 'Folha não reconhecida',
      ),
      _SituacaoFolha.jaCorrigida => _Pilula(
        icone: Icons.check_circle,
        corIcone: AppColors.neutral400,
        texto: folha!.titulo,
        detalhe: 'já corrigida',
      ),
      _SituacaoFolha.pronta => _Pilula(
        icone: Icons.check_circle,
        corIcone: AppColors.success,
        texto: folha!.titulo,
        detalhe: folha.detalhe,
        clara: true,
      ),
    };
  }
}

class _Pilula extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String texto;
  final String? detalhe;
  final bool clara;

  const _Pilula({
    required this.icone,
    required this.texto,
    this.corIcone = AppColors.neutral300,
    this.detalhe,
    this.clara = false,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = clara ? AppColors.text : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2 + 2,
      ),
      decoration: BoxDecoration(
        color: clara ? AppColors.surface : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: corIcone),
          const SizedBox(width: AppSpacing.s2),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: texto,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (detalhe != null)
                    TextSpan(
                      text: ' · $detalhe',
                      style: TextStyle(
                        color: clara
                            ? AppColors.neutral700
                            : AppColors.neutral300,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: corTexto),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoLanterna extends StatelessWidget {
  final bool ligada;
  final VoidCallback aoTocar;

  const _BotaoLanterna({required this.ligada, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ligada ? AppColors.surface : Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: ligada ? 'Desligar lanterna' : 'Ligar lanterna',
        onPressed: aoTocar,
        icon: Icon(
          ligada ? Icons.flashlight_on : Icons.flashlight_off_outlined,
          color: ligada ? AppColors.text : Colors.white,
        ),
      ),
    );
  }
}
