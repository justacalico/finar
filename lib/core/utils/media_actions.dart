import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/pages/adaptive_pages.dart';
import 'package:finar/pages/player.dart';
import 'package:finar/providers/providers.dart';

void playHomeItem(WidgetRef ref, BuildContext context, MediaItem item) {
  if (item.type == MediaType.series) {
    // For series, play the next up episode (continue watching)
    playHomeSeries(ref, context, item);
  } else {
    ref.read(playerProvider.notifier).play(item);
    // Navigate to player for video content
    final isMusic =
        item.type == MediaType.audio ||
        item.type == MediaType.album ||
        item.type == MediaType.musicVideo;
    if (!isMusic) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const PlayerPage()));
    }
  }
}

Future<void> playHomeSeries(
  WidgetRef ref,
  BuildContext context,
  MediaItem series,
) async {
  try {
    final mediaService = ref.read(mediaServiceProvider);
    final nextUp = await mediaService.getNextUpForSeries(series.id);

    if (nextUp != null) {
      // Play the next up episode
      ref.read(playerProvider.notifier).play(nextUp);
      if (context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PlayerPage()));
      }
    } else {
      // No next up episode, get the first episode of the first season
      final seasons = await mediaService.getSeasons(series.id);
      if (seasons.isNotEmpty) {
        final episodes = await mediaService.getSeasonEpisodes(
          series.id,
          seasons.first.id,
        );
        if (episodes.isNotEmpty) {
          ref.read(playerProvider.notifier).play(episodes.first);
          if (context.mounted) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PlayerPage()));
          }
        } else if (context.mounted) {
          showNoEpisodesError(context);
        }
      } else if (context.mounted) {
        showNoEpisodesError(context);
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to play series: $e')));
    }
  }
}

void playDetailItem(WidgetRef ref, BuildContext context, MediaItem item) {
  // Check if this is music content
  final isMusic =
      item.type == MediaType.audio ||
      item.type == MediaType.album ||
      item.type == MediaType.musicVideo;

  if (item.type == MediaType.album) {
    // For albums, fetch tracks and play as playlist
    playDetailAlbum(ref, context, item);
  } else if (item.type == MediaType.series) {
    // For series, play the next up episode (continue watching)
    playDetailSeries(ref, context, item);
  } else {
    // Get the resume position if item has progress
    final startPosition = item.hasProgress
        ? (item.userData?.playbackPositionTicks ?? item.playbackPositionTicks)
        : null;

    ref
        .read(playerProvider.notifier)
        .play(item, startPositionTicks: startPosition);

    // Only navigate to video player for non-music content
    if (!isMusic) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AdaptivePlayerPage()),
      );
    }
  }
}

Future<void> playDetailSeries(
  WidgetRef ref,
  BuildContext context,
  MediaItem series,
) async {
  try {
    final mediaService = ref.read(mediaServiceProvider);
    final nextUp = await mediaService.getNextUpForSeries(series.id);

    if (nextUp != null) {
      // Play the next up episode with resume position
      final startPosition = nextUp.hasProgress
          ? (nextUp.userData?.playbackPositionTicks ??
                nextUp.playbackPositionTicks)
          : null;
      ref
          .read(playerProvider.notifier)
          .play(nextUp, startPositionTicks: startPosition);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AdaptivePlayerPage()),
        );
      }
    } else {
      // No next up episode, get the first episode of the first season
      final seasons = await mediaService.getSeasons(series.id);
      if (seasons.isNotEmpty) {
        final episodes = await mediaService.getSeasonEpisodes(
          series.id,
          seasons.first.id,
        );
        if (episodes.isNotEmpty) {
          ref.read(playerProvider.notifier).play(episodes.first);
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdaptivePlayerPage(),
              ),
            );
          }
        } else if (context.mounted) {
          showNoEpisodesError(context);
        }
      } else if (context.mounted) {
        showNoEpisodesError(context);
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to play series: $e')));
    }
  }
}

Future<void> playDetailAlbum(
  WidgetRef ref,
  BuildContext context,
  MediaItem album,
) async {
  try {
    final mediaService = ref.read(mediaServiceProvider);
    final tracks = await mediaService.getAlbumTracks(album.id);
    if (tracks.isNotEmpty) {
      ref.read(playerProvider.notifier).playPlaylist(tracks, 0);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to play album: $e')));
    }
  }
}

Future<void> playDetailTrailer(
  WidgetRef ref,
  BuildContext context,
  MediaItem item,
) async {
  try {
    // First try to get local trailers
    if (item.localTrailerCount != null && item.localTrailerCount! > 0) {
      final mediaService = ref.read(mediaServiceProvider);
      final trailers = await mediaService.getLocalTrailers(item.id);
      if (trailers.isNotEmpty) {
        ref.read(playerProvider.notifier).play(trailers.first);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AdaptivePlayerPage()),
          );
        }
        return;
      }
    }

    // Fall back to remote trailers (YouTube, etc.)
    if (item.remoteTrailers != null && item.remoteTrailers!.isNotEmpty) {
      for (final trailer in item.remoteTrailers!) {
        final trailerUrl = trailer.url?.trim();
        if (trailerUrl == null || trailerUrl.isEmpty) {
          continue;
        }

        final opened = await openRemoteTrailerUrl(trailerUrl);
        if (opened) {
          return;
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No trailer available')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to play trailer: $e')));
    }
  }
}

Future<bool> openRemoteTrailerUrl(String rawUrl) async {
  final uri = normalizeTrailerUri(rawUrl);
  if (uri == null) {
    return false;
  }

  final launchMode = kIsWeb
      ? LaunchMode.platformDefault
      : LaunchMode.externalApplication;

  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: launchMode);
  }

  return launchUrl(uri, mode: launchMode);
}

Uri? normalizeTrailerUri(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(value);
  if (parsed != null && parsed.hasScheme) {
    return parsed;
  }

  if (value.startsWith('//')) {
    return Uri.tryParse('https:$value');
  }

  // Jellyfin providers sometimes return bare YouTube IDs.
  final isYouTubeId = RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value);
  if (isYouTubeId) {
    return Uri.parse('https://www.youtube.com/watch?v=$value');
  }

  if (parsed != null && parsed.host.isNotEmpty) {
    return parsed.replace(scheme: 'https');
  }

  if (!value.contains(' ')) {
    return Uri.tryParse('https://$value');
  }

  return null;
}

void toggleFavoriteItem(WidgetRef ref, MediaItem item) {
  ref
      .read(mediaActionsProvider)
      .toggleFavorite(item.id, !(item.isFavorite == true));
}

void toggleWatchedItem(WidgetRef ref, MediaItem item) {
  ref
      .read(mediaActionsProvider)
      .toggleWatched(item.id, !(item.isPlayed == true));
}

void toggleEpisodeWatched(WidgetRef ref, MediaItem episode, String seasonId) {
  ref
      .read(mediaActionsProvider)
      .markEpisodeWatched(episode.id, seasonId, !(episode.isPlayed == true));
}

void showNoEpisodesError(BuildContext context) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No episodes available to play')),
    );
  }
}

void shareMediaItem(MediaItem item) {
  final StringBuffer shareText = StringBuffer();
  shareText.write(item.name);
  if (item.productionYear != null) {
    shareText.write(' (${item.productionYear})');
  }
  if (item.overview != null && item.overview!.isNotEmpty) {
    final overview = item.overview!.length > 200
        ? '${item.overview!.substring(0, 200)}...'
        : item.overview!;
    shareText.write('\n\n$overview');
  }
  if (item.communityRating != null) {
    shareText.write('\n\n⭐ ${item.communityRating!.toStringAsFixed(1)}');
  }
  if (item.genres?.isNotEmpty == true) {
    shareText.write('\n🎬 ${item.genres!.take(3).join(', ')}');
  }
  shareText.write('\n\nShared via Finar');
  Share.share(shareText.toString(), subject: item.name);
}
