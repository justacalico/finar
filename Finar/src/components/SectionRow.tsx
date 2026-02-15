import React from 'react';
import { View, Text, ScrollView } from 'react-native';
import { MediaCard } from './MediaCard';
import type { MediaItem } from '../api/models';

type SectionRowProps = {
  title: string;
  items: MediaItem[];
  serverUrl: string;
  onItemPress: (itemId: string) => void;
  showProgress?: boolean;
  cardWidth?: number;
};

export function SectionRow({
  title,
  items,
  serverUrl,
  onItemPress,
  showProgress = false,
  cardWidth = 120,
}: SectionRowProps) {
  if (items.length === 0) return null;

  return (
    <View className="mb-8">
      <Text
        className="text-[22px] font-semibold text-finar-text-primary mb-4 px-4"
        style={{ fontFamily: 'Outfit_600SemiBold' }}
      >
        {title}
      </Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 16, gap: 16, paddingBottom: 8 }}
      >
        {items.map((item, index) => (
          <View key={item.id} className="mr-4">
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
