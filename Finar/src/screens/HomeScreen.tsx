import React, { useMemo, useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, useWindowDimensions, RefreshControl } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../context/AuthContext';
import { useLibrary } from '../context/LibraryContext';
import { SectionRow } from '../components/SectionRow';
import { getBackdropImageUrl, getHeroTitle, formatRuntime } from '../api/itemImages';
import type { MediaItem } from '../api/models';
import { Image } from 'expo-image';
import Animated, { FadeIn, FadeInDown } from 'react-native-reanimated';
import { AppShell } from '../components/layout/AppShell';

export function HomeScreen() {
  const { width } = useWindowDimensions();
  const navigation = useNavigation();
  const { api } = useAuth();
  const { homeData, libraries, isLoading, loadHomeData, featuredItem } = useLibrary();

  const [refreshing, setRefreshing] = useState(false);

  const serverUrl = api.serverUrl ?? '';
  const isWide = width >= 900;
  const featuredHeight = useMemo(() => (isWide ? 390 : 290), [isWide]);
  const sectionCardWidth = useMemo(() => {
    if (width >= 1600) return 200;
    if (width >= 1200) return 180;
    if (width >= 900) return 160;
    return 130;
  }, [width]);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadHomeData();
    setRefreshing(false);
  };

  const navigateToDetail = (itemId: string) => {
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Detail', {
      itemId,
    });
  };

  const navigateToLibrary = (libraryId: string, collectionType?: string) => {
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Library', {
      libraryId,
      isMusic: collectionType?.toLowerCase() === 'music',
    });
  };

  const navigateToPlayer = (item: MediaItem) => {
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Player', {
      itemId: item.id,
    });
  };

  if (isLoading && !homeData) {
    return (
      <View className="flex-1 justify-center items-center bg-finar-bg">
        <Text className="text-base text-finar-text-secondary" style={{ fontFamily: 'Outfit_400Regular' }}>
          Loading...
        </Text>
      </View>
    );
  }

  return (
    <AppShell activeTab="home" title="Home">
      <ScrollView
        className="flex-1"
        contentContainerStyle={{ paddingBottom: 120 }}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#00E5B8" />
        }
      >
        {featuredItem && (
          <Animated.View entering={FadeIn.duration(450)} className="mx-4 mt-3 mb-7">
            <TouchableOpacity
              className="rounded-finar-xl overflow-hidden border border-finar-glass-border shadow-finar-card"
              style={{ height: featuredHeight }}
              onPress={() => navigateToDetail(featuredItem.id)}
              activeOpacity={0.93}
            >
              <Image
                source={{ uri: getBackdropImageUrl(serverUrl, featuredItem, { width: 1400 }) }}
                className="absolute inset-0 w-full h-full"
                contentFit="cover"
              />
              <View className="absolute inset-0 bg-black/35" />
              <View className="absolute inset-x-0 bottom-0 h-48 bg-black/55" />
              <Animated.View entering={FadeInDown.delay(140)} className="absolute left-0 right-0 bottom-0 p-6">
                <View className="flex-row items-center gap-2 mb-2">
                  {featuredItem.communityRating ? (
                    <View className="px-2 py-1 rounded-full bg-black/45 border border-white/10">
                      <Text className="text-[11px] text-finar-warning" style={{ fontFamily: 'Outfit_500Medium' }}>
                        ★ {featuredItem.communityRating.toFixed(1)}
                      </Text>
                    </View>
                  ) : null}
                  {featuredItem.productionYear ? (
                    <View className="px-2 py-1 rounded-full bg-black/45 border border-white/10">
                      <Text className="text-[11px] text-finar-text-secondary" style={{ fontFamily: 'Outfit_400Regular' }}>
                        {featuredItem.productionYear}
                      </Text>
                    </View>
                  ) : null}
                  {featuredItem.runtimeTicks ? (
                    <View className="px-2 py-1 rounded-full bg-black/45 border border-white/10">
                      <Text className="text-[11px] text-finar-text-secondary" style={{ fontFamily: 'Outfit_400Regular' }}>
                        {formatRuntime(featuredItem.runtimeTicks)}
                      </Text>
                    </View>
                  ) : null}
                </View>
                <Text
                  className="text-[30px] text-finar-text-primary"
                  style={{ fontFamily: 'Outfit_600SemiBold' }}
                  numberOfLines={2}
                >
                  {getHeroTitle(featuredItem)}
                </Text>
                {featuredItem.overview ? (
                  <Text
                    className="text-[13px] text-finar-text-secondary mt-1.5"
                    style={{ fontFamily: 'Outfit_400Regular' }}
                    numberOfLines={3}
                  >
                    {featuredItem.overview}
                  </Text>
                ) : null}
                <View className="flex-row gap-3 mt-4">
                  <TouchableOpacity className="bg-finar-primary px-7 py-3 rounded-finar-md" onPress={() => navigateToPlayer(featuredItem)}>
                    <Text className="text-finar-text-on-primary text-base" style={{ fontFamily: 'Outfit_600SemiBold' }}>
                      Play
                    </Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    className="bg-white/10 border border-finar-glass-border px-7 py-3 rounded-finar-md"
                    onPress={() => navigateToDetail(featuredItem.id)}
                  >
                    <Text className="text-finar-text-primary text-base" style={{ fontFamily: 'Outfit_600SemiBold' }}>
                      More Info
                    </Text>
                  </TouchableOpacity>
                </View>
              </Animated.View>
            </TouchableOpacity>
          </Animated.View>
        )}

        <SectionRow
          title="Continue Watching"
          items={homeData?.continueWatching ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          showProgress
          cardWidth={sectionCardWidth}
          onSeeAllPress={() => (navigation as { navigate: (name: string, params?: object) => void }).navigate('Library', { libraryId: '' })}
        />
        <SectionRow
          title="Next Up"
          items={homeData?.nextUp ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
          onSeeAllPress={() => (navigation as { navigate: (name: string, params?: object) => void }).navigate('Library', { libraryId: '' })}
        />
        <SectionRow
          title="Recently Added"
          items={homeData?.recentlyAdded ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
          onSeeAllPress={() => (navigation as { navigate: (name: string, params?: object) => void }).navigate('Library', { libraryId: '' })}
        />
        <SectionRow
          title="Recommended For You"
          items={homeData?.recommended ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
          onSeeAllPress={() => (navigation as { navigate: (name: string, params?: object) => void }).navigate('Library', { libraryId: '' })}
        />
        <SectionRow
          title="Top Rated"
          items={homeData?.topRated ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
          onSeeAllPress={() => (navigation as { navigate: (name: string, params?: object) => void }).navigate('Library', { libraryId: '' })}
        />
        <SectionRow
          title="My Favorites"
          items={homeData?.favorites ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
          onSeeAllPress={() => (navigation as { navigate: (name: string, params?: object) => void }).navigate('Library', { libraryId: '' })}
        />

        {libraries.length > 0 && (
          <View className="mb-8 px-4">
            <Text className="text-[22px] text-finar-text-primary mb-4" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              Libraries
            </Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 14, paddingBottom: 8 }}>
              {libraries.map((lib) => (
                <TouchableOpacity
                  key={lib.id}
                  className="w-44 px-4 py-4 rounded-finar-lg bg-finar-surface border border-finar-glass-border"
                  onPress={() => navigateToLibrary(lib.id, lib.collectionType)}
                >
                  <Text className="text-3xl">{getLibraryIcon(lib.collectionType)}</Text>
                  <Text
                    className="text-[15px] text-finar-text-primary mt-2"
                    numberOfLines={2}
                    style={{ fontFamily: 'Outfit_600SemiBold' }}
                  >
                    {lib.name}
                  </Text>
                  <Text className="text-xs text-finar-text-tertiary mt-1" style={{ fontFamily: 'Outfit_400Regular' }}>
                    Browse collection
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        )}
      </ScrollView>
    </AppShell>
  );
}

function getLibraryIcon(collectionType?: string): string {
  switch (collectionType?.toLowerCase()) {
    case 'movies':
      return '🎬';
    case 'tvshows':
      return '📺';
    case 'music':
      return '🎵';
    case 'photos':
      return '🖼';
    default:
      return '📁';
  }
}
