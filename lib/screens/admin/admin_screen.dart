import 'dart:async';

import 'package:ffpmupt/screens/admin/country_admin_screen.dart';
import 'package:ffpmupt/screens/admin/songs_admin_screen.dart';
import 'package:ffpmupt/screens/videos_screen.dart';
import 'package:ffpmupt/services/admin_auth_service.dart';
import 'package:ffpmupt/services/weekly_videos_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _authService = AdminAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;
  User? _user;
  bool _isAdmin = false;
  bool _isChecking = true;
  bool _isSigningIn = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges().listen(_checkAccess);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess(User? user) async {
    final isAdmin = await _authService.isAdmin(
      user,
      countryCode: weeklyVideosCountryCode,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _user = user;
      _isAdmin = isAdmin;
      _isChecking = false;
    });
  }

  Future<void> _signIn(AppStrings strings) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      final user = await _authService.signIn(email: email, password: password);
      final isAdmin = await _authService.isAdmin(
        user,
        countryCode: weeklyVideosCountryCode,
      );
      if (!isAdmin) {
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(strings.adminAccessDenied)));
        }
      }
    } on FirebaseAuthException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.signInFailed)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.adminArea),
        actions: [
          if (_user != null)
            IconButton(
              tooltip: strings.signOut,
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _isChecking
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(strings),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppStrings strings) {
    if (_user == null) {
      return _buildLogin(strings);
    }

    if (!_isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.adminAccessDenied,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          strings.adminDashboard,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _AdminActionCard(
          icon: Icons.library_music_outlined,
          title: strings.songs,
          subtitle: strings.songsSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SongsAdminScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _AdminActionCard(
          icon: Icons.ondemand_video,
          title: strings.weeklyVideos,
          subtitle: strings.weeklyVideosSubtitle,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const VideosScreen())),
        ),
        const SizedBox(height: 12),
        _AdminActionCard(
          icon: Icons.public,
          title: strings.countrySettings,
          subtitle: strings.countrySettingsSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CountryAdminScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildLogin(AppStrings strings) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                strings.adminLogin,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: strings.adminEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _signIn(strings),
                decoration: InputDecoration(
                  labelText: strings.password,
                  prefixIcon: const Icon(Icons.password),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: strings.togglePasswordVisibility,
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isSigningIn ? null : () => _signIn(strings),
                icon: _isSigningIn
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(strings.signIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
