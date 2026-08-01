import 'package:ffpmupt/models/operational_crm.dart';
import 'package:ffpmupt/services/operational_crm_repository.dart';
import 'package:ffpmupt/settings/admin_copy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum _InviteAuthMode { createAccount, signIn }

class AdminInviteScreen extends StatefulWidget {
  const AdminInviteScreen({super.key, required this.inviteId});

  final String inviteId;

  @override
  State<AdminInviteScreen> createState() => _AdminInviteScreenState();
}

class _AdminInviteScreenState extends State<AdminInviteScreen> {
  final _repository = OperationalCrmRepository();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _InviteAuthMode _mode = _InviteAuthMode.createAccount;
  User? _user;
  AdminInvite? _invite;
  bool _isBusy = false;
  bool _accepted = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _loadInvite();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadInvite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed?.emailVerified == true) {
        await refreshed?.getIdToken(true);
      }
      final invite = await _repository.loadInviteForUser(widget.inviteId);
      if (!mounted) {
        return;
      }
      setState(() {
        _user = refreshed;
        _invite = invite;
      });
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.code == 'permission-denied'
              ? adminText(
                  context,
                  'Esta conta não corresponde ao email do convite.',
                )
              : adminText(context, 'Não foi possível abrir o convite.');
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _message = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 8) {
      setState(
        () => _message = adminText(
          context,
          'Informe um email e uma senha com 8 caracteres.',
        ),
      );
      return;
    }
    if (_mode == _InviteAuthMode.createAccount &&
        password != _confirmPasswordController.text) {
      setState(() => _message = adminText(context, 'As senhas não coincidem.'));
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      final credential = _mode == _InviteAuthMode.createAccount
          ? await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            )
          : await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
      final user = credential.user;
      if (_mode == _InviteAuthMode.createAccount && user != null) {
        await user.sendEmailVerification();
      }
      if (!mounted) {
        return;
      }
      setState(() => _user = user);
      await _loadInvite();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = _authErrorMessage(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _sendVerification() async {
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        setState(
          () => _message = adminText(context, 'Email de confirmação enviado.'),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = _authErrorMessage(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(
        () => _message = adminText(context, 'Informe o email primeiro.'),
      );
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (mounted) {
      setState(
        () => _message = adminText(
          context,
          'Email para redefinir a senha enviado.',
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      setState(() {
        _user = null;
        _invite = null;
        _message = null;
      });
    }
  }

  Future<void> _accept() async {
    final user = FirebaseAuth.instance.currentUser;
    final invite = _invite;
    if (user == null || invite == null) {
      return;
    }
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await _repository.acceptInvite(invite: invite, user: user);
      if (mounted) {
        setState(() => _accepted = true);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _message = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(adminText(context, 'Convite de administrador')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: _accepted
                  ? _AcceptedInvite(
                      onContinue: () {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                    )
                  : _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final user = _user;
    if (user == null) {
      return _buildAuthentication(context);
    }
    if (!user.emailVerified) {
      return _buildVerification(context, user);
    }
    return _buildAcceptance(context, user);
  }

  Widget _buildAuthentication(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 52),
        const SizedBox(height: 14),
        Text(
          adminText(context, 'Você foi convidado para administrar um país'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        SegmentedButton<_InviteAuthMode>(
          segments: [
            ButtonSegment(
              value: _InviteAuthMode.createAccount,
              label: Text(adminText(context, 'Criar conta')),
              icon: const Icon(Icons.person_add_alt_1),
            ),
            ButtonSegment(
              value: _InviteAuthMode.signIn,
              label: Text(adminText(context, 'Já tenho conta')),
              icon: const Icon(Icons.login),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) {
            setState(() {
              _mode = selection.first;
              _message = null;
            });
          },
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: adminText(context, 'Email que recebeu o convite'),
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: adminText(context, 'Senha'),
            prefixIcon: const Icon(Icons.password),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_mode == _InviteAuthMode.createAccount) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            onSubmitted: (_) => _authenticate(),
            decoration: InputDecoration(
              labelText: adminText(context, 'Confirmar senha'),
              prefixIcon: const Icon(Icons.password),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isBusy ? null : _authenticate,
          icon: _isBusy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _mode == _InviteAuthMode.createAccount
                      ? Icons.person_add_alt_1
                      : Icons.login,
                ),
          label: Text(
            adminText(
              context,
              _mode == _InviteAuthMode.createAccount ? 'Criar conta' : 'Entrar',
            ),
          ),
        ),
        if (_mode == _InviteAuthMode.signIn)
          TextButton(
            onPressed: _isBusy ? null : _resetPassword,
            child: Text(adminText(context, 'Esqueci minha senha')),
          ),
      ],
    );
  }

  Widget _buildVerification(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.outgoing_mail, size: 52),
        const SizedBox(height: 14),
        Text(
          adminText(context, 'Confirme seu email'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          '${adminText(context, 'Enviamos uma confirmação para')} '
          '${user.email}. ${adminText(context, 'Abra o email e depois volte aqui.')}',
          textAlign: TextAlign.center,
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isBusy ? null : _loadInvite,
          icon: const Icon(Icons.refresh),
          label: Text(adminText(context, 'Já confirmei')),
        ),
        TextButton(
          onPressed: _isBusy ? null : _sendVerification,
          child: Text(adminText(context, 'Reenviar confirmação')),
        ),
        TextButton(
          onPressed: _signOut,
          child: Text(adminText(context, 'Usar outra conta')),
        ),
      ],
    );
  }

  Widget _buildAcceptance(BuildContext context, User user) {
    final invite = _invite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.admin_panel_settings_outlined, size: 52),
        const SizedBox(height: 14),
        Text(
          adminText(context, 'Confirmar acesso administrativo'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        if (_isBusy && invite == null)
          const Center(child: CircularProgressIndicator()),
        if (invite != null) ...[
          _InviteLine(
            label: adminText(context, 'Nome'),
            value: invite.displayName,
          ),
          _InviteLine(label: 'Email', value: invite.email),
          _InviteLine(
            label: adminText(context, 'Países'),
            value: invite.countryCodes
                .map((code) => code.toUpperCase())
                .join(', '),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isBusy || !invite.isPending ? null : _accept,
            icon: const Icon(Icons.check),
            label: Text(adminText(context, 'Aceitar convite')),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, textAlign: TextAlign.center),
        ],
        TextButton(
          onPressed: _signOut,
          child: Text(adminText(context, 'Usar outra conta')),
        ),
      ],
    );
  }
}

class _InviteLine extends StatelessWidget {
  const _InviteLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptedInvite extends StatelessWidget {
  const _AcceptedInvite({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          adminText(context, 'Acesso confirmado'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          adminText(
            context,
            'Agora você pode selecionar o país e entrar na administração.',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.home_outlined),
          label: Text(adminText(context, 'Continuar')),
        ),
      ],
    );
  }
}

String _authErrorMessage(BuildContext context, FirebaseAuthException error) {
  return switch (error.code) {
    'email-already-in-use' => adminText(
      context,
      'Este email já possui conta. Escolha “Já tenho conta”.',
    ),
    'invalid-credential' ||
    'wrong-password' => adminText(context, 'Email ou senha incorretos.'),
    'invalid-email' => adminText(context, 'Email inválido.'),
    'weak-password' => adminText(context, 'Escolha uma senha mais forte.'),
    'too-many-requests' => adminText(
      context,
      'Muitas tentativas. Aguarde e tente novamente.',
    ),
    _ => error.message ?? adminText(context, 'Não foi possível autenticar.'),
  };
}
