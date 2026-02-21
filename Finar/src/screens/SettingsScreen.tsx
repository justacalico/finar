import React from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { useAuth } from '../context/AuthContext';
import { AppShell } from '../components/layout/AppShell';

export function SettingsScreen() {
  const { state: authState, logout } = useAuth();
  const user = authState.status === 'authenticated' ? authState.user : null;

  return (
    <AppShell activeTab="settings" title="Settings">
      <ScrollView className="flex-1" contentContainerStyle={{ padding: 20, paddingBottom: 120 }}>
        <View className="rounded-finar-xl bg-finar-surface border border-finar-glass-border p-5 mb-4">
          <Text className="text-xs uppercase tracking-[1px] text-finar-text-tertiary mb-2" style={{ fontFamily: 'Outfit_500Medium' }}>
            Account
          </Text>
          <Text className="text-[22px] text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>
            {user?.name ?? 'Guest'}
          </Text>
          <Text className="text-sm text-finar-text-secondary mt-1" style={{ fontFamily: 'Outfit_400Regular' }}>
            Connected to your Jellyfin server
          </Text>
          <TouchableOpacity
            className="mt-5 py-3 px-4 rounded-finar-md bg-finar-primary"
            onPress={() => logout()}
          >
            <Text className="text-center text-finar-text-on-primary text-base" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              Sign out
            </Text>
          </TouchableOpacity>
        </View>

        <View className="rounded-finar-xl bg-finar-surface border border-finar-glass-border p-5">
          <Text className="text-xs uppercase tracking-[1px] text-finar-text-tertiary mb-2" style={{ fontFamily: 'Outfit_500Medium' }}>
            About
          </Text>
          <Text className="text-lg text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>
            Finar
          </Text>
          <Text className="text-sm text-finar-text-secondary mt-1" style={{ fontFamily: 'Outfit_400Regular' }}>
            A polished Jellyfin experience for desktop and mobile.
          </Text>
          <Text className="text-xs text-finar-text-tertiary mt-4" style={{ fontFamily: 'Outfit_400Regular' }}>
            Version 1.0.0
          </Text>
        </View>
      </ScrollView>
    </AppShell>
  );
}
