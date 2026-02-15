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
import { LinearGradient } from 'expo-linear-gradient';
import { Play, Info, Star, Film, Music, Folder, Tv, LibraryBig, Image as ImageIcon } from 'lucide-react-native';

export function HomeScreen() {
  const { width } = useWindowDimensions();
  const navigation = useNavigation();
  const { api } = useAuth();
  const { homeData, libraries, isLoading, loadHomeData, featuredItem } = useLibrary();

  const [refreshing, setRefreshing] = useState(false);

  const serverUrl = api.serverUrl ?? '';
  const isWide = width >= 900;
  const featuredHeight = useMemo(() => (isWide ? 500 : 360), [isWide]);
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
          <Animated.View entering={FadeIn.duration(450)} className="mx-4 mt-3 mb-0">
            <TouchableOpacity
              className="rounded-[22px] overflow-hidden border border-white/10 shadow-finar-card"
              style={{ height: featuredHeight }}
              onPress={() => navigateToDetail(featuredItem.id)}
              activeOpacity={0.93}
            >
              <Image
                source={{ uri: getBackdropImageUrl(serverUrl, featuredItem, { width: 1400 }) }}
                className="absolute inset-0 w-full h-full"
                contentFit="cover"
                style={{ transform: [{ scale: 1.05 }] }}
              />
              <LinearGradient
                colors={['rgba(0,0,0,0.9)', 'rgba(0,0,0,0.3)', 'rgba(0,0,0,0)']}
                start={{ x: 0, y: 1 }}
                end={{ x: 0, y: 0 }}
                style={{ position: 'absolute', left: 0, right: 0, top: 0, bottom: 0 }}
              />
              <LinearGradient
                colors={['rgba(0,0,0,0.92)', 'rgba(0,0,0,0.35)', 'rgba(0,0,0,0)']}
                start={{ x: 0, y: 0.5 }}
                end={{ x: 1, y: 0.5 }}
                style={{ position: 'absolute', left: 0, right: 0, top: 0, bottom: 0 }}
              />
              <View className="absolute inset-0 bg-black/10" />
              {/* Content anchored to bottom of hero */}
              <Animated.View
                entering={FadeInDown.delay(140)}
                className="absolute left-0 right-0 bottom-0 px-8 pb-8 pt-4"
                style={{
                  top: 0,
                  maxWidth: isWide ? 980 : undefined,
                  flex: 1,
                  justifyContent: 'flex-end',
                }}
              >
                <View className="flex-row items-center gap-2 mb-4">
                  {featuredItem.communityRating ? (
                    <View className="flex-row items-center gap-1 px-2.5 py-1 rounded-md bg-black/60 border border-white/10">
                      <Star size={12} color="#FBBF24" fill="#FBBF24" />
                      <Text className="text-[11px] text-white" style={{ fontFamily: 'Outfit_600SemiBold' }}>
                        {featuredItem.communityRating.toFixed(1)}
                      </Text>
                    </View>
                  ) : null}
                  {featuredItem.productionYear ? (
                    <View className="px-2.5 py-1 rounded-md bg-black/60 border border-white/10">
                      <Text className="text-[11px] text-white/80" style={{ fontFamily: 'Outfit_500Medium' }}>
                        {featuredItem.productionYear}
                      </Text>
                    </View>
                  ) : null}
                  {featuredItem.runtimeTicks ? (
                    <View className="px-2.5 py-1 rounded-md bg-black/60 border border-white/10">
                      <Text className="text-[11px] text-white/80" style={{ fontFamily: 'Outfit_500Medium' }}>
                        {formatRuntime(featuredItem.runtimeTicks)}
                      </Text>
                    </View>
                  ) : null}
                </View>
                <Text
                  className={`${isWide ? 'text-[58px]' : 'text-[36px]'} text-white leading-none`}
                  style={{ fontFamily: 'Outfit_600SemiBold' }}
                  numberOfLines={2}
                >
                  {getHeroTitle(featuredItem)}
                </Text>
                <Text className="text-white/60 text-base mt-1 mb-3" style={{ fontFamily: 'Outfit_500Medium' }}>
                  {featuredItem.typeString ?? featuredItem.type ?? 'Media'}
                </Text>
                {featuredItem.overview ? (
                  <Text
                    className={`${isWide ? 'text-base' : 'text-sm'} text-white/80 mt-1 leading-6 max-w-[900px]`}
                    style={{ fontFamily: 'Outfit_400Regular' }}
                    numberOfLines={3}
                  >
                    {featuredItem.overview}
                  </Text>
                ) : null}
                <View className="flex-row gap-3 mt-4">
                  <TouchableOpacity className="bg-finar-primary px-7 py-3 rounded-full flex-row items-center gap-2" onPress={() => navigateToPlayer(featuredItem)}>
                    <Play size={18} color="#041B18" fill="#041B18" />
                    <Text className="text-[#041B18] text-base" style={{ fontFamily: 'Outfit_600SemiBold' }}>
                      Play
                    </Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    className="bg-white/5 border border-white/40 px-7 py-3 rounded-full flex-row items-center gap-2"
                    onPress={() => navigateToDetail(featuredItem.id)}
                  >
                    <Info size={18} color="#FFFFFF" />
                    <Text className="text-white text-base" style={{ fontFamily: 'Outfit_600SemiBold' }}>
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
                  <View className="mb-2">
                    {getLibraryIconElement(lib.collectionType)}
                  </View>
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

function getLibraryIconElement(collectionType?: string): React.ReactNode {
  const size = 32;
  const color = '#B0B0B0';
  switch (collectionType?.toLowerCase()) {
    case 'movies':
      return <Film size={size} color={color} />;
    case 'tvshows':
      return <Tv size={size} color={color} />;
    case 'music':
      return <Music size={size} color={color} />;
    case 'photos':
      return <ImageIcon size={size} color={color} />;
    default:
      return <LibraryBig size={size} color={color} />;
  }
}
