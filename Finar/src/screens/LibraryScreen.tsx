import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { useJellyfinApi } from '../context/AuthContext';
import { createMediaService } from '../api/mediaService';
import { useLibrary } from '../context/LibraryContext';
import { MediaCard } from '../components/MediaCard';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';
import type { MediaItem, Library } from '../api/models';

type RouteParams = { libraryId: string; isMusic?: boolean };

export function LibraryScreen() {
  const route = useRoute();
  const navigation = useNavigation();
  const { libraryId, isMusic } = (route.params ?? {}) as RouteParams;
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
    (navigation as { navigate: (n: string, p: object) => void }).navigate('Detail', {
      itemId,
    });
  };

  if (!libraryId) {
    return (
      <View style={styles.container}>
        <Text style={styles.sectionTitle}>Libraries</Text>
        <FlatList
          data={libraries}
          keyExtractor={(item) => item.id}
          numColumns={2}
          contentContainerStyle={styles.grid}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.libraryCard}
              onPress={() =>
                (navigation as { navigate: (n: string, p: object) => void }).navigate(
                  'Library',
                  {
                    libraryId: item.id,
                    isMusic: item.collectionType?.toLowerCase() === 'music',
                  }
                )
              }
            >
              <Text style={styles.libraryIcon}>
                {item.collectionType?.toLowerCase() === 'music'
                  ? '🎵'
                  : item.collectionType?.toLowerCase() === 'movies'
                    ? '🎬'
                    : item.collectionType?.toLowerCase() === 'tvshows'
                      ? '📺'
                      : '📁'}
              </Text>
              <Text style={styles.libraryName} numberOfLines={2}>
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
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>{library?.name ?? 'Library'}</Text>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        numColumns={3}
        contentContainerStyle={styles.grid}
        columnWrapperStyle={styles.gridRow}
        renderItem={({ item }) => (
          <View style={styles.gridItem}>
            <MediaCard
              item={item}
              serverUrl={serverUrl}
              width={110}
              onPress={() => navigateToDetail(item.id)}
            />
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    paddingTop: spacing.lg,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sectionTitle: {
    fontSize: 22,
    fontWeight: '600',
    color: colors.textPrimary,
    marginBottom: spacing.md,
    paddingHorizontal: spacing.md,
  },
  grid: {
    padding: spacing.md,
    paddingBottom: 80,
  },
  gridRow: {
    justifyContent: 'flex-start',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  gridItem: {
    width: '31%',
  },
  libraryCard: {
    flex: 1,
    margin: spacing.sm,
    padding: spacing.lg,
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.glassBorder,
    alignItems: 'center',
    minHeight: 120,
  },
  libraryIcon: {
    fontSize: 40,
    marginBottom: spacing.sm,
  },
  libraryName: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textPrimary,
    textAlign: 'center',
  },
});
