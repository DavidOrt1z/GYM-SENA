import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_app/models/weight_log_model.dart';
import 'package:gym_app/services/database_service.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const Color _chartLineColor = Color(0xFF8FB1D3);

  final DatabaseService _databaseService = DatabaseService();

  List<WeightLogModel> _weightLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  Future<void> _loadWeightData() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id;

      if (userId != null) {
        final logs = await _databaseService.getWeightLogs(userId);

        if (mounted) {
          setState(() {
            _weightLogs = logs;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<FlSpot> get _chartData {
    return _weightLogs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
  }

  String get _currentWeightText {
    if (_weightLogs.isEmpty) return '-- kg';
    return '${_weightLogs.last.weight.toStringAsFixed(0)} kg';
  }

  double get _recentChangePercent {
    if (_weightLogs.length < 2) return 0;

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recentLogs = _weightLogs
        .where((log) => log.recordedAt.isAfter(cutoff))
        .toList();

    if (recentLogs.length < 2) return 0;

    final first = recentLogs.first;
    final last = recentLogs.last;
    if (first.weight == 0) return 0;

    return ((last.weight - first.weight) / first.weight) * 100;
  }

  bool get _isChangePositive => _recentChangePercent >= 0;

  String get _recentChangeText {
    if (_weightLogs.length < 2) return '0%';
    final sign = _isChangePositive ? '+' : '';
    return '$sign${_recentChangePercent.toStringAsFixed(0)}%';
  }

  Set<int> get _labelIndexes {
    final count = _weightLogs.length;
    if (count == 0) return {};
    if (count <= 4) {
      return List<int>.generate(count, (index) => index).toSet();
    }

    return {
      0,
      ((count - 1) * 0.33).round(),
      ((count - 1) * 0.66).round(),
      count - 1,
    };
  }

  double get _chartMinY {
    if (_chartData.isEmpty) return 0;
    final minY = _chartData
        .map((point) => point.y)
        .reduce((a, b) => a < b ? a : b);
    return minY - 2;
  }

  double get _chartMaxY {
    if (_chartData.isEmpty) return 100;
    final maxY = _chartData
        .map((point) => point.y)
        .reduce((a, b) => a > b ? a : b);
    return maxY + 2;
  }

  Widget _buildChart() {
    if (_chartData.isEmpty) {
      return const Center(
        child: Text(
          'Sin registros de peso aún',
          style: TextStyle(
            color: SECONDARY_COLOR,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_chartData.length - 1).toDouble(),
        minY: _chartMinY,
        maxY: _chartMaxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 ||
                    index >= _weightLogs.length ||
                    !_labelIndexes.contains(index)) {
                  return const SizedBox.shrink();
                }

                return Text(
                  _weightLogs[index].shortDate,
                  style: const TextStyle(
                    color: SECONDARY_COLOR,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _chartData,
            isCurved: true,
            curveSmoothness: 0.32,
            barWidth: 3,
            color: _chartLineColor,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: PRIMARY_COLOR),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Progreso',
                        style: TextStyle(
                          color: WHITE,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Peso',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: WHITE,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
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
                              fontSize: 16,
                              color: WHITE,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentWeightText,
                            style: const TextStyle(
                              fontSize: 44,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: WHITE,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Progreso de peso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: WHITE,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentWeightText,
                      style: const TextStyle(
                        fontSize: 48,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: WHITE,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Últimos 30 días ',
                            style: TextStyle(
                              color: SECONDARY_COLOR,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: _recentChangeText,
                            style: TextStyle(
                              color: _isChangePositive
                                  ? const Color(0xFF27E27A)
                                  : ERROR_COLOR,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(child: _buildChart()),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
      ),
    );
  }
}
