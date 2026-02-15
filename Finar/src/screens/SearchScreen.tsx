import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  FlatList,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useLibrary } from '../context/LibraryContext';
import { useJellyfinApi } from '../context/AuthContext';
import { MediaCard } from '../components/MediaCard';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';

export function SearchScreen() {
  const navigation = useNavigation();
  const { searchResults, search, clearSearch, isLoading } = useLibrary();
  const api = useJellyfinApi();
  const serverUrl = api.serverUrl ?? '';
  const [query, setQuery] = useState('');

  const handleSearch = (text: string) => {
    setQuery(text);
    if (text.length >= 2) {
      search(text);
    } else {
      clearSearch();
    }
  };

  const navigateToDetail = (itemId: string) => {
    (navigation as { navigate: (n: string, p: object) => void }).navigate('Detail', {
      itemId,
    });
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TextInput
          style={styles.input}
          placeholder="Search movies, shows, music..."
          placeholderTextColor={colors.textTertiary}
          value={query}
          onChangeText={handleSearch}
          autoFocus
        />
        {query.length > 0 && (
          <TouchableOpacity onPress={() => handleSearch('')}>
            <Text style={styles.clearText}>Clear</Text>
          </TouchableOpacity>
        )}
      </View>
      {searchResults.length === 0 && !isLoading ? (
        <View style={styles.empty}>
          <Text style={styles.emptyTitle}>Search your media</Text>
          <Text style={styles.emptySubtitle}>
            Find movies, TV shows, and more
          </Text>
        </View>
      ) : (
        <FlatList
          data={searchResults}
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
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
    paddingTop: 48,
    gap: spacing.sm,
  },
  input: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: 8,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    fontSize: 16,
    color: colors.textPrimary,
    borderWidth: 1,
    borderColor: colors.glassBorder,
  },
  clearText: {
    color: colors.primary,
    fontSize: 14,
  },
  empty: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing.xl,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  emptySubtitle: {
    fontSize: 14,
    color: colors.textTertiary,
    marginTop: spacing.sm,
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
});
