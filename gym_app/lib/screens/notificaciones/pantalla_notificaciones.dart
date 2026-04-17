import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import 'package:gym_app/providers/proveedor_notificaciones.dart';
import 'package:gym_app/utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProveedorNotificaciones>().cargarNotificaciones();
    });
  }

  DateTime? _parseNotificationDate(Map<String, dynamic> item) {
    final raw = item['fecha_creacion'] ?? item['created_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  String _formatSectionHeader(DateTime date, bool isEnglish) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return isEnglish ? 'Today' : 'Hoy';
    if (target == yesterday) return isEnglish ? 'Yesterday' : 'Ayer';

    const monthsEs = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const monthsEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (isEnglish) {
      return '${monthsEn[date.month - 1]} ${date.day}, ${date.year}';
    }

    return '${date.day} de ${monthsEs[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date, bool isEnglish) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = isEnglish
        ? (date.hour >= 12 ? 'PM' : 'AM')
        : (date.hour >= 12 ? 'p. m.' : 'a. m.');

    return '$hour:$minute $suffix';
  }

  List<_NotificationSection> _groupByDate(List<Map<String, dynamic>> items) {
    final grouped = <DateTime, List<Map<String, dynamic>>>{};

    for (final item in items) {
      final date =
          _parseNotificationDate(item) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateKey = DateTime(date.year, date.month, date.day);

      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return keys
        .map((key) => _NotificationSection(date: key, items: grouped[key]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      appBar: AppBar(
        backgroundColor: DARKER_BG,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: WHITE),
        title: Text(
          AppLocalizations.of(context, 'notificaciones'),
          style: const TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<ProveedorNotificaciones>(
        builder: (context, provider, _) {
          final isEnglish =
              Localizations.localeOf(context).languageCode == 'en';

          if (!provider.notificacionesHabilitadas) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      color: SECONDARY_COLOR,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEnglish
                          ? 'Notifications are turned off'
                          : 'Las notificaciones están desactivadas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: WHITE,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEnglish
                          ? 'Enable them in Settings to receive booking alerts and reminders.'
                          : 'Actívalas en Configuración para recibir alertas y recordatorios de reservas.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SECONDARY_COLOR,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.cargando) {
            return const Center(
              child: CircularProgressIndicator(color: PRIMARY_COLOR),
            );
          }

          final items = List<Map<String, dynamic>>.from(provider.notificaciones)
            ..sort((a, b) {
              final aDate = _parseNotificationDate(a) ?? DateTime(1970);
              final bDate = _parseNotificationDate(b) ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });

          final sections = _groupByDate(items);

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: SECONDARY_COLOR,
                      size: 54,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context, 'no_notifications_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: WHITE,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context, 'no_notifications_subtitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SECONDARY_COLOR,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: PRIMARY_COLOR,
            onRefresh: provider.cargarNotificaciones,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                    child: Text(
                      _formatSectionHeader(section.date, isEnglish),
                      style: const TextStyle(
                        color: Color(0xFF8DA3C1),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...section.items.map((item) {
                    final id = item['id']?.toString() ?? '';
                    final opened = item['abierta'] == true;
                    final title = item['titulo']?.toString() ?? 'GYM SENA';
                    final body = item['cuerpo']?.toString() ?? '';
                    final date = _parseNotificationDate(item);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: DARK_BG,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A3A4A)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            if (!opened && id.isNotEmpty) {
                              await provider.marcarComoAbierta(id);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF24364A),
                                    borderRadius: BorderRadius.circular(19),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFFB7CEE6),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: WHITE,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (!opened)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              decoration: const BoxDecoration(
                                                color: PRIMARY_COLOR,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: SECONDARY_COLOR,
                                          fontSize: 14,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (date != null)
                                  Text(
                                    _formatTime(date, isEnglish),
                                    style: const TextStyle(
                                      color: Color(0xFF9AB3CF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationSection {
  final DateTime date;
  final List<Map<String, dynamic>> items;

  const _NotificationSection({required this.date, required this.items});
}
