import React, { useState } from 'react';
import { View, Text, TextInput, FlatList, TouchableOpacity, useWindowDimensions } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useLibrary } from '../context/LibraryContext';
import { useJellyfinApi } from '../context/AuthContext';
import { MediaCard } from '../components/MediaCard';
import { AppShell } from '../components/layout/AppShell';

export function SearchScreen() {
  const navigation = useNavigation();
  const { searchResults, search, clearSearch } = useLibrary();
  const api = useJellyfinApi();
  const { width } = useWindowDimensions();
  const serverUrl = api.serverUrl ?? '';
  const [query, setQuery] = useState('');
  const columns = width >= 1300 ? 6 : width >= 1000 ? 5 : width >= 760 ? 4 : 3;
  const cardWidth = width >= 1300 ? 170 : width >= 1000 ? 150 : width >= 760 ? 140 : 110;

  const handleSearch = (text: string) => {
    setQuery(text);
    if (text.length >= 2) search(text);
    else clearSearch();
  };

  const navigateToDetail = (itemId: string) => {
    (navigation as { navigate: (n: string, p: object) => void }).navigate('Detail', { itemId });
  };

  return (
    <AppShell activeTab="search" title="Search">
      <View className="flex-1">
        <View className="px-4 pt-4 pb-3">
          <View className="flex-row items-center gap-2 rounded-finar-lg border border-finar-glass-border bg-finar-surface px-3">
            <Text className="text-lg">🔎</Text>
            <TextInput
              className="flex-1 py-3 text-base text-finar-text-primary"
              placeholder="Search movies, shows, music..."
              placeholderTextColor="#707070"
              value={query}
              onChangeText={handleSearch}
              autoFocus
            />
            {query.length > 0 && (
              <TouchableOpacity onPress={() => handleSearch('')}>
                <Text className="text-sm text-finar-primary" style={{ fontFamily: 'Outfit_500Medium' }}>
                  Clear
                </Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {searchResults.length === 0 ? (
          <View className="flex-1 justify-center items-center px-8">
            <Text className="text-2xl text-finar-text-secondary mb-2" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              Find something great
            </Text>
            <Text className="text-sm text-finar-text-tertiary text-center" style={{ fontFamily: 'Outfit_400Regular' }}>
              Search your Jellyfin library for movies, series, and music.
            </Text>
          </View>
        ) : (
          <FlatList
            data={searchResults}
            keyExtractor={(item) => item.id}
            numColumns={columns}
            contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 120, paddingTop: 8 }}
            columnWrapperStyle={{ gap: 10, marginBottom: 14 }}
            renderItem={({ item, index }) => (
              <View>
                <MediaCard
                  item={item}
                  serverUrl={serverUrl}
                  width={cardWidth}
                  onPress={() => navigateToDetail(item.id)}
                  index={index}
                />
              </View>
            )}
          />
        )}
      </View>
    </AppShell>
  );
}
