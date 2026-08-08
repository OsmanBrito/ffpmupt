import 'package:ffpmupt/models/access_request_country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AccessRequestScreen extends StatefulWidget {
  const AccessRequestScreen({
    super.key,
    required this.countries,
    this.initialCountryCode,
    this.coordinatorEmail = 'osman.gimenes@gmail.com',
    this.emailLauncher,
  });

  final List<AccessRequestCountry> countries;
  final String? initialCountryCode;
  final String coordinatorEmail;

  /// Optional hook for widget tests. Production opens the user's email app.
  final Future<bool> Function(Uri uri)? emailLauncher;

  @override
  State<AccessRequestScreen> createState() => _AccessRequestScreenState();
}

class _AccessRequestScreenState extends State<AccessRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _role = 'Country leader';
  String? _countryCode;
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _copied = false;
  String? _error;
  String? _preparedEmailText;

  @override
  void initState() {
    super.initState();
    _countryCode =
        widget.countries.any(
          (country) => country.code == widget.initialCountryCode,
        )
        ? widget.initialCountryCode
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  AccessRequestCountry? get _selectedCountry {
    for (final country in widget.countries) {
      if (country.code == _countryCode) {
        return country;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final country = _selectedCountry;
    if (country == null) {
      setState(() => _error = 'Please choose a country first.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _copied = false;
      _preparedEmailText = null;
    });
    String? preparedEmailText;
    try {
      final requesterEmail = _emailController.text.trim().toLowerCase();
      final message = _messageController.text.trim();
      final emailBody = [
        'Hello Osman,',
        '',
        'I would like to request administrator access to FFPMU Connect.',
        '',
        'Country: ${country.name} (${country.code.toUpperCase()})',
        'Name: ${_nameController.text.trim()}',
        'Role: $_role',
        'Email for the invitation: $requesterEmail',
        if (message.isNotEmpty) ...['', 'Message:', message],
        '',
        'Thank you.',
      ].join('\n');
      final subject =
          'FFPMU Connect — Administrator access request — ${country.name}';
      preparedEmailText =
          'To: ${widget.coordinatorEmail}\nSubject: $subject\n\n$emailBody';
      final mailto = Uri(
        scheme: 'mailto',
        path: widget.coordinatorEmail,
        queryParameters: {'subject': subject, 'body': emailBody},
      );
      final opened =
          await (widget.emailLauncher?.call(mailto) ??
              launchUrl(mailto, mode: LaunchMode.externalApplication));
      if (!opened) {
        throw StateError('No email application is available.');
      }
      if (mounted) {
        setState(() => _submitted = true);
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'We could not open your email application. Please send your request to ${widget.coordinatorEmail}.';
          _preparedEmailText = preparedEmailText;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request administrator access')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _submitted ? _buildSuccess() : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 58),
          const SizedBox(height: 16),
          Text(
            'Request administrator access',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your details. We will review your request and send an invitation by email.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Request email: ${widget.coordinatorEmail}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (widget.countries.isEmpty)
            const Text(
              'No countries are available right now.',
              textAlign: TextAlign.center,
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _countryCode,
              decoration: const InputDecoration(
                labelText: 'Country',
                prefixIcon: Icon(Icons.public),
                border: OutlineInputBorder(),
              ),
              items: [
                for (final country in widget.countries)
                  DropdownMenuItem(
                    value: country.code,
                    child: Text(
                      '${country.name} (${country.code.toUpperCase()})',
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _countryCode = value),
              validator: (value) => value == null ? 'Choose a country.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter your full name.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email for the invitation',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                    ? null
                    : 'Enter a valid email address.';
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Country leader',
                  child: Text('Country leader'),
                ),
                DropdownMenuItem(
                  value: 'Country administrator',
                  child: Text('Country administrator'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _role = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 62),
                  child: Icon(Icons.notes_outlined),
                ),
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
            ],
            if (_preparedEmailText case final preparedText?) ...[
              const SizedBox(height: 12),
              const Text(
                'Copy the prepared request below and send it manually if you use webmail or do not have an email app configured:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xffeef4f1),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: SelectableText(preparedText),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: preparedText));
                  } finally {
                    if (mounted) {
                      setState(() => _copied = true);
                    }
                  }
                },
                icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
                label: Text(_copied ? 'Request copied' : 'Copy request text'),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.email_outlined),
              label: const Text('Open email to send request'),
            ),
            const SizedBox(height: 12),
            Text(
              'This opens your email application with the request prepared. Press Send to complete it. It does not grant access automatically; the coordinator will review the request and send a separate invitation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 70,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'Email draft prepared',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your email application should now be open with the request ready to send. Please press Send. After reviewing it, we will send an invitation to the email you provided.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Return to the app'),
        ),
      ],
    );
  }
}
