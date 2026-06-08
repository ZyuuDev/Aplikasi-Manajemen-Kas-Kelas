import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/class_provider.dart';
import '../models/expense.dart';
import '../theme.dart';

class ExpenseHistoryScreen extends ConsumerWidget {
  const ExpenseHistoryScreen({super.key});

  String _formatRupiah(int value) {
    return NumberFormat.currency(
      locale: 'id-ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Peralatan':
        return Colors.blueAccent;
      case 'Kegiatan':
        return AppTheme.accentAmber;
      case 'Sosial':
        return AppTheme.successTeal;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Peralatan':
        return LucideIcons.package;
      case 'Kegiatan':
        return LucideIcons.flag;
      case 'Sosial':
        return LucideIcons.heart;
      default:
        return LucideIcons.moreHorizontal;
    }
  }

  void _showDetailDialog(BuildContext context, ExpenseRecord expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      builder: (context) {
        final color = _categoryColor(expense.category);
        final formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(expense.date);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_categoryIcon(expense.category), color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expense.category,
                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detail rows
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF050810),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Column(
                  children: [
                    _detailRow('Tanggal', formattedDate),
                    const Divider(color: AppTheme.darkBorder, height: 16),
                    _detailRow('Kategori', expense.category),
                    const Divider(color: AppTheme.darkBorder, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nominal', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          _formatRupiah(expense.amount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.destructiveRose,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    if (expense.description.isNotEmpty &&
                        expense.description != expense.title) ...[
                      const Divider(color: AppTheme.darkBorder, height: 16),
                      _detailRow('Keterangan', expense.description),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Receipt indicator
              if (expense.receiptUrl != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.image, color: AppTheme.primaryEmerald, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Foto bukti nota telah diunggah oleh bendahara.',
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryEmerald),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.imageOff, color: AppTheme.textMuted, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Tidak ada foto nota yang dilampirkan.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classProvider);
    final expenses = state.expenses;

    // Group by category
    final categories = <String, List<ExpenseRecord>>{};
    for (final exp in expenses) {
      categories.putIfAbsent(exp.category, () => []).add(exp);
    }

    final totalExpense = expenses.fold<int>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pengeluaran'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppTheme.primaryEmerald, size: 20),
            tooltip: 'Segarkan',
            onPressed: () => ref.read(classProvider.notifier).loadClassData(),
          ),
        ],
      ),
      body: expenses.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.receipt, size: 48, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada pengeluaran tercatat.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary header
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF050810),
                    border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL PENGELUARAN',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(totalExpense),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.destructiveRose,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.destructiveRose.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.destructiveRose.withOpacity(0.2)),
                        ),
                        child: Text(
                          '${expenses.length} Transaksi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.destructiveRose,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expenses list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final color = _categoryColor(expense.category);
                      final formattedDate = DateFormat('d MMM yyyy', 'id_ID').format(expense.date);

                      return GestureDetector(
                        onTap: () => _showDetailDialog(context, expense),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(_categoryIcon(expense.category), color: color, size: 18),
                                ),
                                const SizedBox(width: 12),

                                // Title & date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              expense.category,
                                              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                          ),
                                          if (expense.receiptUrl != null) ...[
                                            const SizedBox(width: 6),
                                            Icon(LucideIcons.image, size: 10, color: AppTheme.primaryEmerald),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Amount
                                Text(
                                  '-${_formatRupiah(expense.amount)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.destructiveRose,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
