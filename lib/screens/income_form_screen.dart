import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/class_provider.dart';
import '../theme.dart';

class IncomeFormScreen extends ConsumerStatefulWidget {
  const IncomeFormScreen({super.key});

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final amt = int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
      if (amt <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nominal pemasukan tidak valid.'),
            backgroundColor: AppTheme.destructiveRose,
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        await ref.read(classProvider.notifier).addMiscIncome(
              description: _descController.text.trim(),
              amount: amt,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pemasukan kelas berhasil dicatat!'),
              backgroundColor: AppTheme.primaryEmerald,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan pemasukan: $e'),
              backgroundColor: AppTheme.destructiveRose,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Pemasukan Lainnya'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Informational Card
            Card(
              color: AppTheme.primaryEmerald.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppTheme.primaryEmerald.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, color: AppTheme.primaryEmerald, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pemasukan ini dicatat sebagai saldo umum kelas (misal: donasi, hadiah lomba, sisa dana kegiatan) dan TIDAK dikaitkan dengan tunggakan siswa manapun.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Deskripsi Pemasukan
            const Text(
              'Deskripsi Pemasukan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Hadiah Juara 1 Kebersihan Kelas',
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Deskripsi wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Nominal
            const Text(
              'Nominal Pemasukan (Rp)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Masukkan nominal pemasukan',
              ),
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nominal wajib diisi.';
                }
                return null;
              },
              onChanged: (value) {
                if (value.isEmpty) return;
                // Simple formatting for thousands separators
                final clean = value.replaceAll('.', '');
                final valInt = int.tryParse(clean);
                if (valInt != null) {
                  final formatted = valInt.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      );
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
            const SizedBox(height: 36),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.save, size: 18),
                          SizedBox(width: 8),
                          Text('Simpan Pemasukan'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
