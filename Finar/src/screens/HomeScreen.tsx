import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  useWindowDimensions,
  RefreshControl,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../context/AuthContext';
import { useLibrary } from '../context/LibraryContext';
import { SectionRow } from '../components/SectionRow';
import { getBackdropImageUrl, getHeroTitle } from '../api/itemImages';
import type { MediaItem, Library } from '../api/models';
import { Image } from 'expo-image';
import Animated, { FadeIn, FadeInDown } from 'react-native-reanimated';
import { BREAKPOINTS } from '../utils/responsive';

type NavTab = 'home' | 'search' | 'library' | 'downloads';

export function HomeScreen() {
  const { width } = useWindowDimensions();
  const navigation = useNavigation();
  const { api, state: authState, logout } = useAuth();
  const { homeData, libraries, isLoading, loadHomeData, featuredItem } = useLibrary();

  const [navIndex, setNavIndex] = useState<NavTab>('home');
  const [refreshing, setRefreshing] = useState(false);

  const serverUrl = api.serverUrl ?? '';
  const isWide = width >= BREAKPOINTS.tablet;
  const showSidebar = isWide;

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

  const content = (
    <ScrollView
      className="flex-1"
      contentContainerStyle={{ paddingBottom: 20 }}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#00E5B8" />
      }
    >
      {featuredItem && (
        <Animated.View entering={FadeIn.duration(500)} className="mx-4 mb-6">
          <TouchableOpacity
            className="h-[320px] rounded-finar-lg overflow-hidden"
            onPress={() => navigateToDetail(featuredItem.id)}
            activeOpacity={0.95}
          >
            <Image
              source={{ uri: getBackdropImageUrl(serverUrl, featuredItem, { width: 1200 }) }}
              className="absolute inset-0 w-full h-full"
              contentFit="cover"
            />
            <View className="absolute inset-0 bg-black/50" />
            <View className="absolute left-0 right-0 bottom-0 p-6">
              <Text
                className="text-[28px] font-semibold text-finar-text-primary"
                style={{ fontFamily: 'Outfit_600SemiBold' }}
                numberOfLines={2}
              >
                {getHeroTitle(featuredItem)}
              </Text>
              {featuredItem.overview && (
                <Text
                  className="text-sm text-finar-text-secondary mt-2"
                  style={{ fontFamily: 'Outfit_400Regular' }}
                  numberOfLines={2}
                >
                  {featuredItem.overview}
                </Text>
              )}
              <View className="flex-row gap-4 mt-4">
                <TouchableOpacity
                  className="bg-finar-primary px-8 py-3 rounded-finar-md"
                  onPress={() => navigateToPlayer(featuredItem)}
                >
                  <Text
                    className="text-base font-semibold text-finar-text-on-primary"
                    style={{ fontFamily: 'Outfit_600SemiBold' }}
                  >
                    Play
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  className="bg-finar-glass-border px-8 py-3 rounded-finar-md"
                  onPress={() => navigateToDetail(featuredItem.id)}
                >
                  <Text
                    className="text-base font-semibold text-finar-text-primary"
                    style={{ fontFamily: 'Outfit_600SemiBold' }}
                  >
                    Info
                  </Text>
                </TouchableOpacity>
              </View>
            </View>
          </TouchableOpacity>
        </Animated.View>
      )}

      {homeData?.continueWatching && homeData.continueWatching.length > 0 && (
        <SectionRow
          title="Continue Watching"
          items={homeData.continueWatching}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          showProgress
          cardWidth={isWide ? 170 : 140}
        />
      )}
      {homeData?.nextUp && homeData.nextUp.length > 0 && (
        <SectionRow
          title="Next Up"
          items={homeData.nextUp}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {homeData?.recentlyAdded && homeData.recentlyAdded.length > 0 && (
        <SectionRow
          title="Recently Added"
          items={homeData.recentlyAdded}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {homeData?.recommended && homeData.recommended.length > 0 && (
        <SectionRow
          title="Recommended For You"
          items={homeData.recommended}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {homeData?.topRated && homeData.topRated.length > 0 && (
        <SectionRow
          title="Top Rated"
          items={homeData.topRated}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {homeData?.favorites && homeData.favorites.length > 0 && (
        <SectionRow
          title="My Favorites"
          items={homeData.favorites}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {libraries.length > 0 && (
        <View className="mb-8 px-4">
          <Text
            className="text-[22px] font-semibold text-finar-text-primary mb-4"
            style={{ fontFamily: 'Outfit_600SemiBold' }}
          >
            Libraries
          </Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 16, paddingBottom: 8 }}>
            {libraries.map((lib) => (
              <TouchableOpacity
                key={lib.id}
                className="w-40 py-4 px-4 bg-finar-surface rounded-finar-md border border-finar-glass-border items-center"
                onPress={() => navigateToLibrary(lib.id, lib.collectionType)}
              >
                <Text className="text-3xl mb-2">{getLibraryIcon(lib.collectionType)}</Text>
                <Text
                  className="text-sm font-semibold text-finar-text-primary text-center"
                  style={{ fontFamily: 'Outfit_600SemiBold' }}
                  numberOfLines={2}
                >
                  {lib.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      )}
      <View style={{ height: 100 }} />
    </ScrollView>
  );

  if (showSidebar) {
    const user = authState.status === 'authenticated' ? authState.user : null;
    return (
      <View className="flex-1 flex-row bg-finar-bg">
        <View className="w-[260px] bg-finar-bg-secondary border-r border-finar-divider py-6">
          <View className="flex-row items-center px-6 py-6 gap-2">
            <Text className="text-2xl">▶</Text>
            <Text className="text-xl font-semibold text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              Finar
            </Text>
          </View>
          <TouchableOpacity
            className={`flex-row items-center px-6 py-4 gap-2 ${navIndex === 'home' ? 'bg-finar-primary/20 border-l-4 border-finar-primary' : ''}`}
            onPress={() => setNavIndex('home')}
          >
            <Text className="text-xl">🏠</Text>
            <Text className="text-[15px] text-finar-text-secondary flex-1" style={{ fontFamily: 'Outfit_500Medium' }}>Home</Text>
          </TouchableOpacity>
          <TouchableOpacity
            className={`flex-row items-center px-6 py-4 gap-2 ${navIndex === 'search' ? 'bg-finar-primary/20 border-l-4 border-finar-primary' : ''}`}
            onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Search')}
          >
            <Text className="text-xl">🔍</Text>
            <Text className="text-[15px] text-finar-text-secondary flex-1" style={{ fontFamily: 'Outfit_500Medium' }}>Search</Text>
          </TouchableOpacity>
          {libraries.slice(0, 8).map((lib) => (
            <TouchableOpacity
              key={lib.id}
              className="flex-row items-center px-6 py-4 gap-2"
              onPress={() => navigateToLibrary(lib.id, lib.collectionType)}
            >
              <Text className="text-xl">{getLibraryIcon(lib.collectionType)}</Text>
              <Text className="text-[15px] text-finar-text-secondary flex-1" style={{ fontFamily: 'Outfit_500Medium' }} numberOfLines={1}>{lib.name}</Text>
            </TouchableOpacity>
          ))}
          <View className="mt-auto p-4 border-t border-finar-divider">
            <Text className="text-sm font-semibold text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>{user?.name ?? 'Guest'}</Text>
            <TouchableOpacity onPress={() => logout()}>
              <Text className="text-[13px] text-finar-primary mt-1" style={{ fontFamily: 'Outfit_500Medium' }}>Sign out</Text>
            </TouchableOpacity>
          </View>
          <TouchableOpacity
            className="flex-row items-center px-6 py-4 gap-2"
            onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Settings')}
          >
            <Text className="text-xl">⚙</Text>
            <Text className="text-[15px] text-finar-text-secondary flex-1" style={{ fontFamily: 'Outfit_500Medium' }}>Settings</Text>
          </TouchableOpacity>
        </View>
        <View className="flex-1">{content}</View>
      </View>
    );
  }

  return (
    <View className="flex-1 bg-finar-bg">
      <View className="flex-row items-center justify-between px-4 pt-12 pb-2 bg-finar-bg">
        <Text className="text-xl font-semibold text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>Finar</Text>
        <TouchableOpacity onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Settings')}>
          <Text className="text-[22px]">⚙</Text>
        </TouchableOpacity>
      </View>
      {content}
      <View className="flex-row bg-finar-bg-secondary border-t border-finar-divider pb-6 pt-2">
        <TouchableOpacity
          className={`flex-1 items-center py-2 ${navIndex === 'home' ? 'bg-finar-primary/15' : ''}`}
          onPress={() => setNavIndex('home')}
        >
          <Text className="text-2xl">🏠</Text>
          <Text className="text-[10px] text-finar-text-secondary mt-1" style={{ fontFamily: 'Outfit_400Regular' }}>Home</Text>
        </TouchableOpacity>
        <TouchableOpacity
          className="flex-1 items-center py-2"
          onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Search')}
        >
          <Text className="text-2xl">🔍</Text>
          <Text className="text-[10px] text-finar-text-secondary mt-1" style={{ fontFamily: 'Outfit_400Regular' }}>Search</Text>
        </TouchableOpacity>
        <TouchableOpacity
          className="flex-1 items-center py-2"
          onPress={() => (navigation as { navigate: (name: string, params?: object) => void }).navigate('Library', { libraryId: '', isMusic: false })}
        >
          <Text className="text-2xl">📚</Text>
          <Text className="text-[10px] text-finar-text-secondary mt-1" style={{ fontFamily: 'Outfit_400Regular' }}>Library</Text>
        </TouchableOpacity>
      </View>
    </View>
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
