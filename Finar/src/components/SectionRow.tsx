import React from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { MediaCard } from './MediaCard';
import type { MediaItem } from '../api/models';

type SectionRowProps = {
  title: string;
  items: MediaItem[];
  serverUrl: string;
  onItemPress: (itemId: string) => void;
  showProgress?: boolean;
  cardWidth?: number;
  onSeeAllPress?: () => void;
};

export function SectionRow({
  title,
  items,
  serverUrl,
  onItemPress,
  showProgress = false,
  cardWidth = 120,
  onSeeAllPress,
}: SectionRowProps) {
  if (items.length === 0) return null;

  return (
    <View className="mb-7">
      <View className="px-4 mb-3 flex-row items-center justify-between">
        <Text
          className="text-[28px] font-semibold text-finar-text-primary"
          style={{ fontFamily: 'Outfit_600SemiBold' }}
        >
          {title}
        </Text>
        <TouchableOpacity onPress={onSeeAllPress}>
          <Text className="text-xs text-finar-primary" style={{ fontFamily: 'Outfit_500Medium' }}>
            See all
          </Text>
        </TouchableOpacity>
      </View>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 16, gap: 12, paddingBottom: 8 }}
      >
        {items.map((item, index) => (
          <View key={item.id}>
            <MediaCard
              item={item}
              serverUrl={serverUrl}
              width={cardWidth}
              showProgress={showProgress}
              onPress={() => onItemPress(item.id)}
              index={index}
            />
          </View>
        ))}
      </ScrollView>
    </View>
  );
}
