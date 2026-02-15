import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import { MediaCard } from './MediaCard';
import type { MediaItem } from '../api/models';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';

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
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.row}
      >
        {items.map((item) => (
          <View key={item.id} style={styles.cardWrap}>
            <MediaCard
              item={item}
              serverUrl={serverUrl}
              width={cardWidth}
              showProgress={showProgress}
              onPress={() => onItemPress(item.id)}
            />
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  section: {
    marginBottom: spacing.xl,
  },
  sectionTitle: {
    fontSize: 22,
    fontWeight: '600',
    color: colors.textPrimary,
    marginBottom: spacing.md,
    paddingHorizontal: spacing.md,
  },
  row: {
    paddingHorizontal: spacing.md,
    gap: spacing.md,
    paddingBottom: spacing.sm,
  },
  cardWrap: {
    marginRight: spacing.md,
  },
});
