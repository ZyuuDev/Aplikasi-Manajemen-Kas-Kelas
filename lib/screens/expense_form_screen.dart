import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/class_provider.dart';
import '../theme.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  
  String _category = 'Peralatan';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengakses kamera/galeri: $e'),
          backgroundColor: AppTheme.destructiveRose,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: AppTheme.primaryEmerald),
              title: const Text('Ambil Foto Kamera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Colors.blueAccent),
              title: const Text('Pilih Dari Galeri', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final amt = int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
      if (amt <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nominal pengeluaran tidak valid.'),
            backgroundColor: AppTheme.destructiveRose,
          ),
        );
        return;
      }

      ref.read(classProvider.notifier).addExpense(
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            amount: amt,
            category: _category,
            receiptUrl: _imageFile?.path,
            receiptImageFile: _imageFile,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengeluaran berhasil dicatat!'),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Pengeluaran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppTheme.destructiveRose.withOpacity(0.05),
                  border: Border.all(color: AppTheme.destructiveRose.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.info, color: AppTheme.destructiveRose, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pencatatan ini akan langsung memotong sisa saldo kas kelas secara real-time.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Pengeluaran',
                  hintText: 'e.g. Beli Spidol Baru',
                  prefixIcon: Icon(LucideIcons.type, size: 18, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harap isi judul pengeluaran.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori Pengeluaran',
                  prefixIcon: Icon(LucideIcons.tag, size: 18, color: AppTheme.textMuted),
                ),
                dropdownColor: AppTheme.darkCard,
                items: ['Peralatan', 'Kegiatan', 'Sosial', 'Lainnya'].map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal Biaya',
                  hintText: 'e.g. 25000',
                  prefixIcon: Icon(LucideIcons.dollarSign, size: 18, color: AppTheme.textMuted),
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi nominal biaya.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Tambahan (Opsional)',
                  hintText: 'Tulis detail keperluan belanja barang...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Receipt Attachment Widget
              const Text(
                'Unggah Bukti Struk/Nota',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF050810),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: _imageFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: Image.file(
                                _imageFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.6),
                                radius: 14,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _imageFile = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.camera, size: 36, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            const Text(
                              'Klik untuk mengambil foto struk belanja',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Wajib melampirkan nota agar siswa dapat memverifikasi',
                              style: TextStyle(fontSize: 9, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _handleSave,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.save, size: 18),
                    SizedBox(width: 8),
                    Text('Simpan Pengeluaran Kas'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
