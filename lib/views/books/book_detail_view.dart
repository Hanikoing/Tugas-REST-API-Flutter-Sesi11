import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book_model.dart';
import '../../viewmodels/book_vm.dart';

class BookDetailView extends ConsumerStatefulWidget {
  final BookModel book;

  const BookDetailView({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<BookDetailView> createState() =>
      _BookDetailViewState();
}

class _BookDetailViewState extends ConsumerState<BookDetailView> {
  late BookModel book;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    book = widget.book;
  }

  Color _stockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  String _stockLabel(int stock) {
    return stock == 0 ? 'Habis' : '$stock buku';
  }

  Future<void> _editBook() async {
    final titleController = TextEditingController(text: book.title);
    final authorController = TextEditingController(text: book.author);
    final publisherController =
        TextEditingController(text: book.publisher ?? '');
    final isbnController = TextEditingController(text: book.isbn);
    final yearController =
        TextEditingController(text: book.publishedYear.toString());
    final stockController =
        TextEditingController(text: book.stock.toString());
    final descriptionController =
        TextEditingController(text: book.description ?? '');

    final formKey = GlobalKey<FormState>();

    try {
      final payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit Buku'),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildField(titleController, 'Judul Buku'),
                      _buildField(authorController, 'Penulis'),
                      _buildField(publisherController, 'Penerbit',
                          required: false),
                      _buildField(isbnController, 'ISBN'),
                      _buildField(
                        yearController,
                        'Tahun Terbit',
                        number: true,
                      ),
                      _buildField(
                        stockController,
                        'Stok',
                        number: true,
                      ),
                      _buildField(
                        descriptionController,
                        'Deskripsi',
                        required: false,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  Navigator.pop(dialogContext, {
                    'title': titleController.text.trim(),
                    'author': authorController.text.trim(),
                    'publisher':
                        publisherController.text.trim().isEmpty
                            ? null
                            : publisherController.text.trim(),
                    'isbn': isbnController.text.trim(),
                    'published_year': int.parse(yearController.text),
                    'stock': int.parse(stockController.text),
                    'description':
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                  });
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );

      if (payload == null || !mounted) return;

      final error = await ref
          .read(bookProvider.notifier)
          .update(book.id, payload);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ambil data terbaru dari state Riverpod.
      final updatedBook = ref
          .read(bookProvider)
          .books
          .where((b) => b.id == book.id)
          .firstOrNull;

      if (updatedBook != null) {
        book = updatedBook;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } finally {
      titleController.dispose();
      authorController.dispose();
      publisherController.dispose();
      isbnController.dispose();
      yearController.dispose();
      stockController.dispose();
      descriptionController.dispose();
    }
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label wajib diisi';
          }

          if (number && value != null && value.isNotEmpty) {
            final parsed = int.tryParse(value);
            if (parsed == null || parsed < 0) {
              return '$label harus berupa angka yang valid';
            }
          }

          return null;
        },
      ),
    );
  }

  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${book.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      isDeleting = true;
    });

    final error =
        await ref.read(bookProvider.notifier).delete(book.id);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buku berhasil dihapus'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  Widget _detailItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Buku'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            const Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'ID Buku: ${book.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailItem(
                      Icons.person_outline,
                      'Penulis',
                      book.author,
                    ),
                    const Divider(),
                    _detailItem(
                      Icons.business_outlined,
                      'Penerbit',
                      book.publisher ?? '-',
                    ),
                    const Divider(),
                    _detailItem(
                      Icons.qr_code,
                      'ISBN',
                      book.isbn,
                    ),
                    const Divider(),
                    _detailItem(
                      Icons.calendar_today,
                      'Tahun Terbit',
                      book.publishedYear.toString(),
                    ),
                    const Divider(),
                    _detailItem(
                      Icons.inventory_2_outlined,
                      'Stok Buku',
                      _stockLabel(book.stock),
                      valueColor: _stockColor(book.stock),
                    ),
                    const Divider(),
                    _detailItem(
                      Icons.description_outlined,
                      'Deskripsi',
                      book.description ?? 'Tidak ada deskripsi',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDeleting ? null : _editBook,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isDeleting ? null : _deleteBook,
                    icon: const Icon(Icons.delete),
                    label: Text(isDeleting ? 'Menghapus...' : 'Hapus'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
