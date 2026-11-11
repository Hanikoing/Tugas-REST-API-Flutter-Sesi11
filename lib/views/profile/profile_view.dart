
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routes/app_router.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/book_vm.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        ref.read(authProvider.notifier).loadProfile();
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tidak tersedia';

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => isLoggingOut = true);

    await ref.read(authProvider.notifier).logout();
    ref.read(bookProvider.notifier).reset();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  Widget _profileItem(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context)
                .colorScheme
                .primaryContainer,
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        centerTitle: true,
      ),
      body: auth.loading && user == null
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_off_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          auth.error ?? 'Data profil tidak tersedia.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(authProvider.notifier)
                              .loadProfile(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Text(
                              user.name.isEmpty
                                  ? '?'
                                  : user.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            user.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            user.email,
                            style: const TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 28),

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  _profileItem(
                                    Icons.person_outline,
                                    'Nama Lengkap',
                                    user.name,
                                  ),
                                  const Divider(height: 1),
                                  _profileItem(
                                    Icons.email_outlined,
                                    'Email',
                                    user.email,
                                  ),
                                  const Divider(height: 1),
                                  _profileItem(
                                    Icons.calendar_month_outlined,
                                    'Tanggal Bergabung',
                                    _formatDate(user.createdAt),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isLoggingOut ? null : _logout,
                              icon: const Icon(Icons.logout),
                              label: Text(
                                isLoggingOut ? 'Keluar...' : 'Logout',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
