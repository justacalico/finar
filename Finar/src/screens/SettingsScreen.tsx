import React from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../context/AuthContext';

export function SettingsScreen() {
  const navigation = useNavigation();
  const { state: authState, logout } = useAuth();
  const user = authState.status === 'authenticated' ? authState.user : null;

  return (
    <ScrollView className="flex-1 bg-finar-bg" contentContainerStyle={{ padding: 24, paddingTop: 48, paddingBottom: 80 }}>
      <Text className="text-[28px] font-semibold text-finar-text-primary mb-8" style={{ fontFamily: 'Outfit_600SemiBold' }}>
        Settings
      </Text>
      <View className="mb-8">
        <Text className="text-lg font-semibold text-finar-text-secondary mb-4" style={{ fontFamily: 'Outfit_600SemiBold' }}>
          Account
        </Text>
        <View className="mb-2">
          <Text className="text-[13px] text-finar-text-tertiary" style={{ fontFamily: 'Outfit_400Regular' }}>Signed in as</Text>
          <Text className="text-base text-finar-text-primary mt-0.5" style={{ fontFamily: 'Outfit_600SemiBold' }}>{user?.name ?? 'Guest'}</Text>
        </View>
        <TouchableOpacity
          className="bg-finar-surface border border-finar-glass-border py-4 px-6 rounded-finar-md mt-4"
          onPress={() => logout()}
        >
          <Text className="text-base font-semibold text-finar-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>Sign out</Text>
        </TouchableOpacity>
      </View>
      <View className="mb-8">
        <Text className="text-lg font-semibold text-finar-text-secondary mb-4" style={{ fontFamily: 'Outfit_600SemiBold' }}>
          About
        </Text>
        <Text className="text-[15px] text-finar-text-secondary" style={{ fontFamily: 'Outfit_400Regular' }}>Finar – A beautiful Jellyfin client</Text>
        <Text className="text-[13px] text-finar-text-tertiary mt-1" style={{ fontFamily: 'Outfit_400Regular' }}>Version 1.0.0</Text>
      </View>
      <TouchableOpacity className="mt-8 py-4 items-center" onPress={() => (navigation as { goBack: () => void }).goBack()}>
        <Text className="text-base font-semibold text-finar-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>Back</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}
