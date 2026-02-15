import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../context/AuthContext';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';

export function SettingsScreen() {
  const navigation = useNavigation();
  const { state: authState, logout } = useAuth();
  const user = authState.status === 'authenticated' ? authState.user : null;

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Settings</Text>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Account</Text>
        <View style={styles.row}>
          <Text style={styles.label}>Signed in as</Text>
          <Text style={styles.value}>{user?.name ?? 'Guest'}</Text>
        </View>
        <TouchableOpacity style={styles.button} onPress={() => logout()}>
          <Text style={styles.buttonText}>Sign out</Text>
        </TouchableOpacity>
      </View>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>
        <Text style={styles.aboutText}>Finar – A beautiful Jellyfin client</Text>
        <Text style={styles.aboutVersion}>Version 1.0.0</Text>
      </View>
      <TouchableOpacity
        style={styles.backButton}
        onPress={() => (navigation as { goBack: () => void }).goBack()}
      >
        <Text style={styles.backButtonText}>Back</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: spacing.lg,
    paddingTop: 48,
    paddingBottom: 80,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: spacing.xl,
  },
  section: {
    marginBottom: spacing.xl,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.textSecondary,
    marginBottom: spacing.md,
  },
  row: {
    marginBottom: spacing.sm,
  },
  label: {
    fontSize: 13,
    color: colors.textTertiary,
  },
  value: {
    fontSize: 16,
    color: colors.textPrimary,
    marginTop: 2,
  },
  button: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.glassBorder,
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.lg,
    borderRadius: radius.md,
    marginTop: spacing.md,
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.primary,
  },
  aboutText: {
    fontSize: 15,
    color: colors.textSecondary,
  },
  aboutVersion: {
    fontSize: 13,
    color: colors.textTertiary,
    marginTop: 4,
  },
  backButton: {
    marginTop: spacing.xl,
    paddingVertical: spacing.md,
    alignItems: 'center',
  },
  backButtonText: {
    fontSize: 16,
    color: colors.primary,
    fontWeight: '600',
  },
});
