import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gym_app/models/reservation_model.dart';
import 'package:gym_app/screens/navegacion_principal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_app/utils/error_messages.dart';
import '../../utils/constants.dart';

class QrCodeScreen extends StatefulWidget {
  final ReservationModel? reservation;

  const QrCodeScreen({super.key, this.reservation});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  bool _isLoading = true;
  bool _hasActiveReservation = false;
  Map<String, dynamic>? _reservation;

  @override
  void initState() {
    super.initState();
    if (widget.reservation != null) {
      _reservation = {
        'id': widget.reservation!.id,
        'token_qr': widget.reservation!.qrToken,
        'estado': widget.reservation!.status,
        'fecha_creacion': widget.reservation!.createdAt.toIso8601String(),
      };
      _hasActiveReservation = widget.reservation!.isActive;
      _isLoading = false;
    } else {
      _checkReservation();
    }
  }

  Future<void> _checkReservation() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Resolver posibles IDs de usuario en BD (id y/o id_autenticacion).
      final users = await Supabase.instance.client
          .from('users')
          .select('id')
          .or('id.eq.$userId,id_autenticacion.eq.$userId');

      final userIds = <String>{userId};
      for (final row in users) {
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) {
          userIds.add(id);
        }
      }

      final response = await Supabase.instance.client
          .from('reservas')
          .select('*, franjas_horarias(*)')
          .inFilter('id_usuario', userIds.toList())
          .eq('estado', 'active')
          .order('fecha_creacion', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _reservation = response;
        _hasActiveReservation = response != null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking reservation: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelReservation() async {
    if (_reservation == null) return;

    try {
      final updated = await Supabase.instance.client
          .from('reservas')
          .update({
            'estado': 'cancelled',
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', _reservation!['id'])
          .select('id');

      if (updated.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cancelar la reserva'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _checkReservation();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(
              initialIndex: 1,
              initialMessage: 'Reserva cancelada',
            ),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessages.map(
                e,
                fallback: 'No se pudo cancelar la reserva. Intenta nuevamente',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationId = (_reservation?['id']?.toString() ?? '').trim();
    final qrData = reservationId.isNotEmpty ? reservationId : 'SIN_RESERVA';

    return Scaffold(
      backgroundColor: const Color(0xFF071423),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WHITE),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Acceso de código QR',
          style: TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF081627), Color(0xFF071322), Color(0xFF06111D)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: PRIMARY_COLOR),
                )
              : _hasActiveReservation
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Este código es la entrada para acceder al gimnasio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFD9E5F4),
                          fontSize: 31 / 2,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        'Codigo QR',
                        style: TextStyle(
                          color: WHITE,
                          fontSize: 34 / 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF263A51),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final qrSize = constraints.maxWidth - 24;
                            return Center(
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: qrSize.clamp(200.0, 320.0),
                                backgroundColor: Colors.transparent,
                                foregroundColor: const Color(0xFFE8E8F2),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        reservationId.isNotEmpty
                            ? 'ID: ${reservationId.substring(0, reservationId.length >= 8 ? 8 : reservationId.length)}...'
                            : 'ID: SIN_RESERVA',
                        style: const TextStyle(
                          color: Color(0xFF91ADC9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cancelReservation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PRIMARY_COLOR,
                            foregroundColor: WHITE,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Cancelar reserva',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22364B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: Color(0xFFB8CDE3),
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes reservas activas',
                          style: TextStyle(
                            color: WHITE,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Para generar tu codigo QR, primero debes reservar un horario.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: SECONDARY_COLOR,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const MainNavigationScreen(
                                    initialIndex: 1,
                                  ),
                                ),
                                (_) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PRIMARY_COLOR,
                              foregroundColor: WHITE,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Ir a Reservas',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _checkReservation,
                          child: const Text('Actualizar estado'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
