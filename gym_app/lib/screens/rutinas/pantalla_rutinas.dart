import 'package:flutter/material.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  int _selectedTab = 0;
  String _selectedGoal = 'ganancia_muscular';
  final Set<String> _selectedDays = {'Lunes', 'Miércoles', 'Viernes'};
  int _openWeek = 0;
  int _waterCups = 0;
  String _mealFilter = 'Todos';

  static const _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  static const _goals = [
    _Goal('perdida_peso', 'Pérdida de Peso', 'Cardio + fuerza para acelerar el metabolismo.'),
    _Goal('ganancia_muscular', 'Ganancia Muscular', 'Fuerza e hipertrofia con progresión controlada.'),
    _Goal('tonificacion', 'Tonificación', 'Definición, resistencia y técnica limpia.'),
  ];

  static const _recipes = [
    _Recipe('Bowl de Avena Proteica', 'Desayuno', 'Avena, proteína, plátano y frutos secos.', 380, 22, 52, 8),
    _Recipe('Ensalada de Pollo Grillado', 'Almuerzo', 'Pechuga, vegetales, aguacate y vinagreta.', 320, 38, 12, 10),
    _Recipe('Smoothie Verde Energizante', 'Snack', 'Espinaca, mango, jengibre y leche de almendras.', 210, 8, 38, 4),
    _Recipe('Salmón con Quinoa', 'Cena', 'Salmón al horno, quinoa y brócoli al vapor.', 480, 42, 35, 16),
    _Recipe('Batido Post-Entreno', 'Post-Entreno', 'Proteína, plátano, mantequilla de maní y leche.', 260, 32, 28, 3),
  ];

  @override
  void initState() {
    super.initState();
    _loadWaterCups();
  }

  Future<void> _loadWaterCups() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _waterStorageKey();
    if (!mounted) return;
    setState(() => _waterCups = prefs.getInt(key) ?? 0);
  }

  Future<void> _setWaterCups(int value) async {
    final nextValue = value.clamp(0, 12);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterStorageKey(), nextValue);
    if (!mounted) return;
    setState(() => _waterCups = nextValue);
  }

  String _waterStorageKey() {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'jacek_water_$date';
  }

  List<_RoutineWeek> get _routineWeeks {
    switch (_selectedGoal) {
      case 'perdida_peso':
        return const [
          _RoutineWeek('Semana 1-2: Adaptación Metabólica', 'Descansos cortos para activar el metabolismo.', [
            _Exercise('Cardio Interválico HIIT', '1', '20 min', '—', 'Intensidad moderada-alta'),
            _Exercise('Sentadilla con peso corporal', '3', '15-20', '45s', ''),
            _Exercise('Press de pecho con mancuernas', '3', '12-15', '45s', ''),
            _Exercise('Remo con mancuerna', '3', '12-15', '45s', ''),
          ]),
          _RoutineWeek('Semana 3-4: Fuerza-Resistencia', 'Más intensidad combinando fuerza y cardio.', [
            _Exercise('Cardio Steady State', '1', '25 min', '—', 'Zona aeróbica'),
            _Exercise('Peso muerto rumano', '4', '12', '60s', '+5% peso'),
            _Exercise('Jalón al pecho polea', '4', '12', '60s', ''),
            _Exercise('Burpees', '3', '10', '60s', ''),
          ]),
        ];
      case 'tonificacion':
        return const [
          _RoutineWeek('Semana 1-2: Activación Muscular', 'Cargas moderadas y técnica impecable.', [
            _Exercise('Cardio suave bicicleta', '1', '15 min', '—', 'Calentamiento'),
            _Exercise('Sentadilla goblet', '3', '15', '60s', ''),
            _Exercise('Press de pecho en máquina', '3', '15', '60s', ''),
            _Exercise('Abdominales en banco', '3', '20', '45s', ''),
          ]),
          _RoutineWeek('Semana 3-4: Superseries', 'Combina ejercicios para maximizar definición.', [
            _Exercise('Press pecho + Remo', '4', '12+12', '75s', 'Superserie'),
            _Exercise('Sentadilla + Peso muerto rumano', '4', '12+12', '75s', 'Superserie'),
            _Exercise('Plancha + Mountain climbers', '3', '30s+20', '60s', 'Superserie'),
          ]),
        ];
      default:
        return const [
          _RoutineWeek('Semana 1-2: Base de Fuerza', 'Rango de 6-8 repeticiones con descanso completo.', [
            _Exercise('Press de banca barra', '4', '6-8', '2-3 min', 'Peso controlado'),
            _Exercise('Sentadilla trasera', '4', '6-8', '2-3 min', ''),
            _Exercise('Peso muerto convencional', '3', '5', '3 min', ''),
            _Exercise('Press militar barra', '4', '6-8', '2 min', ''),
          ]),
          _RoutineWeek('Semana 3-4: Hipertrofia', 'Rango 8-12 reps con tiempo bajo tensión.', [
            _Exercise('Press de pecho mancuernas', '4', '10-12', '90s', '+5% peso'),
            _Exercise('Hack squat / prensa', '4', '10-12', '90s', ''),
            _Exercise('Jalón al pecho cerrado', '4', '10-12', '90s', ''),
            _Exercise('Elevaciones laterales', '4', '12-15', '60s', ''),
          ]),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      appBar: AppBar(
        backgroundColor: DARKER_BG,
        elevation: 0,
        centerTitle: true,
        title: const Text('Rutinas', style: TextStyle(color: WHITE, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildSegmentedTabs(),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _selectedTab == 0 ? _buildRoutinesTab() : _buildNutritionTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: DARK_BG, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF262626))),
      child: Row(
        children: [
          _buildTabButton(0, 'Entrenamiento', Icons.fitness_center),
          _buildTabButton(1, 'Nutrición', Icons.restaurant_menu),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final active = _selectedTab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? PRIMARY_COLOR : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: WHITE, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: WHITE, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutinesTab() {
    final goal = _goals.firstWhere((item) => item.key == _selectedGoal);
    return Column(
      key: const ValueKey('routines'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Generador de rutina', style: TextStyle(color: WHITE, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Plan inicial de 4 semanas basado en objetivo y días disponibles.', style: TextStyle(color: SECONDARY_COLOR, fontSize: 13)),
        const SizedBox(height: 18),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Cuál es tu objetivo?', style: TextStyle(color: WHITE, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._goals.map(_buildGoalButton),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Qué días puedes entrenar?', style: TextStyle(color: WHITE, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: _days.map(_buildDayChip).toList()),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: PRIMARY_COLOR.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: PRIMARY_COLOR.withValues(alpha: 0.35))),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: PRIMARY_COLOR),
              const SizedBox(width: 12),
              Expanded(child: Text('Tu plan: ${goal.label} · ${_selectedDays.length} días/semana', style: const TextStyle(color: WHITE, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._routineWeeks.asMap().entries.map((entry) => _buildWeekCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildGoalButton(_Goal goal) {
    final active = _selectedGoal == goal.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedGoal = goal.key),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: active ? PRIMARY_COLOR.withValues(alpha: 0.14) : const Color(0xFF151515),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? PRIMARY_COLOR : const Color(0xFF262626)),
          ),
          child: Row(
            children: [
              Icon(active ? Icons.radio_button_checked : Icons.radio_button_off, color: active ? PRIMARY_COLOR : SECONDARY_COLOR, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.label, style: TextStyle(color: active ? WHITE : SECONDARY_COLOR, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(goal.description, style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(String day) {
    final active = _selectedDays.contains(day);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => active ? _selectedDays.remove(day) : _selectedDays.add(day)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(color: active ? PRIMARY_COLOR : const Color(0xFF151515), borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? PRIMARY_COLOR : const Color(0xFF262626))),
        child: Text(day, style: TextStyle(color: active ? WHITE : SECONDARY_COLOR, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildWeekCard(int index, _RoutineWeek week) {
    final open = _openWeek == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(color: DARK_BG, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF262626))),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _openWeek = open ? -1 : index),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(week.title, style: const TextStyle(color: WHITE, fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(week.description, style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12)),
                      ]),
                    ),
                    Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: open ? PRIMARY_COLOR : SECONDARY_COLOR),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(children: week.exercises.map(_buildExerciseCard).toList()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(_Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: PRIMARY_COLOR.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fitness_center, color: PRIMARY_COLOR, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exercise.name, style: const TextStyle(color: WHITE, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text('${exercise.series} series · ${exercise.reps} reps · descanso ${exercise.rest}', style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12)),
              if (exercise.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(exercise.note, style: const TextStyle(color: PRIMARY_COLOR, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTab() {
    const targetWater = 8;
    final waterPercent = (_waterCups / targetWater).clamp(0, 1).toDouble();
    final tags = ['Todos', ..._recipes.map((recipe) => recipe.tag).toSet()];
    final recipes = _mealFilter == 'Todos' ? _recipes : _recipes.where((recipe) => recipe.tag == _mealFilter).toList();

    return Column(
      key: const ValueKey('nutrition'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nutrición', style: TextStyle(color: WHITE, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Macros estimados, hidratación diaria y recetas saludables.', style: TextStyle(color: SECONDARY_COLOR, fontSize: 13)),
        const SizedBox(height: 18),
        _sectionCard(child: _buildMacroSection()),
        const SizedBox(height: 14),
        _sectionCard(child: _buildWaterSection(waterPercent, targetWater)),
        const SizedBox(height: 18),
        const Text('Recetario saludable', style: TextStyle(color: WHITE, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: tags.map(_buildMealFilterChip).toList()),
        ),
        const SizedBox(height: 14),
        ...recipes.map(_buildRecipeCard),
      ],
    );
  }

  Widget _buildMacroSection() {
    const calories = 2170;
    const protein = 126;
    const carbs = 285;
    const fats = 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [Icon(Icons.restaurant, color: PRIMARY_COLOR, size: 18), SizedBox(width: 8), Text('Calculadora de macros', style: TextStyle(color: WHITE, fontSize: 15, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PRIMARY_COLOR.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: PRIMARY_COLOR.withValues(alpha: 0.28))),
          child: const Column(children: [
            Text('Calorías diarias recomendadas', style: TextStyle(color: SECONDARY_COLOR, fontSize: 12)),
            SizedBox(height: 4),
            Text('$calories kcal', style: TextStyle(color: PRIMARY_COLOR, fontSize: 30, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: _MacroBadge('Proteínas', protein, 'g', Color(0xFFE53935))),
          SizedBox(width: 8),
          Expanded(child: _MacroBadge('Carbos', carbs, 'g', Color(0xFFFBC02D))),
          SizedBox(width: 8),
          Expanded(child: _MacroBadge('Grasas', fats, 'g', Color(0xFF1E88E5))),
        ]),
      ],
    );
  }

  Widget _buildWaterSection(double waterPercent, int targetWater) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.water_drop, color: Color(0xFF1E88E5), size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('Hidratación de hoy', style: TextStyle(color: WHITE, fontSize: 15, fontWeight: FontWeight.w800))),
            TextButton(onPressed: () => _setWaterCups(0), child: const Text('Reset', style: TextStyle(color: SECONDARY_COLOR, fontSize: 12))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roundAction(Icons.remove, () => _setWaterCups(_waterCups - 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(children: [
                Text('$_waterCups', style: TextStyle(color: _waterCups >= targetWater ? const Color(0xFF34D399) : const Color(0xFF1E88E5), fontSize: 46, fontWeight: FontWeight.w900)),
                Text('de $targetWater vasos', style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12)),
              ]),
            ),
            _roundAction(Icons.add, () => _setWaterCups(_waterCups + 1), color: const Color(0xFF1E88E5)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: waterPercent, minHeight: 7, backgroundColor: const Color(0xFF242424), color: _waterCups >= targetWater ? const Color(0xFF34D399) : const Color(0xFF1E88E5))),
      ],
    );
  }

  Widget _roundAction(IconData icon, VoidCallback onTap, {Color color = WHITE}) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.28))), child: Icon(icon, color: color, size: 19)),
    );
  }

  Widget _buildMealFilterChip(String tag) {
    final active = _mealFilter == tag;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _mealFilter = tag),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: active ? PRIMARY_COLOR : DARK_BG, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? PRIMARY_COLOR : const Color(0xFF262626))),
          child: Text(tag, style: TextStyle(color: active ? WHITE : SECONDARY_COLOR, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(_Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: DARK_BG, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF262626))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(recipe.name, style: const TextStyle(color: WHITE, fontSize: 15, fontWeight: FontWeight.w800))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: PRIMARY_COLOR.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)), child: Text(recipe.tag, style: const TextStyle(color: PRIMARY_COLOR, fontSize: 11, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 6),
          Text(recipe.description, style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12, height: 1.35)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _NutBadge('Kcal', '${recipe.calories}', PRIMARY_COLOR),
            _NutBadge('Prot', '${recipe.protein}g', const Color(0xFFE53935)),
            _NutBadge('Carbs', '${recipe.carbs}g', const Color(0xFFFBC02D)),
            _NutBadge('Grasas', '${recipe.fats}g', const Color(0xFF1E88E5)),
          ]),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: DARK_BG, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF262626))),
      child: child,
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;

  const _MacroBadge(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.24))),
      child: Column(children: [
        Text('$value$unit', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: SECONDARY_COLOR, fontSize: 10)),
      ]),
    );
  }
}

class _NutBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutBadge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: SECONDARY_COLOR, fontSize: 10)),
    ]);
  }
}

class _Goal {
  final String key;
  final String label;
  final String description;
  const _Goal(this.key, this.label, this.description);
}

class _RoutineWeek {
  final String title;
  final String description;
  final List<_Exercise> exercises;
  const _RoutineWeek(this.title, this.description, this.exercises);
}

class _Exercise {
  final String name;
  final String series;
  final String reps;
  final String rest;
  final String note;
  const _Exercise(this.name, this.series, this.reps, this.rest, this.note);
}

class _Recipe {
  final String name;
  final String tag;
  final String description;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  const _Recipe(this.name, this.tag, this.description, this.calories, this.protein, this.carbs, this.fats);
}
