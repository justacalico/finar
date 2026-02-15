import React, { useEffect, useMemo, useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, ActivityIndicator, useWindowDimensions } from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { Image } from 'expo-image';
import { useJellyfinApi } from '../context/AuthContext';
import { getDisplayImageUrl, getBackdropUrl, formatRuntime, getPlaybackProgress } from '../api/itemImages';
import type { MediaItem } from '../api/models';
import { AppShell } from '../components/layout/AppShell';
import { MediaCard } from '../components/MediaCard';

type RouteParams = { itemId: string };

export function DetailScreen() {
  const route = useRoute();
  const navigation = useNavigation();
  const { width } = useWindowDimensions();
  const { itemId } = (route.params ?? {}) as RouteParams;
  const api = useJellyfinApi();
  const serverUrl = api.serverUrl ?? '';

  const [item, setItem] = useState<MediaItem | null>(null);
  const [seasons, setSeasons] = useState<MediaItem[]>([]);
  const [episodes, setEpisodes] = useState<MediaItem[]>([]);
  const [similar, setSimilar] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSeasonId, setSelectedSeasonId] = useState<string | null>(null);

  const heroHeight = useMemo(() => (width >= 1200 ? 460 : width >= 900 ? 380 : 270), [width]);
  const similarCardWidth = useMemo(() => (width >= 1200 ? 170 : width >= 900 ? 150 : 130), [width]);

  useEffect(() => {
    if (!itemId) return;
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const [detail, sim] = await Promise.all([api.getItem(itemId), api.getSimilarItems(itemId, 12)]);
        if (cancelled) return;
        setItem(detail);
        setSimilar(sim);
        const type = (detail.typeString ?? detail.type)?.toLowerCase();
        if (type === 'series') {
          const seas = await api.getSeasons(itemId);
          if (cancelled) return;
          setSeasons(seas);
          if (seas.length > 0) {
            const firstSeasonId = seas[0].id;
            setSelectedSeasonId(firstSeasonId);
            const eps = await api.getEpisodes(itemId, firstSeasonId);
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

  const goPlayer = (id: string) =>
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Player', { itemId: id });

  const goDetail = (id: string) =>
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Detail', { itemId: id });

  if (loading && !item) {
    return (
      <AppShell activeTab="home" title="Details">
        <View className="flex-1 items-center justify-center">
          <ActivityIndicator size="large" color="#00E5B8" />
        </View>
      </AppShell>
    );
  }

  if (!item) {
    return (
      <AppShell activeTab="home" title="Details">
        <View className="flex-1 items-center justify-center px-6">
          <Text className="text-lg text-finar-text-secondary" style={{ fontFamily: 'Outfit_500Medium' }}>
            Item not found
          </Text>
        </View>
      </AppShell>
    );
  }

  const backdropUrl = getBackdropUrl(serverUrl, item, 0, { width: 1400 });
  const progress = getPlaybackProgress(item);

  return (
    <AppShell activeTab="home" title="Details">
      <ScrollView className="flex-1" contentContainerStyle={{ paddingBottom: 120 }}>
        <View className="mx-4 mt-4 rounded-finar-xl overflow-hidden border border-finar-glass-border bg-finar-surface">
          <View style={{ height: heroHeight }}>
            {backdropUrl ? (
              <Image source={{ uri: backdropUrl }} className="absolute inset-0 w-full h-full" contentFit="cover" />
            ) : null}
            <View className="absolute inset-0 bg-black/55" />
            <View className="absolute left-0 right-0 bottom-0 p-5">
              <Text className="text-[30px] text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>
                {item.name}
              </Text>
              <View className="flex-row flex-wrap gap-x-4 gap-y-1 mt-2">
                {item.productionYear != null ? (
                  <Text className="text-sm text-finar-text-secondary" style={{ fontFamily: 'Outfit_400Regular' }}>
                    {item.productionYear}
                  </Text>
                ) : null}
                {item.runtimeTicks != null ? (
                  <Text className="text-sm text-finar-text-secondary" style={{ fontFamily: 'Outfit_400Regular' }}>
                    {formatRuntime(item.runtimeTicks)}
                  </Text>
                ) : null}
                {item.communityRating != null ? (
                  <Text className="text-sm text-finar-text-secondary" style={{ fontFamily: 'Outfit_400Regular' }}>
                    ★ {item.communityRating.toFixed(1)}
                  </Text>
                ) : null}
              </View>
              <TouchableOpacity onPress={() => goPlayer(item.id)} className="mt-4 bg-finar-primary px-6 py-3 rounded-finar-md self-start">
                <Text className="text-finar-text-on-primary text-base" style={{ fontFamily: 'Outfit_600SemiBold' }}>
                  Play
                </Text>
              </TouchableOpacity>
            </View>
          </View>
          {progress > 0 && progress < 1 ? (
            <View className="h-1 bg-finar-glass-border">
              <View className="h-full bg-finar-primary" style={{ width: `${progress * 100}%` }} />
            </View>
          ) : null}
        </View>

        {item.overview ? (
          <View className="mx-4 mt-4 rounded-finar-xl bg-finar-surface border border-finar-glass-border p-5">
            <Text className="text-lg text-finar-text-primary mb-2" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              Overview
            </Text>
            <Text className="text-[15px] leading-6 text-finar-text-secondary" style={{ fontFamily: 'Outfit_400Regular' }}>
              {item.overview}
            </Text>
          </View>
        ) : null}

        {seasons.length > 0 ? (
          <View className="mx-4 mt-4 rounded-finar-xl bg-finar-surface border border-finar-glass-border p-5">
            <Text className="text-lg text-finar-text-primary mb-3" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              Seasons
            </Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8 }}>
              {seasons.map((season) => {
                const active = selectedSeasonId === season.id;
                return (
                  <TouchableOpacity
                    key={season.id}
                    className={`px-4 py-2 rounded-full border ${
                      active
                        ? 'bg-finar-primary border-finar-primary'
                        : 'bg-finar-bg-secondary border-finar-glass-border'
                    }`}
                    onPress={() => setSelectedSeasonId(season.id)}
                  >
                    <Text
                      className={`text-sm ${active ? 'text-finar-text-on-primary' : 'text-finar-text-primary'}`}
                      style={{ fontFamily: active ? 'Outfit_600SemiBold' : 'Outfit_500Medium' }}
                    >
                      {season.name}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
        ) : null}

        {episodes.length > 0 ? (
          <View className="mx-4 mt-4 rounded-finar-xl bg-finar-surface border border-finar-glass-border p-5">
            <Text className="text-lg text-finar-text-primary mb-3" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              Episodes
            </Text>
            <View className="gap-3">
              {episodes.map((ep) => (
                <TouchableOpacity
                  key={ep.id}
                  className="rounded-finar-lg bg-finar-bg-secondary border border-finar-glass-border overflow-hidden"
                  onPress={() => goPlayer(ep.id)}
                >
                  <View className="flex-row">
                    <Image source={{ uri: getDisplayImageUrl(serverUrl, ep, { width: 300 }) }} className="w-36 h-20" contentFit="cover" />
                    <View className="flex-1 px-3 py-2">
                      <Text className="text-sm text-finar-text-primary" numberOfLines={1} style={{ fontFamily: 'Outfit_600SemiBold' }}>
                        {ep.indexNumber != null ? `E${ep.indexNumber}` : ''} {ep.name}
                      </Text>
                      {ep.overview ? (
                        <Text className="text-xs text-finar-text-secondary mt-1" numberOfLines={2} style={{ fontFamily: 'Outfit_400Regular' }}>
                          {ep.overview}
                        </Text>
                      ) : null}
                    </View>
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        ) : null}

        {similar.length > 0 ? (
          <View className="mt-5">
            <Text className="text-[22px] text-finar-text-primary px-4 mb-3" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              Similar
            </Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ paddingHorizontal: 16, gap: 12 }}>
              {similar.map((sim, index) => (
                <MediaCard
                  key={sim.id}
                  item={sim}
                  serverUrl={serverUrl}
                  width={similarCardWidth}
                  onPress={() => goDetail(sim.id)}
                  index={index}
                />
              ))}
            </ScrollView>
          </View>
        ) : null}
      </ScrollView>
    </AppShell>
  );
}
