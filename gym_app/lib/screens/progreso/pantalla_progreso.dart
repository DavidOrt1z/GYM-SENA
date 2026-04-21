import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_app/models/weight_log_model.dart';
import 'package:gym_app/services/database_service.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:gym_app/l10n/app_localizations.dart';
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

  List<FlSpot> get _visualChartData {
    if (_chartData.length >= 2) return _chartData;

    final baseWeight = _weightLogs.isNotEmpty ? _weightLogs.last.weight : 60;
    const totalPoints = 28;

    return List<FlSpot>.generate(totalPoints, (index) {
      final progress = index / (totalPoints - 1);
      final waveA = math.sin(progress * math.pi * 6) * 0.9;
      final waveB = math.sin(progress * math.pi * 13) * 0.35;
      return FlSpot(index.toDouble(), baseWeight + waveA + waveB);
    });
  }

  String _formatDayMonth(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  Map<int, String> get _bottomLabels {
    if (_weightLogs.length >= 2) {
      final count = _weightLogs.length;
      if (count <= 4) {
        return {for (int i = 0; i < count; i++) i: _weightLogs[i].shortDate};
      }

      final i1 = 0;
      final i2 = ((count - 1) * 0.33).round();
      final i3 = ((count - 1) * 0.66).round();
      final i4 = count - 1;

      return {
        i1: _weightLogs[i1].shortDate,
        i2: _weightLogs[i2].shortDate,
        i3: _weightLogs[i3].shortDate,
        i4: _weightLogs[i4].shortDate,
      };
    }

    final now = DateTime.now();
    return {
      0: _formatDayMonth(now.subtract(const Duration(days: 21))),
      9: _formatDayMonth(now.subtract(const Duration(days: 14))),
      18: _formatDayMonth(now.subtract(const Duration(days: 7))),
      27: _formatDayMonth(now),
    };
  }

  double get _chartMinY {
    if (_visualChartData.isEmpty) return 0;
    final minY = _visualChartData
        .map((point) => point.y)
        .reduce((a, b) => a < b ? a : b);
    return minY - 1.4;
  }

  double get _chartMaxY {
    if (_visualChartData.isEmpty) return 100;
    final maxY = _visualChartData
        .map((point) => point.y)
        .reduce((a, b) => a > b ? a : b);
    return maxY + 1.4;
  }

  Widget _buildChart() {
    if (_visualChartData.isEmpty) {
      final isEnglish =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode ==
          'en';
      return Center(
        child: Text(
          isEnglish ? 'No weight records yet' : 'Sin registros de peso aún',
          style: TextStyle(
            color: SECONDARY_COLOR,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (_visualChartData.length - 1).toDouble(),
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
                  final label = _bottomLabels[index];
                  if (label == null) {
                    return const SizedBox.shrink();
                  }

                  final isFirst = index == _bottomLabels.keys.first;
                  final isLast = index == _bottomLabels.keys.last;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: isFirst ? 8 : 0,
                      right: isLast ? 8 : 0,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: SECONDARY_COLOR,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _visualChartData,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: SafeArea(
        bottom: true,
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
                    Center(
                      child: Text(
                        AppLocalizations.of(context, 'progreso'),
                        style: TextStyle(
                          color: WHITE,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context, 'peso'),
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
                          Text(
                            AppLocalizations.of(context, 'peso_actual'),
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
                    Text(
                      isEnglish ? 'Weight Progress' : 'Progreso de peso',
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
                          TextSpan(
                            text: isEnglish
                                ? 'Last 30 days '
                                : 'Últimos 30 días ',
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
