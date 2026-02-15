import React, { useState } from 'react';
import { View, Text, TextInput, FlatList, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useLibrary } from '../context/LibraryContext';
import { useJellyfinApi } from '../context/AuthContext';
import { MediaCard } from '../components/MediaCard';

export function SearchScreen() {
  const navigation = useNavigation();
  const { searchResults, search, clearSearch } = useLibrary();
  const api = useJellyfinApi();
  const serverUrl = api.serverUrl ?? '';
  const [query, setQuery] = useState('');

  const handleSearch = (text: string) => {
    setQuery(text);
    if (text.length >= 2) search(text);
    else clearSearch();
  };

  const navigateToDetail = (itemId: string) => {
    (navigation as { navigate: (n: string, p: object) => void }).navigate('Detail', { itemId });
  };

  return (
    <View className="flex-1 bg-finar-bg">
      <View className="flex-row items-center p-4 pt-12 gap-2">
        <TextInput
          className="flex-1 bg-finar-surface rounded-lg px-4 py-3 text-base text-finar-text-primary border border-finar-glass-border"
          placeholder="Search movies, shows, music..."
          placeholderTextColor="#707070"
          value={query}
          onChangeText={handleSearch}
          autoFocus
        />
        {query.length > 0 && (
          <TouchableOpacity onPress={() => handleSearch('')}>
            <Text className="text-sm text-finar-primary" style={{ fontFamily: 'Outfit_500Medium' }}>Clear</Text>
          </TouchableOpacity>
        )}
      </View>
      {searchResults.length === 0 ? (
        <View className="flex-1 justify-center items-center px-8">
          <Text className="text-xl font-semibold text-finar-text-secondary mb-2" style={{ fontFamily: 'Outfit_600SemiBold' }}>Search your media</Text>
          <Text className="text-sm text-finar-text-tertiary" style={{ fontFamily: 'Outfit_400Regular' }}>Find movies, TV shows, and more</Text>
        </View>
      ) : (
        <FlatList
          data={searchResults}
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
      )}
    </View>
  );
}
