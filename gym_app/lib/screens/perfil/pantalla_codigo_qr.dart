import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

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
    _checkReservation();
  }

  Future<void> _checkReservation() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Buscar reserva activa del usuario
      final response = await Supabase.instance.client
          .from('reservations')
          .select('*, slots(*)')
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .order('created_at', ascending: false)
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
      await Supabase.instance.client
          .from('reservations')
          .update({'status': 'cancelled'})
          .eq('id', _reservation!['id']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? '';
    final userEmail = user?.email ?? '';
    
    // Datos que contendrá el QR
    final qrData = 'GYM_SENA:$userId:${_reservation?['id'] ?? 'NO_RESERVATION'}';

    return Scaffold(
      backgroundColor: DARKER_BG,
      appBar: AppBar(
        backgroundColor: DARKER_BG,
        elevation: 0,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PRIMARY_COLOR))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    
                    // Descripción
                    Text(
                      _hasActiveReservation
                          ? 'Este código es la entrada para acceder al gimnasio.'
                          : 'No tienes ninguna reserva activa.',
                      style: const TextStyle(
                        color: SECONDARY_COLOR,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    if (_hasActiveReservation) ...[
                      // Título QR
                      const Text(
                        'Codigo QR',
                        style: TextStyle(
                          color: WHITE,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Contenedor del QR
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
                        decoration: BoxDecoration(
                          color: DARK_BG,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 240,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Botón Cancelar reserva
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: DARK_BG,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  'Cancelar reserva',
                                  style: TextStyle(color: WHITE),
                                ),
                                content: const Text(
                                  '¿Estás seguro de que deseas cancelar tu reserva?',
                                  style: TextStyle(color: SECONDARY_COLOR),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'No',
                                      style: TextStyle(color: SECONDARY_COLOR),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _cancelReservation();
                                    },
                                    child: const Text(
                                      'Sí, cancelar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PRIMARY_COLOR,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar reserva',
                            style: TextStyle(
                              color: WHITE,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ] else ...[
                      // Sin reserva activa
                      const SizedBox(height: 60),
                      Icon(
                        Icons.event_busy_outlined,
                        size: 80,
                        color: SECONDARY_COLOR.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Realiza una reserva para obtener tu código QR de acceso',
                        style: TextStyle(
                          color: SECONDARY_COLOR,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
