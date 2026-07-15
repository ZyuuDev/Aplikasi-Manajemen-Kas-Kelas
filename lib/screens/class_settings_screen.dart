import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/class_provider.dart';
import '../theme.dart';

class ClassSettingsScreen extends ConsumerStatefulWidget {
  const ClassSettingsScreen({super.key});

  @override
  ConsumerState<ClassSettingsScreen> createState() => _ClassSettingsScreenState();
}

class _ClassSettingsScreenState extends ConsumerState<ClassSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final _emailController = TextEditingController();
  final _holidayDescController = TextEditingController();
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _holidayDescController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadQris() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      setState(() {
        _isActionLoading = true;
      });

      await ref.read(classProvider.notifier).uploadQrisImage(File(pickedFile.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QRIS kelas berhasil diunggah!'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah QRIS: $e'),
            backgroundColor: AppTheme.destructiveRose,
          ),
        );
      }
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  void _showAddHolidayDialog() {
    DateTime selectedDate = DateTime.now();
    _holidayDescController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Minggu Libur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih tanggal dalam minggu libur tersebut. Sistem akan merekam awal minggu (Hari Senin) untuk dikecualikan.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              // Date Display
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const Icon(LucideIcons.calendar, color: AppTheme.primaryEmerald, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _holidayDescController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Libur',
                  hintText: 'e.g. Libur Semester, Idul Fitri',
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
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _isActionLoading = true;
                });
                try {
                  // Standardize to Monday of the selected week
                  final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
                  await ref.read(classProvider.notifier).addOffWeek(
                        startDate: monday,
                        description: _holidayDescController.text.trim(),
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Minggu libur berhasil ditambahkan!'),
                        backgroundColor: AppTheme.primaryEmerald,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menambahkan: $e'),
                        backgroundColor: AppTheme.destructiveRose,
                      ),
                    );
                  }
                } finally {
                  setState(() {
                    _isActionLoading = false;
                  });
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddAssistant() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      await ref.read(classProvider.notifier).addAssistantByEmail(email);
      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asisten berhasil didaftarkan!'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendaftarkan asisten: $e'),
            backgroundColor: AppTheme.destructiveRose,
          ),
        );
      }
    } finally {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Kelas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryEmerald,
          labelColor: AppTheme.primaryEmerald,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(LucideIcons.qrCode), text: 'QRIS Kas'),
            Tab(icon: Icon(LucideIcons.calendar), text: 'Minggu Libur'),
            Tab(icon: Icon(LucideIcons.users), text: 'Asisten'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // ── QRIS Tab ──
              _buildQrisTab(state),

              // ── Holiday Weeks Tab ──
              _buildHolidayTab(state),

              // ── Assistants Tab ──
              _buildAssistantsTab(state),
            ],
          ),
          if (_isActionLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrisTab(ClassState state) {
    final qrisUrl = state.classInfo?.qrisUrl;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.qrCode, color: AppTheme.primaryEmerald),
                    SizedBox(width: 8),
                    Text(
                      'QRIS Statis Kelas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unggah gambar QRIS merchant kelas Anda di sini. QRIS ini akan langsung ditampilkan di website transparansi agar siswa dapat membayar kas secara nontunai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                
                // Image Display Container
                Container(
                  height: 240,
                  width: 240,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: qrisUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            qrisUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.alertTriangle, color: AppTheme.destructiveRose, size: 32),
                                    SizedBox(height: 8),
                                    Text('Gagal memuat QRIS', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.imagePlus, color: AppTheme.textMuted, size: 48),
                              SizedBox(height: 12),
                              Text('Belum ada QRIS terunggah', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                ),
                
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _pickAndUploadQris,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(qrisUrl != null ? LucideIcons.refreshCw : LucideIcons.upload, size: 16),
                        const SizedBox(width: 8),
                        Text(qrisUrl != null ? 'Ganti Gambar QRIS' : 'Unggah Gambar QRIS'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHolidayTab(ClassState state) {
    final offWeeks = state.offWeeks;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Minggu Bebas Kas (Libur)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              TextButton.icon(
                onPressed: _showAddHolidayDialog,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Tambah'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryEmerald),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: offWeeks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.calendarDays, color: AppTheme.textMuted.withOpacity(0.4), size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada minggu libur yang dikecualikan.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Siswa akan ditagih penuh untuk setiap minggu berjalan.',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: offWeeks.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.darkBorder, height: 1),
                    itemBuilder: (context, index) {
                      final ow = offWeeks[index];
                      final formattedMonday = DateFormat('d MMM yyyy', 'id_ID').format(ow.startDate);
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(LucideIcons.calendarCheck, color: AppTheme.primaryEmerald, size: 18),
                        ),
                        title: Text(
                          ow.description ?? 'Libur Kelas',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Mulai Minggu: $formattedMonday',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2, color: AppTheme.destructiveRose, size: 18),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Minggu Libur'),
                                content: const Text('Apakah Anda yakin ingin menghapus pengecualian minggu libur ini? Tagihan siswa akan disesuaikan kembali.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: AppTheme.destructiveRose))),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() {
                                _isActionLoading = true;
                              });
                              try {
                                await ref.read(classProvider.notifier).deleteOffWeek(ow.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pengecualian libur berhasil dihapus!'),
                                      backgroundColor: AppTheme.primaryEmerald,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppTheme.destructiveRose),
                                  );
                                }
                              } finally {
                                setState(() {
                                  _isActionLoading = false;
                                });
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantsTab(ClassState state) {
    final assistants = state.assistants;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Asisten Bendahara (Multi-User)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan alamat email asisten kelas Anda. Pastikan rekan Anda sudah mendaftar akun di aplikasi SakuKelas.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          
          // Form Input Email
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g. asisten@domain.com',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleAddAssistant,
                  child: const Text('Tambah'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.darkBorder),
          const SizedBox(height: 16),
          const Text(
            'Daftar Asisten Aktif',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: assistants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.users, color: AppTheme.textMuted.withOpacity(0.4), size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada asisten terdaftar.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hanya Anda (Bendahara Utama) yang memiliki akses kelas.',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: assistants.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.darkBorder, height: 1),
                    itemBuilder: (context, index) {
                      final ca = assistants[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.user, color: Colors.cyan, size: 18),
                        ),
                        title: Text(
                          ca.email,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.userMinus, color: AppTheme.destructiveRose, size: 18),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Asisten'),
                                content: Text('Hapus izin asisten untuk email "${ca.email}"? Mereka tidak akan bisa lagi mengakses data kelas ini.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: AppTheme.destructiveRose))),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() {
                                _isActionLoading = true;
                              });
                              try {
                                await ref.read(classProvider.notifier).removeAssistant(ca.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Akses asisten dicabut!'),
                                      backgroundColor: AppTheme.primaryEmerald,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal mencabut akses: $e'), backgroundColor: AppTheme.destructiveRose),
                                  );
                                }
                              } finally {
                                setState(() {
                                  _isActionLoading = false;
                                });
                              }
                            }
                          },
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
