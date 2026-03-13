import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import 'pantalla_unidades_guardadas.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'm';
  bool _isSaving = false;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _loadUserUnits();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserUnits() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('users')
          .select('unidades, peso_kg, altura_cm')
          .eq('id', userId)
          .single();

      if (response['unidades'] != null) {
        final units = response['unidades'];
        double? weight = response['peso_kg'] as double?;
        double? height = response['altura_cm'] as double?;

        setState(() {
          if (units == 'metric') {
            _selectedWeightUnit = 'kg';
            _selectedHeightUnit = 'm';
            if (weight != null) _weightController.text = weight.toStringAsFixed(1);
            if (height != null) {
              // Mostrar altura en cm cuando la unidad es metros
              _heightController.text = height.toStringAsFixed(0);
            }
          } else {
            _selectedWeightUnit = 'lbs';
            _selectedHeightUnit = 'ft';
            if (weight != null) _weightController.text = (weight * 2.20462).toStringAsFixed(1);
            if (height != null) _heightController.text = (height / 30.48).toStringAsFixed(2);
          }
        });
      }
    } catch (e) {
      print('Error loading units: $e');
    }
  }

  Future<void> _saveUnits() async {
    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
        throw Exception('Por favor completa peso y altura');
      }

      // Convertir valores a metric para guardar
      double weight = double.parse(_weightController.text);
      double height = double.parse(_heightController.text);

      // Si están en imperial, convertir a metric
      if (_selectedWeightUnit == 'lbs') {
        weight = weight / 2.20462; // lbs a kg
      }
      
      // Para altura: si está en metros, convertir a cm
      // Si está en pies, convertir a cm
      if (_selectedHeightUnit == 'ft') {
        height = height * 30.48; // ft a cm
      } else {
        // Si está en metros y es > 10, asumir que es cm
        if (height > 10) {
          // Ya está en cm
        } else {
          // Es en metros, convertir a cm
          height = height * 100; // m a cm
        }
      }

      // Determinar si es metric o imperial
      final unitsType = _selectedWeightUnit == 'kg' ? 'metric' : 'imperial';

      await Supabase.instance.client
          .from('users')
          .update({
            'unidades': unitsType,
            'peso_kg': weight,
            'altura_cm': height,
          })
          .eq('id', userId);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const UnitsSavedScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Unidades de medida',
          style: TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección Peso
              const Text(
                'Peso',
                style: TextStyle(
                  color: WHITE,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: WHITE),
                      decoration: InputDecoration(
                        hintText: 'Ingresa el peso',
                        hintStyle: const TextStyle(color: SECONDARY_COLOR),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedWeightUnit = _selectedWeightUnit == 'kg' ? 'lbs' : 'kg';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: PRIMARY_COLOR, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedWeightUnit,
                        style: const TextStyle(
                          color: WHITE,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Sección Altura
              const Text(
                'Altura',
                style: TextStyle(
                  color: WHITE,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: WHITE),
                      decoration: InputDecoration(
                        hintText: 'Ej: 1.74 o 174',
                        hintStyle: const TextStyle(color: SECONDARY_COLOR),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedHeightUnit = _selectedHeightUnit == 'm' ? 'ft' : 'm';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: PRIMARY_COLOR, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedHeightUnit,
                        style: const TextStyle(
                          color: WHITE,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveUnits,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PRIMARY_COLOR,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: WHITE,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                            color: WHITE,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
