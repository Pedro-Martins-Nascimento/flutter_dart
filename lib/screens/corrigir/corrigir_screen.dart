import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/app_theme.dart';
import '../turmas/criar_turma_screen.dart' show turmasMock;
import '../../widgets/app_card.dart';

int get _totalFolhas => turmasMock.first.qtdAlunos;

const int _jaCorrigidas = 12;

class CorrigirScreen extends StatefulWidget {
  const CorrigirScreen({super.key});

  @override
  State<CorrigirScreen> createState() => _CorrigirScreenState();
}

class _CorrigirScreenState extends State<CorrigirScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final _folhasLidas = <String>{};

  String? _qrEmFoco;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _corrigidas => _jaCorrigidas + _folhasLidas.length;

  bool get _concluido => _corrigidas >= _totalFolhas;

  void _aoDetectar(BarcodeCapture captura) {
    for (final codigo in captura.barcodes) {
      final valor = codigo.rawValue;
      if (valor != null && valor.isNotEmpty) {
        if (valor != _qrEmFoco) setState(() => _qrEmFoco = valor);
        return;
      }
    }
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _capturar() {
    final folha = _qrEmFoco;
    if (folha == null) return;

    if (!_folhasLidas.add(folha)) {
      _avisar('Folha $folha já tinha sido corrigida.');
      return;
    }

    setState(() {});
    _avisar('Folha $folha lida e corrigida.');
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
      MobileScannerErrorCode.permissionDenied =>
        'Sem permissão de câmera.\nLibere o acesso nas configurações.',
      MobileScannerErrorCode.unsupported =>
        'Este dispositivo não tem câmera disponível.',
      _ => 'Não foi possível abrir a câmera.',
    };
  }

  Widget _sobreposicao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s5,
            AppSpacing.s5,
            AppSpacing.s4,
          ),
          child: Text(
            'alinhe os 4 marcadores de canto da folha',
            style: TextStyle(fontSize: 14, color: Colors.white),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.s2,
                runSpacing: AppSpacing.s2,
                children: [
                  _Selo(
                    _qrEmFoco == null ? 'Procurando folha' : 'Folha detectada',
                    alerta: _qrEmFoco != null,
                  ),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, estado, _) {
                      if (estado.torchState == TorchState.unavailable) {
                        return const SizedBox.shrink();
                      }
                      final ligada = estado.torchState == TorchState.on;
                      return _Selo(
                        ligada ? 'Lanterna ligada' : 'Lanterna',
                        aoTocar: _alternarLanterna,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                'QR: ${_qrEmFoco ?? '—'}',
                style: const TextStyle(fontSize: 14, color: Colors.white),
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
    final habilitado = _qrEmFoco != null && !_concluido;

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
                  backgroundColor: AppColors.text,
                  disabledBackgroundColor: AppColors.text.withValues(
                    alpha: 0.35,
                  ),
                ),
                onPressed: habilitado ? _capturar : null,
                child: Text(
                  _concluido
                      ? 'Turma concluída'
                      : (_qrEmFoco == null
                            ? 'Aponte para o QR'
                            : 'Capturar folha'),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Text(
            '$_corrigidas de $_totalFolhas\ncorrigidas',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textMuted,
            ),
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

class _Selo extends StatelessWidget {
  final String texto;
  final bool alerta;
  final VoidCallback? aoTocar;

  const _Selo(this.texto, {this.alerta = false, this.aoTocar});

  @override
  Widget build(BuildContext context) {
    final conteudo = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      color: alerta ? AppColors.accentLight : AppColors.surface,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: alerta ? Colors.white : AppColors.text,
        ),
      ),
    );

    if (aoTocar == null) return conteudo;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: aoTocar, child: conteudo),
    );
  }
}
