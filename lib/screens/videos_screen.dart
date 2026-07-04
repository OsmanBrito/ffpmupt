import 'dart:async';

import 'package:ffpmupt/content/videos.dart';
import 'package:ffpmupt/services/admin_auth_service.dart';
import 'package:ffpmupt/services/weekly_videos_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/widgets/video_embed.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final _authService = AdminAuthService();
  final _repository = WeeklyVideosRepository();
  final _youtubeController = TextEditingController();
  final _vimeoController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;
  late List<WeeklyVideo> _videos = weeklyVideos;
  bool _isLoading = true;
  bool _isCheckingAdmin = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges().listen(
      _refreshAdminAccess,
    );
    _loadSavedVideoLinks();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _youtubeController.dispose();
    _vimeoController.dispose();
    super.dispose();
  }

  Future<void> _refreshAdminAccess(User? user) async {
    final isAdmin = await _authService.isAdmin(
      user,
      countryCode: weeklyVideosCountryCode,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });
  }

  Future<void> _showAdminLogin(AppStrings strings) async {
    final credentials = await showDialog<_AdminCredentials>(
      context: context,
      builder: (context) => _AdminLoginDialog(strings: strings),
    );
    if (credentials == null || !mounted) {
      return;
    }

    setState(() {
      _isCheckingAdmin = true;
    });

    try {
      final user = await _authService.signIn(
        email: credentials.email,
        password: credentials.password,
      );
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
          _isCheckingAdmin = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  Future<void> _loadSavedVideoLinks() async {
    final settings = await _repository.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _videos = settings.videos;
      _youtubeController.text = settings.youtube.watchUrl;
      _vimeoController.text = settings.vimeo.watchUrl;
      _isLoading = false;
    });
  }

  Future<void> _saveVideoLinks(AppStrings strings) async {
    final youtubeVideo = weeklyVideoFromUrl(
      sourceName: 'YouTube',
      sourceUrl: youtubeWeeklySourceUrl,
      title: 'YouTube Semanário',
      url: _youtubeController.text,
    );
    final vimeoVideo = weeklyVideoFromUrl(
      sourceName: 'Vimeo',
      sourceUrl: vimeoWeeklySourceUrl,
      title: 'Vimeo Weekly News',
      url: _vimeoController.text,
    );

    if (youtubeVideo == null || vimeoVideo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.invalidVideoLink)));
      return;
    }

    final settings = WeeklyVideosSettings(
      youtube: youtubeVideo,
      vimeo: vimeoVideo,
    );
    final savedInFirestore = await _repository.save(settings);

    if (!mounted) {
      return;
    }

    setState(() {
      _videos = settings.videos;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedInFirestore
              ? strings.videoLinksSaved
              : strings.videoLinksSavedLocally,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.weeklyVideos),
        actions: [
          if (_isCheckingAdmin)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_isAdmin)
            IconButton(
              tooltip: strings.signOut,
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            )
          else
            IconButton(
              tooltip: strings.adminLogin,
              onPressed: () => _showAdminLogin(strings),
              icon: const Icon(Icons.lock_outline),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 32, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _isLoading ? 1 : _videos.length + (_isAdmin ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_isAdmin && index == 0) {
                    return _VideoLinksPanel(
                      youtubeController: _youtubeController,
                      vimeoController: _vimeoController,
                      onSave: () => _saveVideoLinks(strings),
                    );
                  }

                  final videoIndex = index - (_isAdmin ? 1 : 0);
                  return _WeeklyVideoCard(video: _videos[videoIndex]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminCredentials {
  const _AdminCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

class _AdminLoginDialog extends StatefulWidget {
  const _AdminLoginDialog({required this.strings});

  final AppStrings strings;

  @override
  State<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<_AdminLoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      return;
    }

    Navigator.of(
      context,
    ).pop(_AdminCredentials(email: email, password: password));
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    return AlertDialog(
      title: Text(strings.adminLogin),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                labelText: strings.adminEmail,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: strings.password,
                prefixIcon: const Icon(Icons.password),
                suffixIcon: IconButton(
                  tooltip: strings.togglePasswordVisibility,
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.login),
          label: Text(strings.signIn),
        ),
      ],
    );
  }
}

class _VideoLinksPanel extends StatelessWidget {
  const _VideoLinksPanel({
    required this.youtubeController,
    required this.vimeoController,
    required this.onSave,
  });

  final TextEditingController youtubeController;
  final TextEditingController vimeoController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: Text(strings.updateVideoLinks),
        subtitle: Text(strings.updateVideoLinksSubtitle),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          TextField(
            controller: youtubeController,
            decoration: InputDecoration(
              labelText: strings.youtubeVideoLink,
              prefixIcon: const Icon(Icons.ondemand_video),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vimeoController,
            decoration: InputDecoration(
              labelText: strings.vimeoVideoLink,
              prefixIcon: const Icon(Icons.video_library),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: Text(strings.saveVideoLinks),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyVideoCard extends StatelessWidget {
  const _WeeklyVideoCard({required this.video});

  final WeeklyVideo video;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    video.sourceName == 'YouTube'
                        ? Icons.ondemand_video
                        : Icons.video_library,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.sourceName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xff65716c),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xff1f2724),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: strings.copyVideoLink,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: video.watchUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.videoLinkCopied)),
                    );
                  },
                  icon: const Icon(Icons.link),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: VideoEmbed(
              embedUrl: video.embedUrl,
              title: video.title,
              watchUrl: video.watchUrl,
            ),
          ),
        ],
      ),
    );
  }
}
