import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/auth/data/datasources/auth_profile_remote_data_source.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  late final AuthProfileRemoteDataSource _profileDataSource;
  late AppUser _profile;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profile = widget.sessionController.currentUser;
    _profileDataSource = AuthProfileRemoteDataSourceImpl(
      ApiClient(baseUrl: AppConfig.apiBaseUrl),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final accessToken = widget.sessionController.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileDataSource.getMyProfile(accessToken);
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal memuat profil. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C0702),
        foregroundColor: Colors.white,
        title: const Text('Profil'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            _ProfileHeader(profile: _profile, isLoading: _isLoading),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _errorMessage!, onRetry: _loadProfile),
            ],
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Informasi Akun',
              children: [
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'User ID',
                  value: _profile.id.isEmpty ? '-' : _profile.id,
                ),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _profile.email.isEmpty ? '-' : _profile.email,
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Nomor Telepon',
                  value: _profile.phoneNumber?.isNotEmpty == true
                      ? _profile.phoneNumber!
                      : '-',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoSection(
              title: 'Status',
              children: [
                _StatusTile(
                  icon: Icons.person_outline,
                  label: 'Role',
                  value: _profile.role.apiValue,
                  color: const Color(0xFFD88A16),
                ),
                _StatusTile(
                  icon: _profile.isVerified
                      ? Icons.verified_outlined
                      : Icons.report_gmailerrorred_outlined,
                  label: 'Verifikasi',
                  value: _profile.isVerified
                      ? 'Terverifikasi'
                      : 'Belum verifikasi',
                  color: _profile.isVerified
                      ? const Color(0xFF1F8A5B)
                      : const Color(0xFFD88A16),
                ),
                _StatusTile(
                  icon: _profile.isActive
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  label: 'Akun',
                  value: _profile.isActive ? 'Aktif' : 'Nonaktif',
                  color: _profile.isActive
                      ? const Color(0xFF1F8A5B)
                      : const Color(0xFFB3261E),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isLoggingOut ? null : _logout,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1C0702),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.logout),
              label: Text(_isLoggingOut ? 'Keluar...' : 'Keluar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      await widget.sessionController.logout();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logout gagal. Coba lagi.')));
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.isLoading});

  final AppUser profile;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName.isEmpty ? 'Customer' : profile.fullName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C0702), Color(0xFF5B290F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFFFFE3BC),
            foregroundImage: profile.avatarUrl == null
                ? null
                : NetworkImage(profile.avatarUrl!),
            child: profile.avatarUrl == null
                ? const Icon(
                    Icons.person_outline,
                    size: 42,
                    color: Color(0xFF1C0702),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email.isEmpty
                      ? 'Email belum tersedia'
                      : profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFF3D7A9)),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFFB25F),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD88A16)),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDAD4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB3261E)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Ulangi')),
        ],
      ),
    );
  }
}
