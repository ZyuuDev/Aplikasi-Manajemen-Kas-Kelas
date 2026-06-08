import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/class_provider.dart';
import '../theme.dart';
import 'batch_payment_screen.dart';
import 'expense_form_screen.dart';
import 'expense_history_screen.dart';
import 'special_collections_screen.dart';
import 'student_management_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatRupiah(int value) {
    return NumberFormat.currency(
      locale: 'id-ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    final yearController = TextEditingController(text: "2026/2027");
    final semesterController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppTheme.accentAmber),
            SizedBox(width: 8),
            Text('Tutup Buku Semester'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tindakan ini akan mengarsipkan seluruh riwayat kas semester saat ini, me-reset seluruh tunggakan siswa ke Rp0, dan memulai perhitungan kas baru dari tanggal hari ini.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(
                labelText: 'Tahun Ajaran Baru',
                hintText: 'e.g. 2026/2027',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: semesterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Semester Baru',
                hintText: 'e.g. 1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.destructiveRose,
            ),
            onPressed: () {
              final sem = int.tryParse(semesterController.text) ?? 1;
              ref.read(classProvider.notifier).resetSemester(
                    yearController.text.trim(),
                    sem,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tutup Buku Semester Berhasil! Kas di-reset.'),
                  backgroundColor: AppTheme.primaryEmerald,
                ),
              );
            },
            child: const Text('Ya, Tutup Buku'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
              ),
              SizedBox(height: 16),
              Text(
                'Sinkronisasi data kas...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertTriangle, color: AppTheme.destructiveRose, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Koneksi Database Gagal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(classProvider.notifier).loadClassData();
                  },
                  child: const Text('Coba Lagi'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.classInfo == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: AppTheme.accentAmber, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Data Kelas Tidak Ditemukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Grouping transactions for recent timeline list (merged payments and expenses)
    final incomes = state.students.flatMap((std) => std.payments.map((p) => {
          'id': p.id,
          'type': 'INCOME',
          'title': std.name,
          'subtitle': 'Iuran Kas',
          'amount': p.amount,
          'date': p.date,
        }));
    final expenses = state.expenses.map((exp) => {
          'id': exp.id,
          'type': 'EXPENSE',
          'title': exp.title,
          'subtitle': exp.description,
          'amount': exp.amount,
          'date': exp.date,
        });

    final allActivities = [...incomes, ...expenses];
    allActivities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Get latest 5 activities
    final recentActivities = allActivities.take(5).toList();

    // Calculate dynamic maxY for BarChart based on the maximum weekly income/expense
    double maxVal = 200000.0; // Default minimum maxY of 200k
    final chartStart = DateTime(
      state.classInfo!.semesterStartDate.year,
      state.classInfo!.semesterStartDate.month,
      state.classInfo!.semesterStartDate.day,
    );

    for (int index = 0; index < state.elapsedWeeks; index++) {
      final weekStart = chartStart.add(Duration(days: index * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      int income = 0;
      for (var std in state.students) {
        for (var pay in std.payments) {
          if ((pay.date.isAfter(weekStart) || pay.date.isAtSameMomentAs(weekStart)) &&
              pay.date.isBefore(weekEnd)) {
            income += pay.amount;
          }
        }
      }

      int expense = 0;
      for (var exp in state.expenses) {
        if ((exp.date.isAfter(weekStart) || exp.date.isAtSameMomentAs(weekStart)) &&
            exp.date.isBefore(weekEnd)) {
          expense += exp.amount;
        }
      }

      if (income > maxVal) maxVal = income.toDouble();
      if (expense > maxVal) maxVal = expense.toDouble();
    }
    final dynamicMaxY = maxVal * 1.15; // 15% headroom

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.school, color: AppTheme.primaryEmerald),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.classInfo!.name),
                Text(
                  'Semester ${state.classInfo!.semester} (${state.classInfo!.academicYear})',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppTheme.primaryEmerald, size: 20),
            tooltip: 'Segarkan Data',
            onPressed: () {
              ref.read(classProvider.notifier).loadClassData();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppTheme.textMuted),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryEmerald,
        backgroundColor: AppTheme.darkCard,
        onRefresh: () => ref.read(classProvider.notifier).loadClassData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // Row 1: Dashboard Metrics Card
            Card(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [AppTheme.darkCard, AppTheme.primaryEmerald.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SALDO KAS KELAS SAAT INI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryEmerald,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(state.liveBalance),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppTheme.darkBorder, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSubMetric(
                          icon: LucideIcons.trendingUp,
                          color: AppTheme.primaryEmerald,
                          label: 'Pemasukan',
                          value: _formatRupiah(state.totalIncome),
                        ),
                        _buildSubMetric(
                          icon: LucideIcons.trendingDown,
                          color: AppTheme.destructiveRose,
                          label: 'Pengeluaran',
                          value: _formatRupiah(state.totalExpense),
                        ),
                        _buildSubMetric(
                          icon: LucideIcons.alertCircle,
                          color: AppTheme.accentAmber,
                          label: 'Tunggakan',
                          value: _formatRupiah(state.totalDebt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Row 2: Action Menu
            const Text(
              'Tindakan Bendahara',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildActionButton(
                  context: context,
                  icon: LucideIcons.userCheck,
                  color: AppTheme.primaryEmerald,
                  title: 'Bayar Massal',
                  subtitle: 'Checklist iuran',
                  target: const BatchPaymentScreen(),
                ),
                _buildActionButton(
                  context: context,
                  icon: LucideIcons.receipt,
                  color: AppTheme.destructiveRose,
                  title: 'Catat Keluar',
                  subtitle: 'Input nota belanja',
                  target: const ExpenseFormScreen(),
                ),
                _buildActionButton(
                  context: context,
                  icon: LucideIcons.clipboardList,
                  color: const Color(0xFF8B5CF6),
                  title: 'Iuran Khusus',
                  subtitle: 'LKS, Study Tour, dll',
                  target: const SpecialCollectionsScreen(),
                ),
                _buildActionButton(
                  context: context,
                  icon: LucideIcons.fileText,
                  color: Colors.blueAccent,
                  title: 'Riwayat Keluar',
                  subtitle: 'Histori pengeluaran',
                  target: const ExpenseHistoryScreen(),
                ),
                _buildActionButton(
                  context: context,
                  icon: LucideIcons.users,
                  color: const Color(0xFF06B6D4),
                  title: 'Data Siswa',
                  subtitle: 'Nagih & Blast WA',
                  target: const StudentManagementScreen(),
                ),
                GestureDetector(
                  onTap: () => _showResetDialog(context, ref),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              LucideIcons.archive,
                              color: AppTheme.accentAmber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Tutup Buku',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  'Reset semester',
                                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Row 3: Cash Flow Chart Card
            const Text(
              'Grafik Arus Kas Mingguan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.trendingUp, color: AppTheme.primaryEmerald, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Uang Masuk vs Uang Keluar',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: dynamicMaxY,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final weekNum = value.toInt() + 1;
                                  // Show every odd week to avoid crowding on small screens
                                  if (weekNum % 2 == 1 && weekNum <= state.elapsedWeeks) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'W$weekNum',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const SizedBox.shrink();
                                  return Text(
                                    '${(value / 1000).toInt()}k',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: AppTheme.darkBorder,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: _generateBarGroups(state),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, color: AppTheme.primaryEmerald, size: 10),
                            SizedBox(width: 4),
                            Text('Masuk', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          ],
                        ),
                        SizedBox(width: 24),
                        Row(
                          children: [
                            Icon(Icons.circle, color: AppTheme.destructiveRose, size: 10),
                            SizedBox(width: 4),
                            Text('Keluar', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Row 4: Recent Activities
            const Text(
              'Aktivitas Terakhir',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivities.length,
                separatorBuilder: (context, index) => const Divider(color: AppTheme.darkBorder, height: 1),
                itemBuilder: (context, index) {
                  final act = recentActivities[index];
                  final isIncome = act['type'] == 'INCOME';
                  final date = act['date'] as DateTime;
                  final formattedDate = DateFormat('d MMM yyyy', 'id_ID').format(date);

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? AppTheme.primaryEmerald.withOpacity(0.1)
                            : AppTheme.destructiveRose.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                        color: isIncome ? AppTheme.primaryEmerald : AppTheme.destructiveRose,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      act['title'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      '${act['subtitle']} • $formattedDate',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}${_formatRupiah(act['amount'] as int)}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? AppTheme.primaryEmerald : AppTheme.destructiveRose,
                      ),
                    ),
                  );
                },
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMetric({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget target,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => target),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(ClassState state) {
    // Generate bar groups for elapsed weeks
    final start = DateTime(
      state.classInfo!.semesterStartDate.year,
      state.classInfo!.semesterStartDate.month,
      state.classInfo!.semesterStartDate.day,
    );

    return List.generate(state.elapsedWeeks, (index) {
      final weekStart = start.add(Duration(days: index * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Calculate weekly income
      int income = 0;
      for (var std in state.students) {
        for (var pay in std.payments) {
          if ((pay.date.isAfter(weekStart) || pay.date.isAtSameMomentAs(weekStart)) &&
              pay.date.isBefore(weekEnd)) {
            income += pay.amount;
          }
        }
      }

      // Calculate weekly expense
      int expense = 0;
      for (var exp in state.expenses) {
        if ((exp.date.isAfter(weekStart) || exp.date.isAtSameMomentAs(weekStart)) &&
            exp.date.isBefore(weekEnd)) {
          expense += exp.amount;
        }
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: income.toDouble(),
            color: AppTheme.primaryEmerald,
            width: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: expense.toDouble(),
            color: AppTheme.destructiveRose,
            width: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
