import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  useWindowDimensions,
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { useJellyfinApi } from '../context/AuthContext';
import { createMediaService } from '../api/mediaService';
import { useLibrary } from '../context/LibraryContext';
import { MediaCard } from '../components/MediaCard';
import type { MediaItem, Library } from '../api/models';
import { AppShell } from '../components/layout/AppShell';
import { Film, Music, Folder, Tv, LibraryBig } from 'lucide-react-native';

type RouteParams = { libraryId: string; isMusic?: boolean };

function libraryIcon(collectionType?: string): React.ReactNode {
  const size = 40;
  const color = '#B0B0B0';
  switch (collectionType?.toLowerCase()) {
    case 'movies':
      return <Film size={size} color={color} />;
    case 'music':
      return <Music size={size} color={color} />;
    case 'tvshows':
      return <Tv size={size} color={color} />;
    default:
      return <LibraryBig size={size} color={color} />;
  }
}

export function LibraryScreen() {
  const route = useRoute();
  const navigation = useNavigation();
  const { width } = useWindowDimensions();
  const { libraryId } = (route.params ?? {}) as RouteParams;
  const api = useJellyfinApi();
  const { libraries } = useLibrary();
  const serverUrl = api.serverUrl ?? '';
  const mediaService = React.useMemo(() => createMediaService(api), [api]);

  const [items, setItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [library, setLibrary] = useState<Library | null>(null);
  const collectionColumns = width >= 1100 ? 4 : 2;
  const mediaColumns = width >= 1300 ? 6 : width >= 1000 ? 5 : width >= 760 ? 4 : 3;
  const mediaCardWidth = width >= 1300 ? 165 : width >= 1000 ? 145 : width >= 760 ? 130 : 110;

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
      <AppShell activeTab="library" title="Libraries">
        <FlatList
          data={libraries}
          keyExtractor={(item) => item.id}
          numColumns={collectionColumns}
          contentContainerStyle={{ padding: 16, paddingBottom: 120 }}
          columnWrapperStyle={collectionColumns > 1 ? { gap: 12, marginBottom: 12 } : undefined}
          renderItem={({ item }) => (
            <TouchableOpacity
              className="flex-1 p-6 bg-finar-surface rounded-finar-lg border border-finar-glass-border min-h-[130px]"
              onPress={() =>
                (navigation as { navigate: (n: string, p: object) => void }).navigate('Library', {
                  libraryId: item.id,
                  isMusic: item.collectionType?.toLowerCase() === 'music',
                })
              }
            >
              <View className="mb-2">{libraryIcon(item.collectionType)}</View>
              <Text className="text-base text-finar-text-primary" numberOfLines={2} style={{ fontFamily: 'Outfit_600SemiBold' }}>
                {item.name}
              </Text>
              <Text className="text-xs text-finar-text-tertiary mt-1" style={{ fontFamily: 'Outfit_400Regular' }}>
                Open collection
              </Text>
            </TouchableOpacity>
          )}
        />
      </AppShell>
    );
  }

  if (loading && items.length === 0) {
    return (
      <AppShell activeTab="library" title={library?.name ?? 'Library'}>
        <View className="flex-1 justify-center items-center">
          <ActivityIndicator size="large" color="#00E5B8" />
        </View>
      </AppShell>
    );
  }

  return (
    <AppShell activeTab="library" title={library?.name ?? 'Library'}>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        numColumns={mediaColumns}
        contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 120 }}
        columnWrapperStyle={mediaColumns > 1 ? { gap: 10, marginBottom: 14 } : undefined}
        renderItem={({ item, index }) => (
          <View>
            <MediaCard item={item} serverUrl={serverUrl} width={mediaCardWidth} onPress={() => navigateToDetail(item.id)} index={index} />
          </View>
        )}
      />
    </AppShell>
  );
}
