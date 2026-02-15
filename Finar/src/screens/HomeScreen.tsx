import React, { useMemo, useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, useWindowDimensions, RefreshControl } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../context/AuthContext';
import { useLibrary } from '../context/LibraryContext';
import { SectionRow } from '../components/SectionRow';
import { getBackdropImageUrl, getHeroTitle } from '../api/itemImages';
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
  const featuredHeight = useMemo(() => (isWide ? 360 : 250), [isWide]);
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
    <AppShell activeTab="home" title="Discover">
      <ScrollView
        className="flex-1"
        contentContainerStyle={{ paddingBottom: 120 }}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#00E5B8" />
        }
      >
        {featuredItem && (
          <Animated.View entering={FadeIn.duration(450)} className="mx-4 mt-4 mb-7">
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
              <View className="absolute inset-0 bg-black/50" />
              <View className="absolute inset-0 bg-black/25" />
              <Animated.View entering={FadeInDown.delay(140)} className="absolute left-0 right-0 bottom-0 p-6">
                <Text
                  className="text-[30px] text-finar-text-primary"
                  style={{ fontFamily: 'Outfit_600SemiBold' }}
                  numberOfLines={2}
                >
                  {getHeroTitle(featuredItem)}
                </Text>
                {featuredItem.overview ? (
                  <Text
                    className="text-sm text-finar-text-secondary mt-2"
                    style={{ fontFamily: 'Outfit_400Regular' }}
                    numberOfLines={2}
                  >
                    {featuredItem.overview}
                  </Text>
                ) : null}
                <View className="flex-row gap-3 mt-5">
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
                      Details
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
        />
        <SectionRow
          title="Next Up"
          items={homeData?.nextUp ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
        />
        <SectionRow
          title="Recently Added"
          items={homeData?.recentlyAdded ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
        />
        <SectionRow
          title="Recommended For You"
          items={homeData?.recommended ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
        />
        <SectionRow
          title="Top Rated"
          items={homeData?.topRated ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
        />
        <SectionRow
          title="My Favorites"
          items={homeData?.favorites ?? []}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={sectionCardWidth}
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
