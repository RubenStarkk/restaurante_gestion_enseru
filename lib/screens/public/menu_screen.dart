import 'package:flutter/material.dart';

import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';

/// Carta digital pública — Sprint 1 Kike.
///
/// Lee de Firestore vía MenuService.watchAll() y agrupa por categoría
/// con MenuService.groupByCategory(). Usa los campos reales del modelo:
///   - category: String libre ("Entrantes", "Arroces"…)
///   - pricingType: perUnit | perPerson (RF8)
///   - byOrder: bool (RF5 — platos por encargo)
///   - newArrival: bool (badge "Nuevo")
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _service = MenuService();
  // null = mostrar todas las categorías
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1208),
        foregroundColor: const Color(0xFFD4A843),
        title: const Text(
          'ENSERU — Carta',
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: _service.watchAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A843)),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar la carta.\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B5E48)),
                ),
              ),
            );
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'La carta no está disponible en este momento.',
                style: TextStyle(color: Color(0xFF6B5E48)),
              ),
            );
          }

          final grouped = MenuService.groupByCategory(items);
          final categories = grouped.keys.toList();

          // si la categoría seleccionada desaparece de Firestore, resetear
          if (_selectedCategory != null &&
              !categories.contains(_selectedCategory)) {
            WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => _selectedCategory = null));
          }

          return Column(
            children: [
              _CategoryBar(
                categories: categories,
                selected: _selectedCategory,
                onSelect: (cat) => setState(() => _selectedCategory = cat),
              ),
              Expanded(
                child: isWide
                    ? _WideLayout(
                    grouped: grouped, filter: _selectedCategory)
                    : _NarrowLayout(
                    grouped: grouped, filter: _selectedCategory),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Barra de categorías ──────────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C1F0A),
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _CatChip(
            label: 'Todas',
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
                (cat) => _CatChip(
              label: cat,
              active: selected == cat,
              onTap: () => onSelect(selected == cat ? null : cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD4A843) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
            active ? const Color(0xFFD4A843) : const Color(0xFF6B5020),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: active
                  ? const Color(0xFF1A1208)
                  : const Color(0xFFB0956A),
              fontWeight:
              active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Layouts ──────────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.grouped, required this.filter});

  final Map<String, List<MenuItemModel>> grouped;
  final String? filter;

  @override
  Widget build(BuildContext context) {
    final visible = filter != null
        ? grouped.entries.where((e) => e.key == filter).toList()
        : grouped.entries.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // índice lateral fijo
        SizedBox(
          width: 180,
          child: Container(
            color: const Color(0xFFF0EBE0),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: grouped.keys
                  .map((cat) => _SideItem(
                label: cat,
                active: filter == cat,
              ))
                  .toList(),
            ),
          ),
        ),
        // lista de platos
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: visible
                .map((e) =>
                _CategorySection(category: e.key, items: e.value))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.grouped, required this.filter});

  final Map<String, List<MenuItemModel>> grouped;
  final String? filter;

  @override
  Widget build(BuildContext context) {
    final visible = filter != null
        ? grouped.entries.where((e) => e.key == filter).toList()
        : grouped.entries.toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      children: visible
          .map((e) =>
          _CategorySection(category: e.key, items: e.value))
          .toList(),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: active
          ? const BoxDecoration(
        border: Border(
            left: BorderSide(color: Color(0xFFD4A843), width: 3)),
        color: Color(0xFFEBE3D0),
      )
          : null,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: active ? const Color(0xFF1A1208) : const Color(0xFF6B5E48),
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ─── Sección de categoría ─────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.items});

  final String category;
  final List<MenuItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            children: [
              Container(
                  width: 3, height: 22, color: const Color(0xFFD4A843)),
              const SizedBox(width: 10),
              Text(
                category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: Color(0xFF1A1208),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _ItemRow(item: item)),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFFE8E0D0), thickness: 0.5),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Fila de plato ────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    // RF8 — precio por persona si pricingType == perPerson
    final priceLabel = item.pricingType == PricingType.perPerson
        ? '${item.price.toStringAsFixed(2)} € / persona'
        : '${item.price.toStringAsFixed(2)} €';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // nombre + badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1208),
                        ),
                      ),
                    ),
                    if (item.newArrival)
                      const _Badge(
                          label: 'Nuevo', color: Color(0xFFB07D20)),
                    if (item.byOrder)
                      const _Badge(
                          label: 'Encargo', color: Color(0xFF3A7ABF)),
                  ],
                ),
                // descripción
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B5E48),
                      height: 1.5,
                    ),
                  ),
                ],
                // aviso RF5
                if (item.byOrder) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '⚠ Requiere reserva con más de 24 h de antelación',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3A7ABF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // precio alineado a la derecha
          Text(
            priceLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD4A843),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}