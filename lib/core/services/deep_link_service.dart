import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/delivery_platform.dart';

/// Abre o app de delivery escolhido. No protótipo abrimos o site oficial
/// (no celular o sistema oferece abrir o app instalado, se houver).
class DeepLinkService {
  DeepLinkService._();

  static Future<bool> openPlatform(DeliveryPlatform platform) async {
    final uri = Uri.parse(platform.webUrl);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    } catch (error) {
      debugPrint('[CheapEats] Não foi possível abrir ${platform.name}: $error');
      return false;
    }
  }
}
