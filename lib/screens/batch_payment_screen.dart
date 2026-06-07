import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/class_provider.dart';
import '../theme.dart';

class BatchPaymentScreen extends ConsumerStatefulWidget {
  const BatchPaymentScreen({super.key});

  @override
  ConsumerState<BatchPaymentScreen> createState() => _BatchPaymentScreenState();
}

class _BatchPaymentScreenState extends ConsumerState<BatchPaymentScreen> {
  final List<String> _selectedStudentIds = [];
  int _weeksCount = 1;
  final _customAmountController = TextEditingController();
  bool _useCustomAmount = false;

  String _formatRupiah(int value) {
    return NumberFormat.currency(
      locale: 'id-ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  void _handleSave(int weeklyFee) {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih minimal 1 siswa.'),
          backgroundColor: AppTheme.destructiveRose,
        ),
      );
      return;
    }

    final amountPerStudent = _useCustomAmount
        ? (int.tryParse(_customAmountController.text.replaceAll('.', '')) ?? 0)
        : (weeklyFee * _weeksCount);

    if (amountPerStudent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal pembayaran tidak valid.'),
          backgroundColor: AppTheme.destructiveRose,
        ),
      );
      return;
    }

    ref.read(classProvider.notifier).addPaymentBatch(
          _selectedStudentIds,
          amountPerStudent,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Berhasil mencatat pembayaran ${_selectedStudentIds.length} siswa sebesar ${_formatRupiah(amountPerStudent)} / siswa.',
        ),
        backgroundColor: AppTheme.primaryEmerald,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classProvider);
    final weeklyFee = state.classInfo!.weeklyFee;

    final amountPerStudent = _useCustomAmount
        ? (int.tryParse(_customAmountController.text.replaceAll('.', '')) ?? 0)
        : (weeklyFee * _weeksCount);

    final totalCollected = _selectedStudentIds.length * amountPerStudent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Massal'),
      ),
      body: Column(
        children: [
          // Row 1: Amount Configuration Panel
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nominal Pembayaran Iuran',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  
                  // Custom vs Weekly Toggle Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !_useCustomAmount ? AppTheme.primaryEmerald.withOpacity(0.1) : Colors.transparent,
                            side: BorderSide(
                              color: !_useCustomAmount ? AppTheme.primaryEmerald : AppTheme.darkBorder,
                            ),
                          ),
                          onPressed: () => setState(() => _useCustomAmount = false),
                          child: const Text('Kelipatan Mingguan', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _useCustomAmount ? AppTheme.primaryEmerald.withOpacity(0.1) : Colors.transparent,
                            side: BorderSide(
                              color: _useCustomAmount ? AppTheme.primaryEmerald : AppTheme.darkBorder,
                            ),
                          ),
                          onPressed: () => setState(() => _useCustomAmount = true),
                          child: const Text('Nominal Custom', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!_useCustomAmount)
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          const Text('Pilih Jumlah Minggu:', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildWeekOption(1),
                              const SizedBox(width: 6),
                              _buildWeekOption(2),
                              const SizedBox(width: 6),
                              _buildWeekOption(4),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    TextField(
                      controller: _customAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Masukkan Nominal Rupiah',
                        hintText: 'e.g. 50000',
                        prefixText: 'Rp ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                ],
              ),
            ),
          ),

          // Search & Multi-select Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Siswa Kelas (${state.students.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStudentIds.clear();
                          _selectedStudentIds.addAll(state.students.map((s) => s.id));
                        });
                      },
                      child: const Text('Pilih Semua', style: TextStyle(fontSize: 11)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStudentIds.clear();
                        });
                      },
                      child: const Text('Batal Semua', style: TextStyle(fontSize: 11, color: AppTheme.destructiveRose)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Row 2: List of Students
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: state.students.length,
              itemBuilder: (context, index) {
                final student = state.students[index];
                final isSelected = _selectedStudentIds.contains(student.id);
                final debt = state.getStudentDebt(student);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: CheckboxListTile(
                    activeColor: AppTheme.primaryEmerald,
                    title: Text(
                      student.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Row(
                      children: [
                        Text('NIS: ${student.nis}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        const SizedBox(width: 12),
                        if (debt > 0)
                          Text(
                            'Tunggakan: ${_formatRupiah(debt)}',
                            style: const TextStyle(fontSize: 10, color: AppTheme.destructiveRose, fontWeight: FontWeight.w600),
                          )
                        else
                          Text(
                            'Lunas',
                            style: const TextStyle(fontSize: 10, color: AppTheme.successTeal, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedStudentIds.add(student.id);
                        } else {
                          _selectedStudentIds.remove(student.id);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Row 3: Bottom Action Panel
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              border: const Border(top: BorderSide(color: AppTheme.darkBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedStudentIds.length} Siswa Terpilih',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRupiah(totalCollected),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _handleSave(weeklyFee),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.save, size: 16),
                        SizedBox(width: 8),
                        Text('Simpan Pembayaran'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekOption(int count) {
    final isSelected = _weeksCount == count;
    return ChoiceChip(
      selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryEmerald,
      label: Text(
        '$count Minggu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? AppTheme.primaryEmerald : AppTheme.textMuted,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _weeksCount = count;
          });
        }
      },
    );
  }
}
