
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routes/app_router.dart';
import '../../models/book_model.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/book_vm.dart';
import '../../widgets/book_card.dart';
import '../../widgets/responsive_layout.dart';
import 'book_form_dialog.dart';

class BooksView extends ConsumerStatefulWidget {
  const BooksView({super.key});

  @override
  ConsumerState<BooksView> createState() => _BooksViewState();
}

class _BooksViewState extends ConsumerState<BooksView> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Timer? _debounce;

  BookNotifier get _vm => ref.read(bookProvider.notifier);

  @override
  void initState() {
    super.initState();

    _scrollCtrl.addListener(_onScroll);

    Future.microtask(() => _vm.load(search: ''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // PENCARIAN OTOMATIS (DEBOUNCE 500 MS)
  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;
        _vm.load(search: value);
      },
    );
  }

  void _onScroll() {
    if (_scrollCtrl.position.extentAfter < 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final err = await _vm.loadMore();

    if (err != null) {
      _toast(err, isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  // TAMBAH DAN EDIT BUKU
  Future<void> _openForm([BookModel? book]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookFormDialog(
        book: book,
        onSubmit: (payload) {
          return book == null
              ? _vm.create(payload)
              : _vm.update(book.id, payload);
        },
      ),
    );

    if (saved == true) {
      _toast(
        book == null
            ? 'Buku berhasil ditambahkan'
            : 'Perubahan berhasil disimpan',
      );
    }
  }

  // HAPUS BUKU
  Future<void> _confirmDelete(BookModel book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text('Hapus "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final err = await _vm.delete(book.id);

    _toast(
      err ?? 'Buku berhasil dihapus',
      isError: err != null,
    );
  }

  // LOGOUT
  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();

    _vm.reset();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  // NAVIGASI PROFIL
  void _openProfile() {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  // TAMPILAN DAFTAR BUKU
  Widget _body(BookState state) {
    if (state.loading && state.books.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _vm.load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _vm.load(),
      child: state.books.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    state.search.isEmpty
                        ? 'Belum ada buku.'
                        : 'Tidak ada buku untuk "${state.search}".',
                  ),
                ),
              ],
            )
          : ListView.separated(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: state.books.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (ctx, i) {
                if (i == state.books.length) {
                  return _footer(state);
                }

                final book = state.books[i];

                return BookCard(
                  key: ValueKey(book.id),
                  book: book,
                  onEdit: () => _openForm(book),
                  onDelete: () => _confirmDelete(book),
                );
              },
            ),
    );
  }

  // FOOTER PAGINATION
  Widget _footer(BookState state) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.hasMore) {
      return Center(
        child: TextButton(
          onPressed: _loadMore,
          child: const Text('Muat lebih banyak'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          '${state.books.length} dari ${state.total} buku',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookProvider);

    ref.listen(bookProvider.select((s) => s.error), (_, next) {
      if (next != null &&
          ref.read(bookProvider).books.isNotEmpty) {
        _toast(next, isError: true);
      }
    });

    final userName =
        ref.watch(authProvider.select((s) => s.user?.name)) ?? '';

    // APP BAR
    final appBar = AppBar(
      title: const Text('Daftar Buku'),
      bottom: state.loading && state.books.isNotEmpty
          ? const PreferredSize(
              preferredSize: Size.fromHeight(2),
              child: LinearProgressIndicator(minHeight: 2),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Muat ulang',
          onPressed: state.loading ? null : () => _vm.load(),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profil',
          onPressed: _openProfile,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      ],
    );

    // SEARCH BAR DENGAN DEBOUNCE
    final searchBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari judul / penulis...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Hapus pencarian',
            onPressed: () {
              _debounce?.cancel();
              _searchCtrl.clear();
              _vm.load(search: '');
            },
          ),
        ),

        // PENCARIAN OTOMATIS 500 MS
        onChanged: _onSearchChanged,

        // ENTER UNTUK LANGSUNG MENCARI
        onSubmitted: (value) {
          _debounce?.cancel();
          _vm.load(search: value);
        },
      ),
    );

    // TOMBOL TAMBAH
    final fab = FloatingActionButton.extended(
      onPressed: () => _openForm(),
      icon: const Icon(Icons.add),
      label: const Text('Tambah'),
    );

    // KONTEN UTAMA
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchBar,
        Expanded(
          child: _body(state),
        ),
      ],
    );

    // RESPONSIVE LAYOUT
    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: appBar,
        body: content,
        floatingActionButton: fab,
      ),

      desktop: Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.library_books),
                  label: Text('Buku'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  label: Text('Profil'),
                ),
              ],
              selectedIndex: 0,
              onDestinationSelected: (index) {
                if (index == 1) {
                  _openProfile();
                }
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      child: Text(
                        userName.isEmpty
                            ? '?'
                            : userName[0].toUpperCase(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 72,
                      child: Text(
                        userName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 1),

            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                  ),
                  child: content,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: fab,
      ),
    );
  }
}
