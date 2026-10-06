import 'package:flutter/material.dart';

import '../ui/theme.dart';

/// No Chrome/desktop o app aparece centralizado com cara de celular.
/// Em telas estreitas (celular de verdade ou emulador) não muda nada.
class PhoneFrame extends StatelessWidget {
  final Widget child;

  static const double _phoneWidth = 412;
  static const double _phoneMaxHeight = 900;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < 600) return child;

    final height = (media.size.height - 48).clamp(560.0, _phoneMaxHeight);
    // Material: dá estilo de texto ao fundo (fora dele o Flutter sublinha de amarelo).
    return Material(
      color: AppColors.bgBlack,
      child: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          Center(
            child: Container(
              width: _phoneWidth,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: const Color(0xFF2B3133), width: 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 60,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: MediaQuery(
                  data: media.copyWith(
                    size: Size(_phoneWidth - 20, height - 20),
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.7, -0.8),
          radius: 1.4,
          colors: [AppColors.orange.withValues(alpha: 0.35), AppColors.bgBlack],
        ),
      ),
      child: Align(
        alignment: const Alignment(-0.92, 0.9),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CheapEats', style: AppText.h3.copyWith(color: Colors.white)),
              Text(
                'O faro fino do delivery · Protótipo CP5',
                style: AppText.body2.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
