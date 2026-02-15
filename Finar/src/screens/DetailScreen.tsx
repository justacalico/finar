import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { useJellyfinApi } from '../context/AuthContext';
import { getDisplayImageUrl, getBackdropUrl, formatRuntime, getPlaybackProgress } from '../api/itemImages';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import type { MediaItem } from '../api/models';
import { Image } from 'expo-image';

type RouteParams = { itemId: string };

export function DetailScreen() {
  const route = useRoute();
  const navigation = useNavigation();
  const { itemId } = (route.params ?? {}) as RouteParams;
  const api = useJellyfinApi();
  const serverUrl = api.serverUrl ?? '';

  const [item, setItem] = useState<MediaItem | null>(null);
  const [seasons, setSeasons] = useState<MediaItem[]>([]);
  const [episodes, setEpisodes] = useState<MediaItem[]>([]);
  const [similar, setSimilar] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSeasonId, setSelectedSeasonId] = useState<string | null>(null);

  useEffect(() => {
    if (!itemId) return;
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const [detail, sim] = await Promise.all([
          api.getItem(itemId),
          api.getSimilarItems(itemId, 8),
        ]);
        if (cancelled) return;
        setItem(detail);
        setSimilar(sim);
        const type = (detail.typeString ?? detail.type)?.toLowerCase();
        if (type === 'series') {
          const seas = await api.getSeasons(itemId);
          if (cancelled) return;
          setSeasons(seas);
          if (seas.length > 0) {
            const firstId = seas[0].id;
            setSelectedSeasonId(firstId);
            const eps = await api.getEpisodes(itemId, firstId);
            if (!cancelled) setEpisodes(eps);
          }
        }
      } catch {
        if (!cancelled) setItem(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [itemId, api]);

  useEffect(() => {
    if (!itemId || !selectedSeasonId) return;
    let cancelled = false;
    api.getEpisodes(itemId, selectedSeasonId).then((eps) => {
      if (!cancelled) setEpisodes(eps);
    });
    return () => {
      cancelled = true;
    };
  }, [itemId, selectedSeasonId, api]);

  const play = () => {
    if (!item) return;
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Player', {
      itemId: item.id,
    });
  };

  if (loading && !item) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }
  if (!item) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorText}>Item not found</Text>
      </View>
    );
  }

  const backdropUrl = getBackdropUrl(serverUrl, item, 0, { width: 800 });
  const progress = getPlaybackProgress(item);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.backdropWrap}>
        {backdropUrl ? (
          <Image source={{ uri: backdropUrl }} style={styles.backdrop} contentFit="cover" />
        ) : null}
        <View style={styles.backdropOverlay} />
        <View style={styles.backdropBottom}>
          <Text style={[styles.title, { fontFamily: 'Outfit_600SemiBold' }]}>{item.name}</Text>
          <View style={styles.meta}>
            {item.productionYear != null && (
              <Text style={styles.metaText}>{item.productionYear}</Text>
            )}
            {item.runtimeTicks != null && (
              <Text style={styles.metaText}>{formatRuntime(item.runtimeTicks)}</Text>
            )}
            {item.communityRating != null && (
              <Text style={styles.metaText}>★ {item.communityRating.toFixed(1)}</Text>
            )}
          </View>
          <View style={styles.actions}>
            <TouchableOpacity style={styles.playButton} onPress={play}>
              <Text style={styles.playButtonText}>Play</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>

      {progress > 0 && progress < 1 && (
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
        </View>
      )}

      {item.overview ? (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Overview</Text>
          <Text style={styles.overview}>{item.overview}</Text>
        </View>
      ) : null}

      {seasons.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Seasons</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.seasonScroll}>
            {seasons.map((s) => (
              <TouchableOpacity
                key={s.id}
                style={[
                  styles.seasonChip,
                  selectedSeasonId === s.id && styles.seasonChipActive,
                ]}
                onPress={() => setSelectedSeasonId(s.id)}
              >
                <Text
                  style={[
                    styles.seasonChipText,
                    selectedSeasonId === s.id && styles.seasonChipTextActive,
                  ]}
                >
                  {s.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      )}

      {episodes.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Episodes</Text>
          {episodes.map((ep) => (
            <TouchableOpacity
              key={ep.id}
              style={styles.episodeRow}
              onPress={() =>
                (navigation as { navigate: (n: string, p: object) => void }).navigate(
                  'Player',
                  { itemId: ep.id }
                )
              }
            >
              <Image
                source={{
                  uri: getDisplayImageUrl(serverUrl, ep, { width: 200 }),
                }}
                style={styles.episodeThumb}
              />
              <View style={styles.episodeInfo}>
                <Text style={styles.episodeTitle}>
                  {ep.indexNumber != null ? `E${ep.indexNumber}` : ''} {ep.name}
                </Text>
                {ep.overview ? (
                  <Text style={styles.episodeOverview} numberOfLines={2}>
                    {ep.overview}
                  </Text>
                ) : null}
              </View>
            </TouchableOpacity>
          ))}
        </View>
      )}

      {similar.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Similar</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {similar.map((s) => (
              <TouchableOpacity
                key={s.id}
                style={styles.similarCard}
                onPress={() =>
                  (navigation as { navigate: (n: string, p: object) => void }).navigate(
                    'Detail',
                    { itemId: s.id }
                  )
                }
              >
                <Image
                  source={{
                    uri: getDisplayImageUrl(serverUrl, s, { width: 300 }),
                  }}
                  style={styles.similarImage}
                  contentFit="cover"
                />
                <Text style={styles.similarTitle} numberOfLines={2}>
                  {s.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    paddingBottom: 80,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
  errorText: {
    color: colors.textSecondary,
    fontSize: 16,
  },
  backdropWrap: {
    height: 380,
    position: 'relative',
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject,
  },
  backdropOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.6)',
  },
  backdropBottom: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    padding: spacing.lg,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  meta: {
    flexDirection: 'row',
    gap: spacing.md,
    marginTop: spacing.sm,
  },
  metaText: {
    fontSize: 14,
    color: colors.textSecondary,
  },
  actions: {
    flexDirection: 'row',
    marginTop: spacing.md,
    gap: spacing.md,
  },
  playButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.md,
    borderRadius: radius.md,
  },
  playButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textOnPrimary,
  },
  progressBar: {
    height: 4,
    backgroundColor: colors.glassBorder,
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary,
  },
  section: {
    padding: spacing.lg,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: colors.textPrimary,
    marginBottom: spacing.md,
  },
  overview: {
    fontSize: 15,
    color: colors.textSecondary,
    lineHeight: 22,
  },
  seasonScroll: {
    marginBottom: spacing.md,
  },
  seasonChip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.full,
    backgroundColor: colors.surface,
    marginRight: spacing.sm,
  },
  seasonChipActive: {
    backgroundColor: colors.primary,
  },
  seasonChipText: {
    fontSize: 14,
    color: colors.textPrimary,
  },
  seasonChipTextActive: {
    color: colors.textOnPrimary,
    fontWeight: '600',
  },
  episodeRow: {
    flexDirection: 'row',
    marginBottom: spacing.md,
    gap: spacing.md,
  },
  episodeThumb: {
    width: 160,
    height: 90,
    borderRadius: radius.sm,
  },
  episodeInfo: {
    flex: 1,
  },
  episodeTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  episodeOverview: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 4,
  },
  similarCard: {
    width: 140,
    marginRight: spacing.md,
  },
  similarImage: {
    width: 140,
    height: 210,
    borderRadius: radius.md,
  },
  similarTitle: {
    fontSize: 13,
    color: colors.textPrimary,
    marginTop: 4,
  },
});
