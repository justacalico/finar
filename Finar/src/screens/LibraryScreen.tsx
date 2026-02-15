import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { useJellyfinApi } from '../context/AuthContext';
import { createMediaService } from '../api/mediaService';
import { useLibrary } from '../context/LibraryContext';
import { MediaCard } from '../components/MediaCard';
import type { MediaItem, Library } from '../api/models';

type RouteParams = { libraryId: string; isMusic?: boolean };

export function LibraryScreen() {
  const route = useRoute();
  const navigation = useNavigation();
  const { libraryId } = (route.params ?? {}) as RouteParams;
  const api = useJellyfinApi();
  const { libraries } = useLibrary();
  const serverUrl = api.serverUrl ?? '';
  const mediaService = React.useMemo(() => createMediaService(api), [api]);

  const [items, setItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [library, setLibrary] = useState<Library | null>(null);

  useEffect(() => {
    if (libraryId && libraries.length > 0) {
      const lib = libraries.find((l) => l.id === libraryId);
      setLibrary(lib ?? null);
    } else {
      setLibrary(null);
    }
  }, [libraryId, libraries]);

  useEffect(() => {
    if (!libraryId) {
      setItems([]);
      setLoading(false);
      return;
    }
    let cancelled = false;
    setLoading(true);
    mediaService
      .getLibraryContent(libraryId)
      .then((content) => {
        if (!cancelled) setItems(content.items);
      })
      .catch(() => {
        if (!cancelled) setItems([]);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [libraryId, mediaService]);

  const navigateToDetail = (itemId: string) => {
    (navigation as { navigate: (n: string, p: object) => void }).navigate('Detail', { itemId });
  };

  if (!libraryId) {
    return (
      <View className="flex-1 bg-finar-bg pt-6">
        <Text className="text-[22px] font-semibold text-finar-text-primary mb-4 px-4" style={{ fontFamily: 'Outfit_600SemiBold' }}>Libraries</Text>
        <FlatList
          data={libraries}
          keyExtractor={(item) => item.id}
          numColumns={2}
          contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
          renderItem={({ item }) => (
            <TouchableOpacity
              className="flex-1 m-2 p-6 bg-finar-surface rounded-xl border border-finar-glass-border items-center min-h-[120px]"
              onPress={() =>
                (navigation as { navigate: (n: string, p: object) => void }).navigate('Library', {
                  libraryId: item.id,
                  isMusic: item.collectionType?.toLowerCase() === 'music',
                })
              }
            >
              <Text className="text-4xl mb-2">
                {item.collectionType?.toLowerCase() === 'music'
                  ? '🎵'
                  : item.collectionType?.toLowerCase() === 'movies'
                    ? '🎬'
                    : item.collectionType?.toLowerCase() === 'tvshows'
                      ? '📺'
                      : '📁'}
              </Text>
              <Text className="text-sm font-semibold text-finar-text-primary text-center" numberOfLines={2} style={{ fontFamily: 'Outfit_600SemiBold' }}>
                {item.name}
              </Text>
            </TouchableOpacity>
          )}
        />
      </View>
    );
  }

  if (loading && items.length === 0) {
    return (
      <View className="flex-1 justify-center items-center bg-finar-bg">
        <ActivityIndicator size="large" color="#00E5B8" />
      </View>
    );
  }

  return (
    <View className="flex-1 bg-finar-bg pt-6">
      <Text className="text-[22px] font-semibold text-finar-text-primary mb-4 px-4" style={{ fontFamily: 'Outfit_600SemiBold' }}>{library?.name ?? 'Library'}</Text>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        numColumns={3}
        contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
        columnWrapperStyle={{ gap: 8, marginBottom: 16 }}
        renderItem={({ item, index }) => (
          <View className="w-[31%]">
            <MediaCard item={item} serverUrl={serverUrl} width={110} onPress={() => navigateToDetail(item.id)} index={index} />
          </View>
        )}
      />
    </View>
  );
}
