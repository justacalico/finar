import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Image } from 'expo-image';
import type { MediaItem } from '../api/models';
import { getDisplayImageUrl, getPlaybackProgress } from '../api/itemImages';
import { colors } from '../theme/colors';
import { radius } from '../theme/spacing';

type MediaCardProps = {
  item: MediaItem;
  serverUrl: string;
  width?: number;
  showProgress?: boolean;
  onPress: () => void;
};

export function MediaCard({
  item,
  serverUrl,
  width = 120,
  showProgress = false,
  onPress,
}: MediaCardProps) {
  const imageUrl = getDisplayImageUrl(serverUrl, item, { width: Math.round(width * 2) });
  const progress = showProgress ? getPlaybackProgress(item) : undefined;

  return (
    <TouchableOpacity style={[styles.card, { width }]} onPress={onPress} activeOpacity={0.9}>
      <Image
        source={{ uri: imageUrl }}
        style={[styles.image, { width, height: width * (3 / 2) }]}
        contentFit="cover"
      />
      {progress != null && progress > 0 && progress < 1 && (
        <View style={styles.progressTrack}>
          <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
        </View>
      )}
      <View style={styles.info}>
        <Text style={styles.title} numberOfLines={2}>
          {item.name}
        </Text>
        {item.productionYear != null && (
          <Text style={styles.subtitle}>{item.productionYear}</Text>
        )}
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: radius.md,
    overflow: 'hidden',
    backgroundColor: colors.surface,
  },
  image: {
    borderRadius: radius.md,
  },
  progressTrack: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 44,
    height: 4,
    backgroundColor: colors.glassBorder,
    marginHorizontal: 8,
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary,
  },
  info: {
    padding: 8,
    paddingTop: 6,
  },
  title: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  subtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
});
