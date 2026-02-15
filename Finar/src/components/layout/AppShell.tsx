import React from 'react';
import { View, Text, TouchableOpacity, ScrollView, useWindowDimensions } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '../../context/AuthContext';
import { useLibrary } from '../../context/LibraryContext';

type ShellTab = 'home' | 'search' | 'library' | 'settings';

type AppShellProps = {
  children: React.ReactNode;
  activeTab: ShellTab;
  title: string;
};

function iconForLibrary(collectionType?: string): string {
  switch (collectionType?.toLowerCase()) {
    case 'movies':
      return '🎬';
    case 'tvshows':
      return '📺';
    case 'music':
      return '🎵';
    case 'photos':
      return '🖼';
    default:
      return '📁';
  }
}

export function AppShell({ children, activeTab, title }: AppShellProps) {
  const { width } = useWindowDimensions();
  const navigation = useNavigation();
  const isDesktop = width >= 900;
  const { state: authState, logout } = useAuth();
  const { libraries } = useLibrary();
  const user = authState.status === 'authenticated' ? authState.user : null;

  const go = (name: string, params?: object) =>
    (navigation as { navigate: (route: string, routeParams?: object) => void }).navigate(
      name,
      params
    );

  const sidebar = (
    <View className="w-[248px] bg-[#0A0B10] border-r border-white/5">
      <View className="px-5 pt-6 pb-5 border-b border-white/5 flex-row items-center gap-2">
        <View className="w-7 h-7 rounded-lg bg-finar-primary items-center justify-center">
          <Text className="text-xs text-finar-text-on-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>
            ▶
          </Text>
        </View>
        <Text className="text-[26px] text-finar-text-primary mt-0.5" style={{ fontFamily: 'Outfit_600SemiBold' }}>
          Finar
        </Text>
      </View>

      <View className="px-3 pt-3">
        <ShellNavButton icon="⌂" label="Home" active={activeTab === 'home'} onPress={() => go('Home')} />
        <ShellNavButton icon="⌕" label="Search" active={activeTab === 'search'} onPress={() => go('Search')} />
        <ShellNavButton
          icon="▦"
          label="Library"
          active={activeTab === 'library'}
          onPress={() => go('Library', { libraryId: '' })}
        />
        <ShellNavButton icon="⚙" label="Settings" active={activeTab === 'settings'} onPress={() => go('Settings')} />
      </View>

      <View className="px-5 pt-5">
        <Text className="text-xs text-finar-text-tertiary mb-2 uppercase tracking-[1px]" style={{ fontFamily: 'Outfit_500Medium' }}>
          Libraries
        </Text>
        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 8 }}>
          {libraries.slice(0, 10).map((lib) => (
            <TouchableOpacity
              key={lib.id}
              onPress={() => go('Library', { libraryId: lib.id, isMusic: lib.collectionType?.toLowerCase() === 'music' })}
              className="flex-row items-center gap-2.5 py-2.5 px-2 rounded-finar-md hover:bg-white/5"
            >
              <Text className="text-xs">{iconForLibrary(lib.collectionType)}</Text>
              <Text className="text-[13px] text-finar-text-secondary flex-1" numberOfLines={1} style={{ fontFamily: 'Outfit_400Regular' }}>
                {lib.name}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      <View className="mt-auto border-t border-white/5 px-4 py-4">
        <Text className="text-sm text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }} numberOfLines={1}>
          {user?.name ?? 'Guest'}
        </Text>
        <Text className="text-[11px] text-finar-text-tertiary mt-0.5" numberOfLines={1} style={{ fontFamily: 'Outfit_400Regular' }}>
          Connected
        </Text>
        <TouchableOpacity onPress={logout} className="mt-1">
          <Text className="text-[13px] text-finar-primary" style={{ fontFamily: 'Outfit_500Medium' }}>
            Sign out
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );

  if (isDesktop) {
    return (
      <View className="flex-1 flex-row bg-[#05060A]">
        {sidebar}
        <View className="flex-1 relative bg-[#07080D]">
          <LinearGradient
            colors={['rgba(0,229,184,0.07)', 'rgba(0,184,217,0.03)', 'rgba(13,13,15,0)']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 240 }}
          />
          <View className="h-14 px-7 border-b border-white/5 flex-row items-center justify-between">
            <Text className="text-[18px] text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              {title}
            </Text>
            <Text className="text-xs text-finar-text-tertiary" style={{ fontFamily: 'Outfit_400Regular' }}>
              Jellyfin client
            </Text>
          </View>
          <View className="flex-1">{children}</View>
        </View>
      </View>
    );
  }

  return (
    <View className="flex-1 bg-finar-bg">
      <LinearGradient
        colors={['rgba(0,229,184,0.14)', 'rgba(13,13,15,0)']}
        start={{ x: 0.2, y: 0 }}
        end={{ x: 0.8, y: 1 }}
        style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 180 }}
      />
      <View className="pt-12 pb-3 px-4 border-b border-finar-divider flex-row items-center justify-between">
        <Text className="text-[24px] text-finar-text-primary" style={{ fontFamily: 'Outfit_600SemiBold' }}>
          {title}
        </Text>
        <TouchableOpacity onPress={() => go('Settings')}>
          <Text className="text-xl">⚙</Text>
        </TouchableOpacity>
      </View>
      <View className="flex-1">{children}</View>
      <View className="flex-row border-t border-finar-divider bg-finar-bg-secondary pb-6 pt-2">
        <MobileNavButton icon="⌂" label="Home" active={activeTab === 'home'} onPress={() => go('Home')} />
        <MobileNavButton icon="⌕" label="Search" active={activeTab === 'search'} onPress={() => go('Search')} />
        <MobileNavButton
          icon="▦"
          label="Library"
          active={activeTab === 'library'}
          onPress={() => go('Library', { libraryId: '' })}
        />
      </View>
    </View>
  );
}

function ShellNavButton({
  icon,
  label,
  active,
  onPress,
}: {
  icon: string;
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <TouchableOpacity
      onPress={onPress}
      className={`flex-row items-center gap-2.5 px-3 py-3 rounded-finar-md mb-1 border ${
        active
          ? 'bg-[#0E2623] border-finar-primary/35'
          : 'bg-transparent border-transparent'
      }`}
    >
      <Text className={`text-base ${active ? 'text-finar-primary' : 'text-finar-text-tertiary'}`}>{icon}</Text>
      <Text
        className={`${active ? 'text-finar-text-primary' : 'text-finar-text-secondary'} text-[15px]`}
        style={{ fontFamily: active ? 'Outfit_600SemiBold' : 'Outfit_500Medium' }}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );
}

function MobileNavButton({
  icon,
  label,
  active,
  onPress,
}: {
  icon: string;
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <TouchableOpacity onPress={onPress} className="flex-1 items-center py-2">
      <Text className="text-[22px]">{icon}</Text>
      <Text
        className={`${active ? 'text-finar-primary' : 'text-finar-text-tertiary'} text-[11px] mt-1`}
        style={{ fontFamily: active ? 'Outfit_600SemiBold' : 'Outfit_400Regular' }}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );
}
