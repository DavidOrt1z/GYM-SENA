import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gym_app/models/reservation_model.dart';
import 'package:gym_app/models/slot_model.dart';
import 'package:gym_app/services/auth_service.dart';
import 'package:gym_app/services/database_service.dart';
import 'package:gym_app/screens/perfil/pantalla_codigo_qr.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:gym_app/utils/error_messages.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<SlotModel> _allSlots = [];
  List<ReservationModel> _userReservations = [];
  bool _isLoading = false;
  bool _isFetching = false;
  Timer? _refreshTimer;
  RealtimeChannel? _realtimeChannel;
  OverlayEntry? _successOverlayEntry;
  Timer? _successOverlayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _startAutoRefresh();
    _subscribeToRealtimeUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _successOverlayTimer?.cancel();
    _successOverlayEntry?.remove();
    _successOverlayEntry = null;
    final channel = _realtimeChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(showLoader: false);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadData(showLoader: false);
    });
  }

  void _subscribeToRealtimeUpdates() {
    final supabase = Supabase.instance.client;

    final existingChannel = _realtimeChannel;
    if (existingChannel != null) {
      supabase.removeChannel(existingChannel);
    }

    _realtimeChannel = supabase
        .channel('reservas-capacidad-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reservas',
          callback: (_) => _loadData(showLoader: false),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'franjas_horarias',
          callback: (_) => _loadData(showLoader: false),
        )
        .subscribe();
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (showLoader && mounted) {
      setState(() => _isLoading = true);
    }

    final userId = _authService.currentUser?.id ?? '';

    try {
      final slots = await _databaseService.getAvailableSlots();
      final reservations = await _databaseService.getUserReservations(userId);

      if (!mounted) return;
      setState(() {
        _allSlots = slots;
        _userReservations = reservations;
        if (showLoader) {
          _isLoading = false;
        }
      });
    } finally {
      _isFetching = false;
      if (showLoader && mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<SlotModel> _getSlotsByDay(DateTime date) {
    final todayStart = DateTime.now();
    final normalizedToday = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day,
    );
    final normalizedSelected = DateTime(date.year, date.month, date.day);

    if (normalizedSelected.isBefore(normalizedToday)) {
      return [];
    }

    final exactDateSlots = _allSlots.where((slot) {
      final slotDate = slot.slotDate;
      return slotDate != null && _isSameDay(slotDate, date);
    }).toList();

    exactDateSlots.sort((a, b) {
      if (a.startTime == b.startTime) {
        return a.endTime.compareTo(b.endTime);
      }
      return a.startTime.compareTo(b.startTime);
    });

    return exactDateSlots;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _getReservationSlotDate(ReservationModel reservation) {
    for (final slot in _allSlots) {
      if (slot.id == reservation.slotId && slot.slotDate != null) {
        return slot.slotDate!;
      }
    }
    return null;
  }

  DateTime _getReservationDate(ReservationModel reservation) {
    return _getReservationSlotDate(reservation) ?? reservation.reservedAt;
  }

  bool _hasReservationOnDate(DateTime date) {
    return _userReservations.any((reservation) {
      if (!reservation.isActive) return false;
      final reservationSlotDate = _getReservationSlotDate(reservation);
      if (reservationSlotDate == null) return false;
      return _isSameDay(reservationSlotDate, date);
    });
  }

  bool _isSlotReservedByUser(SlotModel slot) {
    return _userReservations.any(
      (reservation) => reservation.slotId == slot.id && reservation.isActive,
    );
  }

  String _formatDate(DateTime date, bool isEnglish) {
    final months = isEnglish
        ? [
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
          ]
        : [
            'Enero',
            'Febrero',
            'Marzo',
            'Abril',
            'Mayo',
            'Junio',
            'Julio',
            'Agosto',
            'Septiembre',
            'Octubre',
            'Noviembre',
            'Diciembre',
          ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatMonthYear(DateTime date, bool isEnglish) {
    final months = isEnglish
        ? [
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
          ]
        : [
            'Enero',
            'Febrero',
            'Marzo',
            'Abril',
            'Mayo',
            'Junio',
            'Julio',
            'Agosto',
            'Septiembre',
            'Octubre',
            'Noviembre',
            'Diciembre',
          ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _reservationStatusText(ReservationModel reservation, bool isEnglish) {
    if (!isEnglish) return reservation.statusText;
    if (reservation.isActive) return 'Active';
    if (reservation.isCompleted) return 'Completed';
    if (reservation.isCancelled) return 'Cancelled';
    return 'Unknown';
  }

  String get _formattedSelectedTime {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')} : $minute';
  }

  void _setSelectedPeriod(DayPeriod targetPeriod) {
    final currentHour = _selectedTime.hour;
    final currentMinute = _selectedTime.minute;

    int newHour = currentHour;
    if (targetPeriod == DayPeriod.am && currentHour >= 12) {
      newHour = currentHour - 12;
    } else if (targetPeriod == DayPeriod.pm && currentHour < 12) {
      newHour = currentHour + 12;
    }

    setState(() {
      _selectedTime = TimeOfDay(hour: newHour, minute: currentMinute);
    });
  }

  bool _isWeekday(DateTime date) {
    // Lunes=1 a Viernes=5
    return date.weekday >= 1 && date.weekday <= 5;
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final slotsForDay = _getSlotsByDay(_selectedDate);

    return Scaffold(
      backgroundColor: DARKER_BG,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: DARKER_BG)),
          SafeArea(
            bottom: false,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: PRIMARY_COLOR),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            AppLocalizations.of(context, 'reservas'),
                            style: const TextStyle(
                              color: WHITE,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // CALENDAR PICKER
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          child: Column(
                            children: [
                              // Month Navigation
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _formatMonthYear(
                                          _selectedDate,
                                          isEnglish,
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFF2C3E50),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF2C3E50),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chevron_left,
                                          color: Color(0xFF2C3E50),
                                          size: 34,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _selectedDate = DateTime(
                                              _selectedDate.year,
                                              _selectedDate.month - 1,
                                              _selectedDate.day,
                                            );
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF2C3E50),
                                          size: 34,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _selectedDate = DateTime(
                                              _selectedDate.year,
                                              _selectedDate.month + 1,
                                              _selectedDate.day,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Day headers
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    isEnglish ? 'SUN' : 'DOM',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isEnglish ? 'MON' : 'LUN',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isEnglish ? 'TUE' : 'MAR',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isEnglish ? 'WED' : 'MIE',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isEnglish ? 'THU' : 'JUE',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isEnglish ? 'FRI' : 'VIE',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isEnglish ? 'SAT' : 'SAB',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Calendar grid
                              _buildCalendarGrid(),
                              const SizedBox(height: 12),

                              // Time Picker
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context, 'hora'),
                                    style: TextStyle(
                                      color: Color(0xFF111111),
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: _selectedTime,
                                          );
                                          if (time != null) {
                                            setState(
                                              () => _selectedTime = time,
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE7E7E7),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _formattedSelectedTime,
                                            style: const TextStyle(
                                              color: Color(0xFF1E1E1E),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE7E7E7),
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _setSelectedPeriod(
                                                DayPeriod.am,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      _selectedTime.period ==
                                                          DayPeriod.am
                                                      ? WHITE
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  border:
                                                      _selectedTime.period ==
                                                          DayPeriod.am
                                                      ? Border.all(
                                                          color: const Color(
                                                            0xFFD0D0D0,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                child: const Text(
                                                  'AM',
                                                  style: TextStyle(
                                                    color: Color(0xFF111111),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => _setSelectedPeriod(
                                                DayPeriod.pm,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      _selectedTime.period ==
                                                          DayPeriod.pm
                                                      ? WHITE
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  border:
                                                      _selectedTime.period ==
                                                          DayPeriod.pm
                                                      ? Border.all(
                                                          color: const Color(
                                                            0xFFD0D0D0,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                child: const Text(
                                                  'PM',
                                                  style: TextStyle(
                                                    color: Color(0xFF111111),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Date header
                        Text(
                          _formatDate(_selectedDate, isEnglish),
                          style: const TextStyle(
                            color: WHITE,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Slots List
                        if (!_isWeekday(_selectedDate))
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: DARK_BG,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                isEnglish
                                    ? 'The gym only operates Monday to Friday'
                                    : 'El gimnasio solo atiende de Lunes a Viernes',
                                style: TextStyle(
                                  color: SECONDARY_COLOR,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else if (slotsForDay.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: DARK_BG,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                isEnglish
                                    ? 'No schedules available for this day'
                                    : 'No hay horarios disponibles para este día',
                                style: TextStyle(
                                  color: SECONDARY_COLOR,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: slotsForDay.length,
                            itemBuilder: (context, index) {
                              final slot = slotsForDay[index];
                              final isReserved = _isSlotReservedByUser(slot);
                              final isFull = !slot.isAvailable;

                              final buttonColor = isReserved
                                  ? const Color(0xFF4D647A)
                                  : isFull
                                  ? const Color(0xFF2A3E52)
                                  : PRIMARY_COLOR;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            slot.displayTimeWithPeriod,
                                            style: const TextStyle(
                                              color: WHITE,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isEnglish
                                                ? '${slot.availableSpots}/${slot.capacity} spots available'
                                                : slot.placesText,
                                            style: const TextStyle(
                                              color: SECONDARY_COLOR,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: isReserved || isFull
                                          ? null
                                          : () => _showReservationConfirmation(
                                              slot,
                                            ),
                                      child: Container(
                                        width: 102,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: buttonColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          isReserved
                                              ? (isEnglish
                                                    ? 'Booked'
                                                    : 'Reservado')
                                              : isFull
                                              ? AppLocalizations.of(
                                                  context,
                                                  'agotado',
                                                )
                                              : AppLocalizations.of(
                                                  context,
                                                  'reservar',
                                                ),
                                          style: const TextStyle(
                                            color: WHITE,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        // My Reservations
                        if (_userReservations.isNotEmpty)
                          _buildMyReservations(isEnglish),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final startingDayOfWeek = firstDayOfMonth.weekday % 7;

    final days = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < startingDayOfWeek; i++) {
      days.add(const SizedBox.shrink());
    }

    // Days of month
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, i);
      final isSelected = _selectedDate.day == i;
      // Solo permitir lunes a viernes (weekday: 1=Monday, 5=Friday, 6=Saturday, 7=Sunday)
      final isWeekday = date.weekday >= 1 && date.weekday <= 5;
      final isPastDate = _isPastDate(date);
      final isSelectable = isWeekday && !isPastDate;

      days.add(
        GestureDetector(
          onTap: isSelectable
              ? () => setState(() => _selectedDate = date)
              : null,
          child: Opacity(
            opacity: isSelectable ? 1.0 : 0.3,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2A4055)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$i',
                  maxLines: 1,
                  softWrap: false,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: isSelected ? WHITE : const Color(0xFF2A3B4D),
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    while (days.length % 7 != 0) {
      days.add(const SizedBox.shrink());
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.18,
      children: days,
    );
  }

  Widget _buildMyReservations(bool isEnglish) {
    final visibleReservations = _userReservations
        .where((r) => !r.isCancelled)
        .toList();

    visibleReservations.sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      return _getReservationDate(b).compareTo(_getReservationDate(a));
    });

    if (visibleReservations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: SECONDARY_COLOR, height: 32),
        Text(
          AppLocalizations.of(context, 'mis_reservas'),
          style: const TextStyle(
            color: WHITE,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleReservations.length,
          itemBuilder: (context, index) {
            final reservation = visibleReservations[index];
            final slot = _allSlots.firstWhere(
              (s) => s.id == reservation.slotId,
              orElse: () => SlotModel(
                id: '0',
                gymId: 0,
                dayOfWeek: 0,
                startTime: '00:00',
                endTime: '00:00',
                capacity: 0,
                reservedCount: 0,
                status: 'inactive',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3947),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D5366), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.displayTimeWithPeriod,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: PRIMARY_COLOR,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reservation.displayReservationDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: SECONDARY_COLOR,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: reservation.isCompleted
                                ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
                                : PRIMARY_COLOR.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _reservationStatusText(reservation, isEnglish),
                            style: const TextStyle(
                              fontSize: 11,
                              color: WHITE,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    reservation.isActive
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => _showQRCode(reservation),
                                style: TextButton.styleFrom(
                                  backgroundColor: PRIMARY_COLOR,
                                  foregroundColor: WHITE,
                                  minimumSize: const Size(64, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppLocalizations.of(context, 'mostrar_qr'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: WHITE,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _showCancelConfirmation(reservation),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  foregroundColor: WHITE,
                                  minimumSize: const Size(80, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppLocalizations.of(context, 'cancelar'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: WHITE,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isEnglish
                                  ? 'This booking is already completed.'
                                  : 'Esta reserva ya fue completada.',
                              style: TextStyle(
                                color: SECONDARY_COLOR,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showQRCode(ReservationModel reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QrCodeScreen(reservation: reservation)),
    );
  }

  void _showReservationConfirmation(SlotModel slot) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final selectedSlotDate = slot.slotDate ?? _selectedDate;
    if (_hasReservationOnDate(selectedSlotDate)) {
      _showCenteredDailyLimitToast();
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DARK_BG,
        title: Text(
          isEnglish ? 'Confirm Booking' : 'Confirmar Reserva',
          style: const TextStyle(color: WHITE),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isEnglish ? 'Schedule' : 'Horario'}: ${slot.displayTimeWithPeriod}',
              style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '${isEnglish ? 'Available' : 'Disponibles'}: ${slot.availableSpots}/${slot.capacity}',
              style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              isEnglish
                  ? 'Do you want to confirm this booking?'
                  : '¿Deseas confirmar esta reserva?',
              style: const TextStyle(color: WHITE),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context, 'cancelar'),
              style: TextStyle(color: SECONDARY_COLOR),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _reserveSlot(slot);
            },
            child: Text(
              isEnglish ? 'Confirm' : 'Confirmar',
              style: TextStyle(color: PRIMARY_COLOR),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(ReservationModel reservation) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DARK_BG,
        title: Text(
          isEnglish ? 'Cancel Booking' : 'Cancelar Reserva',
          style: const TextStyle(color: WHITE),
        ),
        content: Text(
          isEnglish
              ? 'Are you sure you want to cancel this booking?'
              : '¿Estás seguro de que deseas cancelar esta reserva?',
          style: const TextStyle(color: SECONDARY_COLOR),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              isEnglish ? 'No' : 'No',
              style: const TextStyle(color: SECONDARY_COLOR),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _cancelReservation(reservation);
            },
            child: Text(
              isEnglish ? 'Yes' : 'Sí',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCenteredSuccessToast(String message) {
    if (!mounted) return;

    _successOverlayTimer?.cancel();
    _successOverlayEntry?.remove();
    _successOverlayEntry = null;

    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B7FDB), Color(0xFF0F5FB8)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D1273D4),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF91C8FF).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: WHITE,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: WHITE,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);
    _successOverlayEntry = entry;

    _successOverlayTimer = Timer(const Duration(milliseconds: 1900), () {
      _successOverlayEntry?.remove();
      _successOverlayEntry = null;
    });
  }

  void _showCenteredDailyLimitToast() {
    if (!mounted) return;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    _successOverlayTimer?.cancel();
    _successOverlayEntry?.remove();
    _successOverlayEntry = null;

    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B7FDB), Color(0xFF0F5FB8)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D1273D4),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF91C8FF).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_rounded, color: WHITE, size: 22),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          isEnglish
                              ? 'You can only book once per day'
                              : 'Solo puedes reservar una sola vez al dia',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            color: WHITE,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            height: 1.25,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);
    _successOverlayEntry = entry;

    _successOverlayTimer = Timer(const Duration(milliseconds: 2200), () {
      _successOverlayEntry?.remove();
      _successOverlayEntry = null;
    });
  }

  void _showCenteredCancelToast() {
    if (!mounted) return;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    _successOverlayTimer?.cancel();
    _successOverlayEntry?.remove();
    _successOverlayEntry = null;

    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66C62828),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFCDD2).withValues(alpha: 0.75),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_busy_rounded,
                        color: WHITE,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          isEnglish
                              ? 'Booking cancelled successfully'
                              : 'Reserva cancelada correctamente',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: WHITE,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);
    _successOverlayEntry = entry;

    _successOverlayTimer = Timer(const Duration(milliseconds: 2200), () {
      _successOverlayEntry?.remove();
      _successOverlayEntry = null;
    });
  }

  Future<void> _reserveSlot(SlotModel slot) async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    try {
      final selectedSlotDate = slot.slotDate ?? _selectedDate;
      if (_hasReservationOnDate(selectedSlotDate)) {
        _showCenteredDailyLimitToast();
        return;
      }

      final userId = _authService.currentUser?.id ?? '';
      if (userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEnglish
                    ? 'You must sign in to book'
                    : 'Debes iniciar sesión para reservar',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final reservation = await _databaseService.createReservation(
        userId,
        slot.id,
      );

      if (reservation != null) {
        await _databaseService.incrementSlotReservations(slot.id);
        await _loadData();

        _showCenteredSuccessToast(
          isEnglish ? 'Booking confirmed!' : '¡Reserva confirmada!',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEnglish
                    ? 'Could not book. Check your user profile and RLS permissions.'
                    : 'No se pudo reservar. Revisa tu perfil de usuario y permisos RLS.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessages.map(
                e,
                fallback: isEnglish
                    ? 'Could not complete booking. Please try again.'
                    : 'No se pudo realizar la reserva. Intenta nuevamente',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelReservation(ReservationModel reservation) async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    try {
      final success = await _databaseService.cancelReservation(
        reservation.id,
        isEnglish ? 'Cancelled by user' : 'Cancelado por el usuario',
      );

      if (success) {
        await _databaseService.decrementSlotReservations(reservation.slotId);
        await _loadData();
        _showCenteredCancelToast();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEnglish
                    ? 'Could not cancel booking. Check Supabase permissions.'
                    : 'No se pudo cancelar la reserva. Verifica permisos en Supabase.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessages.map(
                e,
                fallback: isEnglish
                    ? 'Could not cancel booking. Please try again.'
                    : 'No se pudo cancelar la reserva. Intenta nuevamente',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
