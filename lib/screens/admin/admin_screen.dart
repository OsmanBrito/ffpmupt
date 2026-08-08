import 'dart:async';

import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/screens/admin/country_admin_screen.dart';
import 'package:ffpmupt/screens/admin/country_readiness_screen.dart';
import 'package:ffpmupt/screens/admin/family_promise_admin_screen.dart';
import 'package:ffpmupt/screens/admin/holy_grounds_admin_screen.dart';
import 'package:ffpmupt/screens/admin/motto_admin_screen.dart';
import 'package:ffpmupt/screens/admin/operational_crm_screen.dart';
import 'package:ffpmupt/screens/admin/payment_settings_admin_screen.dart';
import 'package:ffpmupt/screens/admin/songs_admin_screen.dart';
import 'package:ffpmupt/screens/videos_screen.dart';
import 'package:ffpmupt/services/admin_auth_service.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/admin_copy.dart';
import 'package:ffpmupt/settings/p0_strings.dart';
import 'package:ffpmupt/widgets/language_menu_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.country});

  final CountryModel country;

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
  bool _isSuperAdmin = false;
  bool _isChecking = true;
  bool _isSigningIn = false;
  bool _obscurePassword = true;
  String? _loginMessage;

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
    final access = await _authService.getAccess(
      user,
      countryCode: widget.country.code,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _user = user;
      _isAdmin = access.canManageCountry;
      _isSuperAdmin = access.isSuperAdmin;
      _isChecking = false;
    });
  }

  Future<void> _signIn(AppStrings strings) async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _loginMessage = adminText(
          context,
          'Informe o email e a palavra-passe para continuar.',
        ),
      );
      return;
    }

    setState(() {
      _isSigningIn = true;
      _loginMessage = null;
    });

    try {
      final user = await _authService.signIn(email: email, password: password);
      final access = await _authService.getAccess(
        user,
        countryCode: widget.country.code,
      );
      if (!access.canManageCountry) {
        await _authService.signOut();
        if (mounted) {
          setState(
            () => _loginMessage =
                '${strings.adminAccessDenied}: ${widget.country.name}',
          );
        }
      }
    } on FirebaseAuthException {
      if (mounted) {
        setState(() => _loginMessage = strings.signInFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(
        () => _loginMessage = adminText(
          context,
          'Informe o email antes de redefinir a palavra-passe.',
        ),
      );
      return;
    }

    setState(() {
      _isSigningIn = true;
      _loginMessage = null;
    });
    try {
      await _authService.sendPasswordReset(email);
      if (mounted) {
        setState(
          () => _loginMessage = adminText(
            context,
            'Enviámos um email para redefinir a palavra-passe.',
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _loginMessage = _loginErrorMessage(error));
      }
    } on Object {
      if (mounted) {
        setState(
          () => _loginMessage = adminText(
            context,
            'Não foi possível enviar o email de recuperação.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  String _loginErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => adminText(context, 'O email não é válido.'),
      'user-not-found' => adminText(
        context,
        'Não encontrámos uma conta com este email.',
      ),
      'too-many-requests' => adminText(
        context,
        'Demasiadas tentativas. Aguarde e tente novamente.',
      ),
      _ => adminText(
        context,
        'Não foi possível enviar o email de recuperação.',
      ),
    };
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
          const LanguageMenuButton(),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 52,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '${strings.adminAccessDenied}: ${widget.country.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                adminText(
                  context,
                  'Peça ao coordenador um convite para este país ou troque de país antes de entrar.',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/request-access'),
                icon: const Icon(Icons.mark_email_unread_outlined),
                label: Text(adminText(context, 'Pedir acesso administrativo')),
              ),
            ],
          ),
        ),
      );
    }

    final p0 = P0Strings.of(AppLanguageScope.watch(context).language);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          strings.adminDashboard,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        if (_isSuperAdmin) ...[
          _AdminSectionTitle(title: p0[P0Text.adminOperations]),
          const SizedBox(height: 10),
          _AdminActionCard(
            icon: Icons.business_outlined,
            title: p0[P0Text.adminOperations],
            subtitle: p0[P0Text.checklistSubtitle],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OperationalCrmScreen(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _AdminSectionTitle(title: p0[P0Text.adminCountry]),
        const SizedBox(height: 10),
        _AdminActionCard(
          icon: Icons.fact_check_outlined,
          title: p0[P0Text.checklistTitle],
          subtitle: p0[P0Text.checklistSubtitle],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CountryReadinessScreen(country: widget.country),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdminActionCard(
          icon: Icons.public,
          title: strings.countrySettings,
          subtitle: strings.countrySettingsSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CountryAdminScreen(countryCode: widget.country.code),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _AdminSectionTitle(title: p0[P0Text.adminContent]),
        const SizedBox(height: 10),
        _AdminActionCard(
          icon: Icons.auto_stories_outlined,
          title: strings.familyPromise,
          subtitle: strings.familyPromiseSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  FamilyPromiseAdminScreen(country: widget.country),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdminActionCard(
          icon: Icons.auto_stories,
          title: strings.motto,
          subtitle: strings.mottoSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  MottoAdminScreen(countryCode: widget.country.code),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdminActionCard(
          icon: Icons.landscape_outlined,
          title: p0[P0Text.holyGrounds],
          subtitle: p0[P0Text.emptyHolyGroundsDescription],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HolyGroundsAdminScreen(
                countryCode: widget.country.code,
                defaultLanguage: widget.country.defaultLanguage,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdminActionCard(
          icon: Icons.library_music_outlined,
          title: strings.songs,
          subtitle: strings.songsSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SongsAdminScreen(
                countryCode: widget.country.code,
                defaultLanguage: widget.country.defaultLanguage,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdminActionCard(
          icon: Icons.payments_outlined,
          title: p0[P0Text.payments],
          subtitle: strings.offeringsSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PaymentSettingsAdminScreen(countryCode: widget.country.code),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdminActionCard(
          icon: Icons.ondemand_video,
          title: strings.weeklyVideos,
          subtitle: strings.weeklyVideosSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  VideosScreen(countryCode: widget.country.code),
            ),
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
              const SizedBox(height: 8),
              Text(
                '${adminText(context, 'Gerir conteúdo de')} ${widget.country.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xff65716c),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.done,
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
              if (_loginMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _loginMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                adminText(
                  context,
                  'Sem acesso? Peça um convite ao coordenador do FFPMU Connect com o seu país, nome e email.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/request-access'),
                icon: const Icon(Icons.mark_email_unread_outlined),
                label: Text(adminText(context, 'Pedir acesso administrativo')),
              ),
              TextButton(
                onPressed: _isSigningIn ? null : _resetPassword,
                child: Text(adminText(context, 'Esqueci a palavra-passe')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSectionTitle extends StatelessWidget {
  const _AdminSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
