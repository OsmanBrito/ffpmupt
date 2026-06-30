import 'package:ffpmupt/content/videos.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:ffpmupt/widgets/video_embed.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _youtubeVideoUrlKey = 'weekly_video_youtube_url';
const _vimeoVideoUrlKey = 'weekly_video_vimeo_url';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final _youtubeController = TextEditingController();
  final _vimeoController = TextEditingController();
  late List<WeeklyVideo> _videos = weeklyVideos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedVideoLinks();
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _vimeoController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedVideoLinks() async {
    final savedYoutubeUrl = await LocalStore.getString(_youtubeVideoUrlKey);
    final savedVimeoUrl = await LocalStore.getString(_vimeoVideoUrlKey);
    final youtubeVideo =
        weeklyVideoFromUrl(
          sourceName: 'YouTube',
          title: 'YouTube Semanário',
          url: savedYoutubeUrl ?? weeklyVideos[0].watchUrl,
        ) ??
        weeklyVideos[0];
    final vimeoVideo =
        weeklyVideoFromUrl(
          sourceName: 'Vimeo',
          title: 'Vimeo Weekly News',
          url: savedVimeoUrl ?? weeklyVideos[1].watchUrl,
        ) ??
        weeklyVideos[1];

    if (!mounted) {
      return;
    }

    setState(() {
      _videos = [youtubeVideo, vimeoVideo];
      _youtubeController.text = youtubeVideo.watchUrl;
      _vimeoController.text = vimeoVideo.watchUrl;
      _isLoading = false;
    });
  }

  Future<void> _saveVideoLinks(AppStrings strings) async {
    final youtubeVideo = weeklyVideoFromUrl(
      sourceName: 'YouTube',
      title: 'YouTube Semanário',
      url: _youtubeController.text,
    );
    final vimeoVideo = weeklyVideoFromUrl(
      sourceName: 'Vimeo',
      title: 'Vimeo Weekly News',
      url: _vimeoController.text,
    );

    if (youtubeVideo == null || vimeoVideo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.invalidVideoLink)));
      return;
    }

    await LocalStore.setString(_youtubeVideoUrlKey, youtubeVideo.watchUrl);
    await LocalStore.setString(_vimeoVideoUrlKey, vimeoVideo.watchUrl);

    if (!mounted) {
      return;
    }

    setState(() {
      _videos = [youtubeVideo, vimeoVideo];
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.videoLinksSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    return Scaffold(
      appBar: AppBar(title: Text(strings.weeklyVideos)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 32, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _isLoading ? 1 : _videos.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (index == 0) {
                    return _VideoLinksPanel(
                      youtubeController: _youtubeController,
                      vimeoController: _vimeoController,
                      onSave: () => _saveVideoLinks(strings),
                    );
                  }

                  return _WeeklyVideoCard(video: _videos[index - 1]);
                },
              ),
            ),
          ),
        ),
      ),
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
