import 'package:flutter/material.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import '../../utils/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: DARKER_BG,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            title: Text(
              AppLocalizations.of(context, 'inicio'),
              style: const TextStyle(
                color: WHITE,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: WHITE),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: WHITE),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildMainBanner(),
              const SizedBox(height: 28),
              _buildSectionTitle(context, 'instalaciones'),
              const SizedBox(height: 12),
              _buildInstalacionesSection(),
              const SizedBox(height: 28),
              _buildSectionTitle(context, 'beneficios'),
              const SizedBox(height: 12),
              _buildBeneficiosSection(),
              const SizedBox(height: 28),
              _buildSectionTitle(context, 'equipamiento'),
              const SizedBox(height: 12),
              _buildEquipamientoSection(context),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
          ),
        ),
        child: const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Explora Nuestros servicios',
              style: TextStyle(
                color: WHITE,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String titleKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        AppLocalizations.of(context, titleKey),
        style: const TextStyle(
          color: WHITE,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInstalacionesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBeneficiosSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildBeneficioItem(
            icon: Icons.card_membership_outlined,
            title: 'Acceso Gratuito',
            subtitle: 'Servicios sin costo alguno.',
          ),
          const SizedBox(height: 12),
          _buildBeneficioItem(
            icon: Icons.access_time_outlined,
            title: 'Horarios Flexibles',
            subtitle: 'Adaptado a tus necesidades.',
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficioItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DARK_BG,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: WHITE, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: WHITE,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: SECONDARY_COLOR, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipamientoSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 36) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Primera fila - 2 items
          Row(
            children: [
              Expanded(
                child: _buildEquipamientoCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1576678927484-cc907957088c?w=400',
                  title: 'Cintas de correr',
                  subtitle: 'De última generación',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEquipamientoCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1638536532686-d610adfc8e5c?w=400',
                  title: 'Máquinas de peso',
                  subtitle: 'gama de equipos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda fila - 1 item
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: cardWidth,
              child: _buildEquipamientoCard(
                imageUrl:
                    'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400',
                title: 'Pesas libres',
                subtitle: 'Para todos los niveles de\ncondición física',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipamientoCard({
    required String imageUrl,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: WHITE,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12),
        ),
      ],
    );
  }
}
