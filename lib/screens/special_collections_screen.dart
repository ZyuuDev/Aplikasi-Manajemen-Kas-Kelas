import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/class_provider.dart';
import '../models/special_collection.dart';
import '../models/student.dart';
import '../theme.dart';

class SpecialCollectionsScreen extends ConsumerStatefulWidget {
  const SpecialCollectionsScreen({super.key});

  @override
  ConsumerState<SpecialCollectionsScreen> createState() =>
      _SpecialCollectionsScreenState();
}

class _SpecialCollectionsScreenState
    extends ConsumerState<SpecialCollectionsScreen> {
  String _formatRupiah(int value) {
    return NumberFormat.currency(
      locale: 'id-ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  void _openCreateDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.plusCircle, color: AppTheme.primaryEmerald),
            SizedBox(width: 10),
            Text('Buat Iuran Baru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Iuran *',
                  hintText: 'Contoh: LKS PJOK, Study Tour...',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama iuran wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp) *',
                  hintText: 'Contoh: 50000',
                  prefixIcon: Icon(LucideIcons.badgeDollarSign, size: 18),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nominal wajib diisi';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) {
                    return 'Masukkan nominal yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                  hintText: 'Misal: Untuk pembelian buku LKS semester 2',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.save, size: 16),
            label: const Text('Buat Iuran'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(classProvider.notifier)
                    .createSpecialCollection(
                      name: nameCtrl.text.trim(),
                      amount: int.parse(amountCtrl.text.trim()),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Iuran baru berhasil dibuat!'),
                      backgroundColor: AppTheme.primaryEmerald,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: AppTheme.destructiveRose,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _openChecklist(SpecialCollection collection, List<Student> students) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChecklistScreen(
          collection: collection,
          students: students,
        ),
      ),
    );
  }

  void _confirmDelete(SpecialCollection collection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.trash2, color: AppTheme.destructiveRose),
            SizedBox(width: 8),
            Text('Hapus Iuran'),
          ],
        ),
        content: Text(
          'Hapus iuran "${collection.name}"? Semua data pembayaran iuran ini akan ikut terhapus.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.destructiveRose,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(classProvider.notifier)
                  .deleteSpecialCollection(collection.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Iuran berhasil dihapus.'),
                    backgroundColor: AppTheme.accentAmber,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classProvider);
    final collections = state.specialCollections;
    final students = state.students;
    final totalStudents = students.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iuran Khusus'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw,
                color: AppTheme.primaryEmerald, size: 20),
            tooltip: 'Segarkan',
            onPressed: () => ref.read(classProvider.notifier).loadClassData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plusCircle, size: 20),
        label: const Text('Buat Iuran Baru',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
            )
          : collections.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    final paidCount = col.paidCount;
                    final progress = totalStudents > 0
                        ? paidCount / totalStudents
                        : 0.0;
                    final isPerfect = paidCount == totalStudents && totalStudents > 0;

                    return GestureDetector(
                      onTap: () => _openChecklist(col, students),
                      onLongPress: () => _confirmDelete(col),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isPerfect
                                          ? AppTheme.primaryEmerald.withOpacity(0.15)
                                          : AppTheme.accentAmber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPerfect
                                          ? LucideIcons.checkCircle2
                                          : LucideIcons.clipboardList,
                                      color: isPerfect
                                          ? AppTheme.primaryEmerald
                                          : AppTheme.accentAmber,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title & amount
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          col.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (col.description != null &&
                                            col.description!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              col.description!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatRupiah(col.amount),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.primaryEmerald,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isPerfect
                                          ? AppTheme.primaryEmerald.withOpacity(0.15)
                                          : AppTheme.accentAmber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isPerfect
                                            ? AppTheme.primaryEmerald.withOpacity(0.3)
                                            : AppTheme.accentAmber.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '$paidCount/$totalStudents',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isPerfect
                                            ? AppTheme.primaryEmerald
                                            : AppTheme.accentAmber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Progress Bar
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$paidCount dari $totalStudents siswa sudah bayar',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).round()}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isPerfect
                                              ? AppTheme.primaryEmerald
                                              : AppTheme.accentAmber,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 5,
                                      backgroundColor: AppTheme.darkBorder,
                                      color: isPerfect
                                          ? AppTheme.primaryEmerald
                                          : AppTheme.accentAmber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Actions Row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(LucideIcons.clipboardCheck,
                                          size: 15),
                                      label: const Text('Atur Pembayaran',
                                          style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryEmerald,
                                        side: const BorderSide(
                                            color: AppTheme.primaryEmerald),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                      onPressed: () =>
                                          _openChecklist(col, students),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Hapus Iuran',
                                    icon: const Icon(LucideIcons.trash2,
                                        color: AppTheme.destructiveRose, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.destructiveRose.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _confirmDelete(col),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.clipboardList,
                size: 48,
                color: AppTheme.primaryEmerald,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Iuran Khusus',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat iuran baru untuk mencatat\npembayaran non-rutin seperti LKS,\nStudy Tour, atau biaya khusus lainnya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.plusCircle, size: 18),
              label: const Text('Buat Iuran Pertama'),
              onPressed: _openCreateDialog,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checklist Screen (untuk mengatur siapa saja yang sudah bayar)
// ─────────────────────────────────────────────────────────────────────────────

class _ChecklistScreen extends ConsumerStatefulWidget {
  final SpecialCollection collection;
  final List<Student> students;

  const _ChecklistScreen({
    required this.collection,
    required this.students,
  });

  @override
  ConsumerState<_ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<_ChecklistScreen> {
  late Set<String> _checkedIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with currently paid students
    _checkedIds = Set.from(widget.collection.paidStudentIds);
  }

  String _formatRupiah(int value) {
    return NumberFormat.currency(
      locale: 'id-ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(classProvider.notifier).updateSpecialCollectionPayments(
            collectionId: widget.collection.id,
            paidStudentIds: _checkedIds.toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status pembayaran berhasil disimpan! ✓'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppTheme.destructiveRose,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = widget.students.length;
    final paidCount = _checkedIds.length;
    final unpaidCount = totalStudents - paidCount;
    final progress = totalStudents > 0 ? paidCount / totalStudents : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.collection.name,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.save, size: 16),
            label: const Text('Simpan',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Summary Header Card
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF050810),
              border: Border(
                  bottom: BorderSide(color: AppTheme.darkBorder)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Collection info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.collection.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          if (widget.collection.description != null &&
                              widget.collection.description!.isNotEmpty)
                            Text(
                              widget.collection.description!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textMuted),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(widget.collection.amount) +
                                ' / siswa',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stats column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatChip(
                          '$paidCount Lunas',
                          AppTheme.primaryEmerald,
                          LucideIcons.checkCircle2,
                        ),
                        const SizedBox(height: 6),
                        _buildStatChip(
                          '$unpaidCount Belum',
                          AppTheme.destructiveRose,
                          LucideIcons.xCircle,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: $paidCount/$totalStudents',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textMuted),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryEmerald),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppTheme.darkBorder,
                        color: progress == 1.0
                            ? AppTheme.primaryEmerald
                            : AppTheme.accentAmber,
                      ),
                    ),
                  ],
                ),

                // Quick select row
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(LucideIcons.checkSquare, size: 14),
                      label: const Text('Semua Bayar',
                          style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryEmerald,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4)),
                      onPressed: () {
                        setState(() {
                          _checkedIds =
                              widget.students.map((s) => s.id).toSet();
                        });
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(LucideIcons.square, size: 14),
                      label: const Text('Kosongkan',
                          style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4)),
                      onPressed: () {
                        setState(() {
                          _checkedIds = {};
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Student Checklist
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                final isPaid = _checkedIds.contains(student.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isPaid) {
                        _checkedIds.remove(student.id);
                      } else {
                        _checkedIds.add(student.id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppTheme.primaryEmerald.withOpacity(0.08)
                          : AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPaid
                            ? AppTheme.primaryEmerald.withOpacity(0.3)
                            : AppTheme.darkBorder,
                        width: isPaid ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Rank / Number
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),

                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isPaid
                                ? AppTheme.primaryEmerald.withOpacity(0.2)
                                : AppTheme.darkMuted,
                            foregroundColor: isPaid
                                ? AppTheme.primaryEmerald
                                : AppTheme.textMuted,
                            child: Text(
                              student.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name & NIS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isPaid
                                        ? Colors.white
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                Text(
                                  'NIS: ${student.nis}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),

                          // Status
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: isPaid
                                ? Container(
                                    key: const ValueKey('paid'),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryEmerald
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppTheme.primaryEmerald
                                              .withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.check,
                                            size: 12,
                                            color: AppTheme.primaryEmerald),
                                        SizedBox(width: 4),
                                        Text(
                                          'LUNAS',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryEmerald),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    key: const ValueKey('unpaid'),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.darkBorder,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'BELUM',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textMuted),
                                    ),
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

      // Bottom Save Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF050810),
            border:
                Border(top: BorderSide(color: AppTheme.darkBorder)),
          ),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.save, size: 18),
            label: Text(
              _isSaving
                  ? 'Menyimpan...'
                  : 'Simpan Status ($paidCount Lunas)',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
