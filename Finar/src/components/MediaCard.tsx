import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { Image } from 'expo-image';
import Animated, { FadeInRight } from 'react-native-reanimated';
import type { MediaItem } from '../api/models';
import { getDisplayImageUrl, getPlaybackProgress } from '../api/itemImages';

type MediaCardProps = {
  item: MediaItem;
  serverUrl: string;
  width?: number;
  showProgress?: boolean;
  onPress: () => void;
  index?: number;
};

export function MediaCard({
  item,
  serverUrl,
  width = 120,
  showProgress = false,
  onPress,
  index = 0,
}: MediaCardProps) {
  const imageUrl = getDisplayImageUrl(serverUrl, item, { width: Math.round(width * 2) });
  const progress = showProgress ? getPlaybackProgress(item) : undefined;
  const cardHeight = width * 1.45;

  return (
    <Animated.View
      entering={FadeInRight.delay(index * 40).duration(320).springify()}
      style={{ width }}
    >
      <TouchableOpacity
        className="rounded-[12px] overflow-hidden bg-finar-surface border border-white/10 shadow-finar-card"
        onPress={onPress}
        activeOpacity={0.9}
      >
        <Image
          source={{ uri: imageUrl }}
          style={{ width, height: cardHeight }}
          contentFit="cover"
          className="rounded-[12px]"
        />
        <View className="absolute inset-x-0 bottom-0 h-24 bg-black/60" />
        {progress != null && progress > 0 && progress < 1 && (
          <View className="absolute left-2 right-2 bottom-12 h-1 bg-finar-glass-border rounded-full overflow-hidden">
            <View
              className="h-full bg-finar-primary rounded-full"
              style={{ width: `${progress * 100}%` }}
            />
          </View>
        )}
        <View className="absolute left-0 right-0 bottom-0 px-2.5 pb-2.5">
          <Text
            className="text-[13px] text-finar-text-primary"
            style={{ fontFamily: 'Outfit_600SemiBold' }}
            numberOfLines={2}
          >
            {item.name}
          </Text>
          {item.productionYear != null && (
            <Text
              className="text-[11px] text-finar-text-secondary mt-0.5"
              style={{ fontFamily: 'Outfit_400Regular' }}
            >
              {item.productionYear}
            </Text>
          )}
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
}
