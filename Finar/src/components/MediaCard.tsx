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

  return (
    <Animated.View
      entering={FadeInRight.delay(index * 40).duration(320).springify()}
      style={{ width }}
    >
      <TouchableOpacity
        className="rounded-finar-md overflow-hidden bg-finar-surface shadow-finar-card"
        onPress={onPress}
        activeOpacity={0.9}
      >
        <Image
          source={{ uri: imageUrl }}
          style={{ width, height: width * (3 / 2) }}
          contentFit="cover"
          className="rounded-finar-md"
        />
        {progress != null && progress > 0 && progress < 1 && (
          <View className="absolute left-2 right-2 bottom-11 h-1 bg-finar-glass-border rounded-full overflow-hidden">
            <View
              className="h-full bg-finar-primary rounded-full"
              style={{ width: `${progress * 100}%` }}
            />
          </View>
        )}
        <View className="p-2 pt-1.5">
          <Text
            className="text-sm font-semibold text-finar-text-primary"
            style={{ fontFamily: 'Outfit_600SemiBold' }}
            numberOfLines={2}
          >
            {item.name}
          </Text>
          {item.productionYear != null && (
            <Text
              className="text-xs text-finar-text-secondary mt-0.5"
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
