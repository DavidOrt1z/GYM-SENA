import 'package:flutter/material.dart';
import 'package:gym_app/models/reservation_model.dart';
import 'package:gym_app/models/slot_model.dart';
import 'package:gym_app/services/auth_service.dart';
import 'package:gym_app/services/database_service.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<SlotModel> _allSlots = [];
  List<ReservationModel> _userReservations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser?.id ?? '';
    
    final slots = await _databaseService.getAvailableSlots();
    final reservations = await _databaseService.getUserReservations(userId);
    
    setState(() {
      _allSlots = slots;
      _userReservations = reservations;
      _isLoading = false;
    });
  }

  List<SlotModel> _getSlotsByDay(DateTime date) {
    final dayOfWeek = date.weekday - 1; // Monday = 0
    if (dayOfWeek < 0 || dayOfWeek > 4) return []; // Solo lunes a viernes
    return _allSlots.where((slot) => slot.dayOfWeek == dayOfWeek).toList();
  }

  bool _isSlotReservedByUser(SlotModel slot) {
    return _userReservations.any(
      (reservation) => reservation.slotId == slot.id && reservation.isActive,
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getDayName(DateTime date) {
    final days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return days[date.weekday - 1];
  }

  bool _isWeekday(DateTime date) {
    // Lunes=1 a Viernes=5
    return date.weekday >= 1 && date.weekday <= 5;
  }

  @override
  Widget build(BuildContext context) {
    final slotsForDay = _getSlotsByDay(_selectedDate);

    return Scaffold(
      backgroundColor: DARKER_BG,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PRIMARY_COLOR))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Reservas',
                      style: TextStyle(
                          color: WHITE,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  
                  // CALENDAR PICKER
                  Container(
                    decoration: BoxDecoration(
                      color: WHITE,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Month Navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.year > DateTime.now().year ? '' : ''}${['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'][_selectedDate.month - 1]} ${_selectedDate.year}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            Text('DOM', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('LUN', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('MAR', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('MIÉ', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('JUE', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('VIE', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('SÁB', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Calendar grid
                        _buildCalendarGrid(),
                        const SizedBox(height: 16),
                        
                        // Time Picker
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Time', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _selectedTime,
                                    );
                                    if (time != null) {
                                      setState(() => _selectedTime = time);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: Colors.black, fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCCCCCC)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('AM', style: TextStyle(color: Colors.black, fontSize: 12)),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCCCCCC)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('PM', style: TextStyle(color: Colors.black, fontSize: 12)),
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
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                        color: WHITE,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
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
                      child: const Center(
                        child: Text(
                          'El gimnasio solo atiende de Lunes a Viernes',
                          style: TextStyle(color: SECONDARY_COLOR, fontSize: 14),
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
                      child: const Center(
                        child: Text(
                          'No hay horarios disponibles para este día',
                          style: TextStyle(color: SECONDARY_COLOR, fontSize: 14),
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

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: DARK_BG,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      slot.displayTimeWithPeriod,
                                      style: const TextStyle(
                                        color: WHITE,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: isReserved || isFull
                                          ? null
                                          : () => _showReservationConfirmation(slot),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isReserved
                                              ? SECONDARY_COLOR
                                              : isFull
                                                  ? DARK_BG
                                                  : PRIMARY_COLOR,
                                          borderRadius: BorderRadius.circular(8),
                                          border: (isReserved || isFull)
                                              ? Border.all(color: SECONDARY_COLOR, width: 1)
                                              : null,
                                        ),
                                        child: Text(
                                          isReserved
                                              ? 'Reservado'
                                              : isFull
                                                  ? 'Agotado'
                                                  : 'Reservar',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: (isReserved || isFull) && !isReserved
                                                ? SECONDARY_COLOR
                                                : WHITE,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  slot.placesText,
                                  style: const TextStyle(
                                    color: SECONDARY_COLOR,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // My Reservations
                  if (_userReservations.isNotEmpty) _buildMyReservations(),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingDayOfWeek = firstDayOfMonth.weekday;

    final days = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < startingDayOfWeek % 7; i++) {
      days.add(const SizedBox());
    }

    // Days of month
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, i);
      final isSelected = _selectedDate.day == i;
      final isToday = date.day == DateTime.now().day &&
          date.month == DateTime.now().month &&
          date.year == DateTime.now().year;
      
      // Solo permitir lunes a viernes (weekday: 1=Monday, 5=Friday, 6=Saturday, 7=Sunday)
      final isWeekday = date.weekday >= 1 && date.weekday <= 5;

      days.add(
        GestureDetector(
          onTap: isWeekday ? () => setState(() => _selectedDate = date) : null,
          child: Opacity(
            opacity: isWeekday ? 1.0 : 0.3,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : (isToday ? Colors.black : Colors.transparent),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    color: isSelected ? WHITE : Colors.black,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: days,
    );
  }

  Widget _buildMyReservations() {
    final activeReservations =
        _userReservations.where((r) => r.isActive).toList();

    if (activeReservations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: SECONDARY_COLOR, height: 32),
        const Text('Mis Reservas',
            style: TextStyle(
                color: WHITE, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeReservations.length,
          itemBuilder: (context, index) {
            final reservation = activeReservations[index];
            final slot = _allSlots.firstWhere(
              (s) => s.id == reservation.slotId,
              orElse: () => SlotModel(
                id: 0,
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
                  color: DARK_BG,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PRIMARY_COLOR, width: 1),
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
                            Text(slot.displayTimeWithPeriod,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: PRIMARY_COLOR)),
                            const SizedBox(height: 4),
                            Text(reservation.displayReservationDate,
                                style: const TextStyle(
                                    fontSize: 12, color: SECONDARY_COLOR)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: PRIMARY_COLOR.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(reservation.statusText,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: PRIMARY_COLOR,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _showQRCode(reservation),
                          child: Text('Ver QR',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: PRIMARY_COLOR,
                                  fontWeight: FontWeight.w600)),
                        ),
                        GestureDetector(
                          onTap: () => _showCancelConfirmation(reservation),
                          child: Text('Cancelar',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DARK_BG,
        title: const Text('QR de Reserva',
            style: TextStyle(color: WHITE)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WHITE,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: 'RES_${reservation.id}_${reservation.userId}',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID Reserva: ${reservation.id}',
              style: const TextStyle(
                color: SECONDARY_COLOR,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar',
                style: TextStyle(color: PRIMARY_COLOR)),
          ),
        ],
      ),
    );
  }

  void _showReservationConfirmation(SlotModel slot) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DARK_BG,
        title: const Text('Confirmar Reserva',
            style: TextStyle(color: WHITE)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Horario: ${slot.displayTimeWithPeriod}',
                style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12)),
            const SizedBox(height: 8),
            Text('Disponibles: ${slot.availableSpots}/${slot.capacity}',
                style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12)),
            const SizedBox(height: 12),
            const Text('¿Deseas confirmar esta reserva?',
                style: TextStyle(color: WHITE)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                const Text('Cancelar', style: TextStyle(color: SECONDARY_COLOR)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _reserveSlot(slot);
            },
            child: const Text('Confirmar',
                style: TextStyle(color: PRIMARY_COLOR)),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DARK_BG,
        title: const Text('Cancelar Reserva',
            style: TextStyle(color: WHITE)),
        content: const Text('¿Estás seguro de que deseas cancelar esta reserva?',
            style: TextStyle(color: SECONDARY_COLOR)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No', style: TextStyle(color: SECONDARY_COLOR)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _cancelReservation(reservation);
            },
            child: const Text('Sí', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _reserveSlot(SlotModel slot) async {
    try {
      final userId = _authService.currentUser?.id ?? '';
      final reservation =
          await _databaseService.createReservation(userId, slot.id);
      
      if (reservation != null) {
        await _databaseService.incrementSlotReservations(slot.id);
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Reserva confirmada!'),
              backgroundColor: PRIMARY_COLOR,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar la reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelReservation(ReservationModel reservation) async {
    try {
      final success = await _databaseService.cancelReservation(
        reservation.id,
        'Cancelado por el usuario',
      );
      
      if (success) {
        await _databaseService.decrementSlotReservations(reservation.slotId);
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva cancelada'),
              backgroundColor: PRIMARY_COLOR,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar la reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
