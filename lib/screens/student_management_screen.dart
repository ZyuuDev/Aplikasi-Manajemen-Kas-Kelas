import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/class_provider.dart';
import '../models/student.dart';
import '../theme.dart';

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends ConsumerState<StudentManagementScreen> {
  String _searchQuery = "";
  final _nameController = TextEditingController();
  final _nisController = TextEditingController();
  final _editNameController = TextEditingController();
  final _editNisController = TextEditingController();

  String _formatRupiah(int value) {
    return NumberFormat.currency(
      locale: 'id-ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  void _showAddStudentDialog() {
    _nameController.clear();
    _nisController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.userPlus, color: AppTheme.primaryEmerald),
            SizedBox(width: 8),
            Text('Tambah Siswa Baru'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'e.g. Rian Hidayat',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nisController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor Induk Siswa (NIS)',
                hintText: 'e.g. 220116',
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
            onPressed: () {
              final name = _nameController.text.trim();
              final nis = _nisController.text.trim();

              if (name.isEmpty || nis.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama dan NIS tidak boleh kosong.'),
                    backgroundColor: AppTheme.destructiveRose,
                  ),
                );
                return;
              }

              ref.read(classProvider.notifier).addStudent(name, nis);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Siswa $name berhasil ditambahkan!'),
                  backgroundColor: AppTheme.primaryEmerald,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(Student student) {
    _editNameController.text = student.name;
    _editNisController.text = student.nis;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.userCog, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Edit Data Siswa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _editNisController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'NIS',
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
            onPressed: () {
              final name = _editNameController.text.trim();
              final nis = _editNisController.text.trim();
              if (name.isEmpty || nis.isEmpty) return;
              ref.read(classProvider.notifier).updateStudent(student.id, name, nis);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data siswa berhasil diperbarui.'),
                  backgroundColor: AppTheme.primaryEmerald,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateConfirm(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.userX, color: AppTheme.destructiveRose),
            SizedBox(width: 8),
            Text('Nonaktifkan Siswa'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menonaktifkan ${student.name}? Siswa ini tidak akan tampil lagi di daftar, namun data transaksinya tetap tersimpan.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
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
              ref.read(classProvider.notifier).deactivateStudent(student.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student.name} telah dinonaktifkan.'),
                  backgroundColor: AppTheme.accentAmber,
                ),
              );
            },
            child: const Text('Ya, Nonaktifkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(Student student, int debt, int debtWeeks, String className) async {
    final message = 
      "Halo ${student.name}, ini pengingat dari Bendahara Kelas $className. 📢\n\n"
      "Kamu saat ini memiliki sisa tunggakan uang kas kelas sebesar *${_formatRupiah(debt)}* (selama *$debtWeeks minggu* berjalan).\n\n"
      "Mohon untuk segera melakukan pembayaran ke bendahara kelas ya. Terima kasih! 🙏";

    // Standard url encoding for message
    final encodedMessage = Uri.encodeComponent(message);
    
    // Using a mock phone number for simulation, or empty so WhatsApp opens contact selector
    final whatsappUrl = Uri.parse("https://wa.me/?text=$encodedMessage");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not launch $whatsappUrl";
      }
    } catch (e) {
      // Fallback: Show composed text copy dialog if url cannot launch
      _showCopyDialog(student.name, message);
    }
  }

  void _showCopyDialog(String studentName, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.message, color: Colors.green),
            SizedBox(width: 8),
            Text('Kirim Tagihan Kas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Salin pesan tagihan berikut untuk dikirim ke $studentName:', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF050810),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classProvider);
    
    // Filter students
    final filtered = state.students.where((std) {
      return std.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          std.nis.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Siswa'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        onPressed: _showAddStudentDialog,
        child: const Icon(LucideIcons.userPlus),
      ),
      body: Column(
        children: [
          // Row 1: Search Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cari Nama / NIS Siswa...',
                prefixIcon: Icon(LucideIcons.search, size: 20, color: AppTheme.textMuted),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Row 2: Header stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Siswa: ${filtered.length}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Minggu Ke-${state.elapsedWeeks}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: List view
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.users, size: 40, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text('Tidak ada data siswa ditemukan.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 80.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      final debt = state.getStudentDebt(student);
                      final debtWeeks = state.getStudentDebtWeeks(student);
                      final isLunas = debt <= 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ExpansionTile(
                          shape: const Border(), // Removes standard line border on open
                          leading: CircleAvatar(
                            backgroundColor: isLunas 
                                ? AppTheme.primaryEmerald.withOpacity(0.1) 
                                : AppTheme.destructiveRose.withOpacity(0.1),
                            foregroundColor: isLunas ? AppTheme.primaryEmerald : AppTheme.destructiveRose,
                            child: Text(
                              student.name[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Text(
                            'NIS: ${student.nis}',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: isLunas 
                                  ? AppTheme.primaryEmerald.withOpacity(0.1) 
                                  : AppTheme.destructiveRose.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isLunas ? 'Lunas' : 'Nunggak',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLunas ? AppTheme.primaryEmerald : AppTheme.destructiveRose,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  // Stats Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatDetail('Total Bayar', _formatRupiah(student.totalPaid), AppTheme.primaryEmerald),
                                      _buildStatDetail('Sisa Tunggakan', _formatRupiah(debt), isLunas ? AppTheme.successTeal : AppTheme.destructiveRose),
                                      _buildStatDetail('Tunggakan Minggu', '$debtWeeks Minggu', isLunas ? AppTheme.successTeal : AppTheme.accentAmber),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Action Buttons
                                  Row(
                                    children: [
                                      // Blast WhatsApp Button
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                                          ),
                                          onPressed: () => _launchWhatsApp(student, debt, debtWeeks, state.classInfo?.name ?? 'Kelas'),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.message, size: 16),
                                              SizedBox(width: 8),
                                              Text('Blast Tagihan WA', style: TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Edit & Deactivate Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                            tooltip: 'Edit Data Siswa',
                            icon: const Icon(LucideIcons.pencil, size: 16, color: Colors.blueAccent),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _showEditStudentDialog(student),
                          ),
                          const SizedBox(width: 6),
                          // Deactivate button
                          IconButton(
                            tooltip: 'Nonaktifkan Siswa',
                            icon: const Icon(LucideIcons.userX, size: 16, color: AppTheme.destructiveRose),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.destructiveRose.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _showDeactivateConfirm(student),
                          ),
                        ],
                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
