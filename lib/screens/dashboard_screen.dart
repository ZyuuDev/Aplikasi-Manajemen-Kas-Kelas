import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/class_provider.dart';
import '../theme.dart';
import 'batch_payment_screen.dart';
import 'expense_form_screen.dart';
import 'expense_history_screen.dart';
import 'special_collections_screen.dart';
import 'student_management_screen.dart';
import 'login_screen.dart';
import 'income_form_screen.dart';
import 'class_settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _leaderboardTab = "fame"; // "fame" | "debtors"

  String _formatRupiah(int value) {
    return NumberFormat.currency(
      locale: 'id-ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  void _showResetDialog(BuildContext context) {
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
  Widget build(BuildContext context) {
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

    // Grouping transactions for recent timeline list
    final incomes = state.students.flatMap((std) => std.payments.map((p) => {
          'id': p.id,
          'type': 'INCOME',
          'title': std.name,
          'subtitle': 'Iuran Kas',
          'amount': p.amount,
          'date': p.date,
        }));
    final miscIncomes = state.miscIncomes.map((misc) => {
          'id': misc.id,
          'type': 'INCOME',
          'title': 'Pemasukan Umum',
          'subtitle': misc.description,
          'amount': misc.amount,
          'date': misc.date,
        });
    final expenses = state.expenses.map((exp) => {
          'id': exp.id,
          'type': 'EXPENSE',
          'title': exp.title,
          'subtitle': exp.description,
          'amount': exp.amount,
          'date': exp.date,
        });

    final allActivities = [...incomes, ...miscIncomes, ...expenses];
    allActivities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final recentActivities = allActivities.take(5).toList();

    // Wall of Fame (Lunas) and Debtors (Tunggakan)
    final starStudents = [...state.students]
        .where((s) => state.getStudentDebt(s) <= 0)
        .toList()
      ..sort((a, b) => b.totalPaid.compareTo(a.totalPaid));

    final debtorStudents = [...state.students]
        .where((s) => state.getStudentDebt(s) > 0)
        .toList()
      ..sort((a, b) => state.getStudentDebt(b).compareTo(state.getStudentDebt(a)));

    // Expense breakdown by category
    final categoryTotals = <String, int>{};
    for (var exp in state.expenses) {
      final cat = exp.category.isNotEmpty ? exp.category : 'Lainnya';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + exp.amount;
    }

    // Calculate dynamic maxY for BarChart
    double maxVal = 200000.0;
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
      for (var misc in state.miscIncomes) {
        if ((misc.date.isAfter(weekStart) || misc.date.isAtSameMomentAs(weekStart)) &&
            misc.date.isBefore(weekEnd)) {
          income += misc.amount;
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
    final dynamicMaxY = maxVal * 1.15;

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
            tooltip: 'Keluar',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
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
                    icon: LucideIcons.plusSquare,
                    color: const Color(0xFF2DD4BF),
                    title: 'Masuk Umum',
                    subtitle: 'Catat pemasukan',
                    target: const IncomeFormScreen(),
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
                    subtitle: 'Histori & Batal Nota',
                    target: const ExpenseHistoryScreen(),
                  ),
                  _buildActionButton(
                    context: context,
                    icon: LucideIcons.users,
                    color: const Color(0xFF06B6D4),
                    title: 'Data Siswa',
                    subtitle: 'Teladan & Tagihan',
                    target: const StudentManagementScreen(),
                  ),
                  _buildActionButton(
                    context: context,
                    icon: LucideIcons.settings,
                    color: const Color(0xFF94A3B8),
                    title: 'Pengaturan',
                    subtitle: 'QRIS, Libur, Asisten',
                    target: const ClassSettingsScreen(),
                  ),
                  GestureDetector(
                    onTap: () => _showResetDialog(context),
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

              // Row 3: Wall of Fame vs Papan Tunggakan
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _leaderboardTab == "fame" ? LucideIcons.trophy : LucideIcons.alertTriangle,
                                color: _leaderboardTab == "fame" ? AppTheme.primaryEmerald : AppTheme.destructiveRose,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _leaderboardTab == "fame" ? 'Wall of Fame' : 'Papan Tunggakan',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _leaderboardTab == "fame"
                                  ? AppTheme.primaryEmerald.withOpacity(0.12)
                                  : AppTheme.destructiveRose.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _leaderboardTab == "fame"
                                    ? AppTheme.primaryEmerald.withOpacity(0.3)
                                    : AppTheme.destructiveRose.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _leaderboardTab == "fame" ? '${starStudents.length} Lunas' : '${debtorStudents.length} Siswa',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _leaderboardTab == "fame" ? AppTheme.primaryEmerald : AppTheme.destructiveRose,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Segmented Tab switcher (Full Width with Expanded to avoid overflow)
                      Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050810),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _leaderboardTab = "fame"),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _leaderboardTab == "fame" ? AppTheme.primaryEmerald.withOpacity(0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🥇 ', style: TextStyle(fontSize: 11)),
                                        Text(
                                          'Teladan (${starStudents.length})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _leaderboardTab == "fame" ? AppTheme.primaryEmerald : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _leaderboardTab = "debtors"),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _leaderboardTab == "debtors" ? AppTheme.destructiveRose.withOpacity(0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('⚠️ ', style: TextStyle(fontSize: 11)),
                                        Text(
                                          'Tunggakan (${debtorStudents.length})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _leaderboardTab == "debtors" ? AppTheme.destructiveRose : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // List items
                      if (_leaderboardTab == "fame")
                        starStudents.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text('Belum ada siswa yang lunas kas.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: starStudents.take(5).length,
                                separatorBuilder: (_, __) => const Divider(color: AppTheme.darkBorder, height: 1),
                                itemBuilder: (context, index) {
                                  final student = starStudents[index];
                                  final medal = index == 0 ? "🥇" : index == 1 ? "🥈" : index == 2 ? "🥉" : "${index + 1}";

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.primaryEmerald.withOpacity(0.15),
                                      child: Text(
                                        medal,
                                        style: TextStyle(
                                          fontSize: index < 3 ? 14 : 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryEmerald,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      student.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    subtitle: const Text('✓ Lunas Kas Semester Ini', style: TextStyle(fontSize: 10, color: AppTheme.primaryEmerald)),
                                    trailing: Text(
                                      _formatRupiah(student.totalPaid),
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                                    ),
                                  );
                                },
                              )
                      else
                        debtorStudents.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text('Keren! Semua siswa sudah lunas.', style: TextStyle(fontSize: 12, color: AppTheme.primaryEmerald)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: debtorStudents.take(5).length,
                                separatorBuilder: (_, __) => const Divider(color: AppTheme.darkBorder, height: 1),
                                itemBuilder: (context, index) {
                                  final student = debtorStudents[index];
                                  final debt = state.getStudentDebt(student);
                                  final weeks = state.getStudentDebtWeeks(student);

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.destructiveRose.withOpacity(0.15),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.destructiveRose),
                                      ),
                                    ),
                                    title: Text(
                                      student.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    subtitle: Text('$weeks minggu belum bayar', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                    trailing: Text(
                                      _formatRupiah(debt),
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.destructiveRose),
                                    ),
                                  );
                                },
                              ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Row 4: Cash Flow Bar Chart
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
              const SizedBox(height: 24),

              // Row 5: Expense Breakdown (Donut Chart)
              if (categoryTotals.isNotEmpty) ...[
                const Text(
                  'Alokasi Pengeluaran (Kategori)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 160,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 36,
                              sections: _generatePieSections(categoryTotals, state.totalExpense),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: categoryTotals.entries.map((entry) {
                            final color = _getCategoryColor(entry.key);
                            final percent = state.totalExpense > 0
                                ? ((entry.value / state.totalExpense) * 100).toStringAsFixed(0)
                                : "0";
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${entry.key} ($percent%)',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Row 6: Recent Activities
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Peralatan':
        return Colors.blueAccent;
      case 'Kegiatan':
        return AppTheme.accentAmber;
      case 'Sosial':
        return AppTheme.successTeal;
      case 'Konsumsi':
        return Colors.orangeAccent;
      case 'Fotokopi':
        return Colors.purpleAccent;
      default:
        return const Color(0xFF6366F1);
    }
  }

  List<PieChartSectionData> _generatePieSections(Map<String, int> totals, int totalExpense) {
    if (totalExpense <= 0) return [];
    return totals.entries.map((entry) {
      final color = _getCategoryColor(entry.key);
      final value = entry.value.toDouble();
      return PieChartSectionData(
        color: color,
        value: value,
        title: '',
        radius: 22,
      );
    }).toList();
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
    final start = DateTime(
      state.classInfo!.semesterStartDate.year,
      state.classInfo!.semesterStartDate.month,
      state.classInfo!.semesterStartDate.day,
    );

    return List.generate(state.elapsedWeeks, (index) {
      final weekStart = start.add(Duration(days: index * 7));
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
      for (var misc in state.miscIncomes) {
        if ((misc.date.isAfter(weekStart) || misc.date.isAtSameMomentAs(weekStart)) &&
            misc.date.isBefore(weekEnd)) {
          income += misc.amount;
        }
      }

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
