import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:gym_app/services/database_service.dart';
import 'package:gym_app/models/weight_log_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<WeightLogModel> _weightLogs = [];
  double _currentWeight = 0;
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  Future<void> _loadWeightData() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id;

      print('DEBUG: Current User ID: $userId');

      if (userId != null) {
        final logs = await _databaseService.getWeightLogs(userId);
        
        print('DEBUG: Weight logs retrieved: ${logs.length}');
        for (var log in logs) {
          print('DEBUG: Log - ${log.weight}kg on ${log.recordedAt}');
        }

        if (mounted) {
          setState(() {
            _weightLogs = logs;
            if (_weightLogs.isNotEmpty) {
              _currentWeight = _weightLogs.last.weight;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading weight logs: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Convertir WeightLogModels a FlSpot para la gráfica
  List<FlSpot> get _chartData {
    return _weightLogs.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.weight,
      );
    }).toList();
  }

  /// Calcular progreso y porcentaje
  String get _progressText {
    if (_weightLogs.length < 2) return 'Sin datos aún';

    final last = _weightLogs.last;

    return '${last.weight.toStringAsFixed(0)} kg';
  }

  String get _progressPercentage {
    if (_weightLogs.length < 2) return '';

    final first = _weightLogs.first;
    final last = _weightLogs.last;
    final difference = last.weight - first.weight;
    final percentage = ((difference / first.weight) * 100).toStringAsFixed(1);
    final sign = difference >= 0 ? '+' : '';

    return 'Últimos 30 días $sign$percentage%';
  }

  /// Calcular estadísticas
  double get _minWeight {
    if (_weightLogs.isEmpty) return 0;
    return _weightLogs.map((w) => w.weight).reduce((a, b) => a < b ? a : b);
  }

  double get _maxWeight {
    if (_weightLogs.isEmpty) return 0;
    return _weightLogs.map((w) => w.weight).reduce((a, b) => a > b ? a : b);
  }

  double get _avgWeight {
    if (_weightLogs.isEmpty) return 0;
    final sum = _weightLogs.map((w) => w.weight).reduce((a, b) => a + b);
    return sum / _weightLogs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: PRIMARY_COLOR),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: double.infinity),
                  const Text(
                    'Progreso',
                    style: TextStyle(
                      color: WHITE,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Peso section title
                        const Text(
                          'Peso',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: WHITE,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Current Weight Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: DARK_BG,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Peso actual',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SECONDARY_COLOR,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_currentWeight.toStringAsFixed(0)} kg',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: WHITE,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Progress section title
                        const Text(
                          'Progreso de peso',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: WHITE,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Progress Card
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _progressText,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: WHITE,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _progressPercentage,
                              style: TextStyle(
                                fontSize: 12,
                                color: _weightLogs.length >= 2 && 
                                    (_weightLogs.last.weight - _weightLogs.first.weight) >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Statistics Row
                        if (_weightLogs.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Min Weight
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: DARK_BG,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mínimo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: SECONDARY_COLOR,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_minWeight.toStringAsFixed(0)} kg',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: WHITE,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Avg Weight
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: DARK_BG,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Promedio',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: SECONDARY_COLOR,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_avgWeight.toStringAsFixed(0)} kg',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: WHITE,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Max Weight
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: DARK_BG,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Máximo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: SECONDARY_COLOR,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_maxWeight.toStringAsFixed(0)} kg',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: WHITE,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 32),

                        // Weight Chart
                        SizedBox(
                          width: double.infinity,
                          height: 280,
                          child: _chartData.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Sin registros aún. ¡Agrega tu peso desde el perfil!',
                                    style: TextStyle(
                                      color: SECONDARY_COLOR,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      horizontalInterval: 2,
                                      verticalInterval: 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.white.withOpacity(0.08),
                                          strokeWidth: 1,
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: Colors.white.withOpacity(0.08),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: 1,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                            final index = value.toInt();
                                            if (index >= 0 &&
                                                index < _weightLogs.length) {
                                              return Text(
                                                _weightLogs[index].shortDate,
                                                style: const TextStyle(
                                                  color: SECONDARY_COLOR,
                                                  fontSize: 11,
                                                ),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 2,
                                          reservedSize: 40,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                            return Text(
                                              '${value.toInt()} kg',
                                              style: const TextStyle(
                                                color: SECONDARY_COLOR,
                                                fontSize: 11,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: false,
                                    ),
                                    minX: 0,
                                    maxX: (_chartData.length - 1).toDouble(),
                                    minY: (_chartData.isNotEmpty
                                            ? _chartData
                                                .map((e) => e.y)
                                                .reduce((a, b) => a < b ? a : b)
                                            : 0) -
                                        2,
                                    maxY: (_chartData.isNotEmpty
                                            ? _chartData
                                                .map((e) => e.y)
                                                .reduce((a, b) => a > b ? a : b)
                                            : 100) +
                                        2,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _chartData,
                                        isCurved: false,
                                        barWidth: 2.5,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(show: false),
                                        color: PRIMARY_COLOR,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
