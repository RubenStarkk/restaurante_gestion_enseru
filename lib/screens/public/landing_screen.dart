import 'package:flutter/material.dart';

import '../../models/menu_item_model.dart';
import '../../services/menu_service.dart';
import '../../app.dart' show AppRoutes;
import 'menu_screen.dart';

/// Landing pública — Sprint 1 Kike.
///
/// Secciones:
///   1. Hero con CTA a reservas y carta.
///   2. Strip informativo (horarios, teléfono, dirección).
///   3. Novedades de temporada (platos con newArrival == true).
///   4. CTA secundario de reserva.
///   5. Footer con acceso staff discreto.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _HeroSection(),
            _InfoStrip(),
            _NovedadesSection(),
            _CtaSection(),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ─── 1. Hero ──────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 700;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 420),
      color: const Color(0xFF1A1208),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DiagonalPainter())),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 24,
                vertical: 60,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ENSERU',
                    style: TextStyle(
                      color: Color(0xFFD4A843),
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Restaurante & Gastronomía',
                    style: TextStyle(
                      color: Color(0xFFB0956A),
                      fontSize: 16,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Una experiencia gastronómica\nque despierta los sentidos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFEDE8DF),
                      fontSize: 22,
                      height: 1.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeroButton(
                        label: 'Reservar mesa',
                        filled: true,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.reservationStep1),
                      ),
                      const SizedBox(width: 16),
                      _HeroButton(
                        label: 'Ver carta',
                        filled: false,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.menu),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFD4A843) : Colors.transparent,
          border: Border.all(color: const Color(0xFFD4A843), width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
            filled ? const Color(0xFF1A1208) : const Color(0xFFD4A843),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// Líneas diagonales sutiles de fondo
class _DiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A843).withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── 2. Strip informativo ─────────────────────────────────────────────────────

class _InfoStrip extends StatelessWidget {
  const _InfoStrip();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 700;
    final items = [
      const _InfoChip(icon: Icons.access_time_rounded, text: 'Comida 13:00–15:30'),
      const _InfoChip(icon: Icons.access_time_rounded, text: 'Cena 20:00–23:00'),
      const _InfoChip(icon: Icons.phone_rounded,       text: '+34 600 000 000'),
      const _InfoChip(icon: Icons.location_on_rounded, text: 'Calle Imaginaria 42'),
    ];

    return Container(
      color: const Color(0xFF2C1F0A),
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 20),
      child: isWide
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items,
      )
          : Column(
        children: items
            .map((w) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: w,
        ))
            .toList(),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFD4A843), size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(color: Color(0xFFB0956A), fontSize: 13)),
      ],
    );
  }
}

// ─── 3. Novedades ─────────────────────────────────────────────────────────────

class _NovedadesSection extends StatelessWidget {
  const _NovedadesSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 700;
    return Container(
      color: const Color(0xFFFAF8F5),
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Novedades de temporada'),
          const SizedBox(height: 32),
          StreamBuilder<List<MenuItemModel>>(
            // usa el nuevo método del MenuService — sin ir directamente a Firestore
            stream: MenuService().watchNewArrivals(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4A843)),
                );
              }
              final items = snap.data ?? [];
              // Si aún no hay platos con newArrival en Firestore, muestra placeholders
              final cards = items.isEmpty
                  ? _placeholderCards()
                  : items.map((i) => _NovedadCard(item: i)).toList();

              return isWide
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards
                    .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: c,
                  ),
                ))
                    .toList(),
              )
                  : Column(
                children: cards
                    .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: c,
                ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _placeholderCards() => [
    const _StaticNovedadCard(
      tag: 'TEMPORADA',
      name: 'Menú degustación',
      description:
      'Una selección de nuestros mejores platos maridados con vinos de la región.',
      priceLabel: '45,00 € / persona',
    ),
    const _StaticNovedadCard(
      tag: 'NOVEDAD',
      name: 'Tartar de atún rojo',
      description:
      'Atún rojo de almadraba con aguacate, soja y crujiente de wonton.',
      priceLabel: '18,50 €',
    ),
    const _StaticNovedadCard(
      tag: 'CHEF',
      name: 'Carrillada ibérica',
      description:
      'Confitada a baja temperatura con puré de trufa y reducción de Pedro Ximénez.',
      priceLabel: '22,00 €',
    ),
  ];
}

class _NovedadCard extends StatelessWidget {
  const _NovedadCard({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    final priceLabel = item.pricingType == PricingType.perPerson
        ? '${item.price.toStringAsFixed(2)} € / persona'
        : '${item.price.toStringAsFixed(2)} €';

    return _CardShell(
      tag: 'NOVEDAD',
      name: item.name,
      description: item.description,
      priceLabel: priceLabel,
    );
  }
}

class _StaticNovedadCard extends StatelessWidget {
  const _StaticNovedadCard({
    required this.tag,
    required this.name,
    required this.description,
    required this.priceLabel,
  });

  final String tag;
  final String name;
  final String description;
  final String priceLabel;

  @override
  Widget build(BuildContext context) => _CardShell(
    tag: tag,
    name: name,
    description: description,
    priceLabel: priceLabel,
  );
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.tag,
    required this.name,
    required this.description,
    required this.priceLabel,
  });

  final String tag;
  final String name;
  final String? description;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE8E0D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF0DC),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Color(0xFFB07D20),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1208))),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description!,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF6B5E48), height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          Text(priceLabel,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD4A843))),
        ],
      ),
    );
  }
}

// ─── 4. CTA secundario ────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 700;
    return Container(
      color: const Color(0xFF1A1208),
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 64),
      child: Column(
        children: [
          const Text(
            '¿Listo para vivir la experiencia?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFFEDE8DF),
                fontSize: 28,
                fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reserva tu mesa en menos de dos minutos.\n'
                'Máximo 4 comensales online; grupos mayores, llámanos.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF8A7A62), fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.reservationStep1),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A843),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'Reservar ahora',
                style: TextStyle(
                  color: Color(0xFF1A1208),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 5. Footer ────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0B05),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© 2026 Restaurante Enseru',
            style: TextStyle(color: Color(0xFF4A3F2E), fontSize: 12),
          ),
          // acceso staff: discreto, solo texto pequeño, sin destacar
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.staffLogin),
            child: const Text(
              'Acceso staff',
              style: TextStyle(
                color: Color(0xFF4A3F2E),
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF4A3F2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget auxiliar ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 40, height: 2, color: const Color(0xFFD4A843)),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1208))),
      ],
    );
  }
}