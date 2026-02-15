import React from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';

export function SplashScreen() {
  return (
    <View style={styles.container}>
      <View style={styles.logoBox}>
        <Text style={styles.logoIcon}>▶</Text>
      </View>
      <Text style={styles.title}>Finar</Text>
      <ActivityIndicator size="small" color={colors.primary} style={styles.spinner} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoBox: {
    width: 80,
    height: 80,
    borderRadius: 20,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoIcon: {
    fontSize: 40,
    color: colors.textOnPrimary,
  },
  title: {
    fontSize: 36,
    fontWeight: '700',
    color: colors.textPrimary,
    marginTop: spacing.lg,
    letterSpacing: -0.5,
  },
  spinner: {
    marginTop: spacing.xxl,
  },
});
