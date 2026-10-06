import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/services/address_controller.dart';
import '../core/services/location_service.dart';
import '../data/catalog.dart';
import '../data/mock_addresses.dart';
import '../ui/theme.dart';

/// Escolha do endereço de entrega (abre ao tocar no endereço do topo da Home).
/// Ao escolher, o topo da Home e os mapas passam a usar o novo endereço.
class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _search = TextEditingController();
  bool _locating = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DeliveryAddress> get _filtered {
    final query = Catalog.normalize(_search.text);
    if (query.isEmpty) return mockAddresses;
    return mockAddresses
        .where((a) => Catalog.normalize('${a.label} ${a.street} ${a.district}').contains(query))
        .toList();
  }

  void _select(DeliveryAddress address) {
    AppServices.address.select(address);
    Navigator.of(context).pop();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final address = await AppServices.location.currentAddress();
      if (!mounted) return;
      _select(address);
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _clearSearch() => setState(_search.clear);

  @override
  Widget build(BuildContext context) {
    final current = AppServices.address.current;
    final usingLocation = current.label == LocationService.currentLabel;
    final addresses = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Endereço de entrega')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('Escolha onde receber seu pedido', style: AppText.body2.copyWith(color: AppColors.textDarkGrey)),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar endereço salvo',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(tooltip: 'Limpar busca', icon: const Icon(Icons.close_rounded), onPressed: _clearSearch),
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            children: [
              _AddressTile(
                icon: Icons.my_location_rounded,
                title: 'Usar minha localização atual',
                subtitle: usingLocation ? current.full : 'Pelo GPS do celular ou do navegador',
                selected: usingLocation,
                loading: _locating,
                onTap: _locating ? null : _useCurrentLocation,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Endereços salvos', style: AppText.h6),
          const SizedBox(height: 10),
          if (addresses.isEmpty)
            _EmptySearch(onClear: _clearSearch)
          else
            _Card(
              children: [
                for (final address in addresses)
                  _AddressTile(
                    icon: _iconFor(address),
                    title: address.label,
                    subtitle: address.full,
                    selected: !usingLocation && _same(address, current),
                    onTap: _locating ? null : () => _select(address),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static bool _same(DeliveryAddress a, DeliveryAddress b) =>
      a.label == b.label && a.latitude == b.latitude && a.longitude == b.longitude;

  static IconData _iconFor(DeliveryAddress address) => switch (address.label) {
        'Casa' => Icons.home_outlined,
        'Trabalho' => Icons.work_outline_rounded,
        'Academia' => Icons.fitness_center_rounded,
        _ => Icons.school_outlined,
      };
}

/// Card branco com divisórias entre os itens.
class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    // Material (e não Container) para o fundo do item selecionado aparecer.
    return Material(
      color: AppColors.bgWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppColors.strokeLight),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool loading;
  final VoidCallback? onTap;

  const _AddressTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.orange),
          )
        : selected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.orange)
            : null;

    return Semantics(
      selected: selected,
      child: ListTile(
        onTap: onTap,
        tileColor: selected ? AppColors.orangeSoft : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : AppColors.orangeSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: selected ? Colors.white : AppColors.orange),
        ),
        title: Text(title, style: AppText.h6),
        subtitle: Text(
          loading ? 'Procurando sua localização…' : subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption,
        ),
        trailing: trailing,
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptySearch({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, size: 32, color: AppColors.textGrey),
          const SizedBox(height: 8),
          Text('Nenhum endereço encontrado', style: AppText.h6),
          TextButton(onPressed: onClear, child: const Text('Limpar busca')),
        ],
      ),
    );
  }
}
