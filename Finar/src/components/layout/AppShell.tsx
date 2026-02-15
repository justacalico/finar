import React from 'react';
import { View, Text, TouchableOpacity, ScrollView, useWindowDimensions } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { LinearGradient } from 'expo-linear-gradient';
import {
  House,
  Search,
  Heart,
  Download,
  Film,
  Music,
  Folder,
  ListMusic,
  Tv,
  Settings,
  LogOut,
  LibraryBig,
} from 'lucide-react-native';
import { useAuth } from '../../context/AuthContext';
import { useLibrary } from '../../context/LibraryContext';

type ShellTab = 'home' | 'search' | 'library' | 'settings';

type AppShellProps = {
  children: React.ReactNode;
  activeTab: ShellTab;
  title: string;
};

function libraryIcon(collectionType?: string) {
  const color = '#9CA3AF';
  const size = 18;
  switch (collectionType?.toLowerCase()) {
    case 'movies':
      return <Film size={size} color={color} />;
    case 'music':
      return <Music size={size} color={color} />;
    case 'musicvideos':
      return <Folder size={size} color={color} />;
    case 'playlists':
      return <ListMusic size={size} color={color} />;
    case 'tvshows':
      return <Tv size={size} color={color} />;
    default:
      return <LibraryBig size={size} color={color} />;
  }
}

function truncate(value: string, max = 18): string {
  if (value.length <= max) return value;
  return `${value.slice(0, max - 3)}...`;
}

export function AppShell({ children, activeTab, title }: AppShellProps) {
  const { width } = useWindowDimensions();
  const navigation = useNavigation();
  const isDesktop = width >= 900;
  const { state: authState, logout, api } = useAuth();
  const { libraries } = useLibrary();
  const user = authState.status === 'authenticated' ? authState.user : null;
  const serverUrl = api.serverUrl ?? 'Not connected';

  const go = (name: string, params?: object) =>
    (navigation as { navigate: (route: string, routeParams?: object) => void }).navigate(
      name,
      params
    );

  const navItems = [
    {
      id: 'home',
      label: 'Home',
      icon: <House size={20} color={activeTab === 'home' ? '#00E5B8' : '#9CA3AF'} />,
      onPress: () => go('Home'),
      active: activeTab === 'home',
    },
    {
      id: 'search',
      label: 'Search',
      icon: <Search size={20} color={activeTab === 'search' ? '#00E5B8' : '#9CA3AF'} />,
      onPress: () => go('Search'),
      active: activeTab === 'search',
    },
    {
      id: 'favorites',
      label: 'Favorites',
      icon: <Heart size={20} color="#9CA3AF" />,
      onPress: () => go('Home'),
      active: false,
    },
    {
      id: 'downloads',
      label: 'Downloads',
      icon: <Download size={20} color="#9CA3AF" />,
      onPress: () => go('Home'),
      active: false,
    },
  ];

  const sidebar = (
    <View className="w-[280px] bg-[#0D0D0F] px-4 pt-6 pb-4 border-r border-white/5">
      <View className="flex-row items-center gap-3 px-2 mb-8">
        <View className="w-11 h-11 rounded-xl bg-finar-primary items-center justify-center shadow-finar-glow">
          <View className="w-5 h-5 rounded-full bg-[#041B18] items-center justify-center">
            <Text className="text-[9px] text-finar-primary ml-[1px]" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              ▶
            </Text>
          </View>
        </View>
        <Text className="text-[40px] leading-[42px] text-white" style={{ fontFamily: 'Outfit_600SemiBold' }}>
          Finar
        </Text>
      </View>

      <View className="mb-7">
        {navItems.map((item) => (
          <TouchableOpacity
            key={item.id}
            onPress={item.onPress}
            className={`w-full flex-row items-center gap-4 px-4 py-3.5 rounded-xl mb-1 ${
              item.active
                ? 'bg-[#152A28] border border-[#00E5B8]/30'
                : 'bg-transparent border border-transparent'
            }`}
          >
            {item.icon}
            <Text
              className={`text-base ${item.active ? 'text-white' : 'text-[#9CA3AF]'}`}
              style={{ fontFamily: item.active ? 'Outfit_600SemiBold' : 'Outfit_500Medium' }}
            >
              {item.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <View className="flex-1">
        <Text
          className="text-[11px] text-[#4B5563] tracking-[4px] mb-4 px-4"
          style={{ fontFamily: 'Outfit_600SemiBold' }}
        >
          LIBRARIES
        </Text>
        <ScrollView showsVerticalScrollIndicator={false}>
          <View className="gap-1">
            {libraries.map((lib) => (
              <TouchableOpacity
                key={lib.id}
                onPress={() =>
                  go('Library', {
                    libraryId: lib.id,
                    isMusic: lib.collectionType?.toLowerCase() === 'music',
                  })
                }
                className="w-full flex-row items-center justify-between px-4 py-3 rounded-xl"
              >
                <View className="flex-row items-center gap-4 flex-1">
                  {libraryIcon(lib.collectionType)}
                  <Text
                    className="text-base text-[#9CA3AF] flex-1"
                    numberOfLines={1}
                    style={{ fontFamily: 'Outfit_500Medium' }}
                  >
                    {lib.name}
                  </Text>
                </View>
                {typeof lib.childCount === 'number' && (
                  <View className="w-7 h-7 rounded-full bg-[#1A1A1C] items-center justify-center">
                    <Text className="text-[11px] text-[#4B5563]" style={{ fontFamily: 'Outfit_600SemiBold' }}>
                      {lib.childCount > 99 ? '99+' : lib.childCount}
                    </Text>
                  </View>
                )}
              </TouchableOpacity>
            ))}

            <TouchableOpacity onPress={() => go('Settings')} className="w-full flex-row items-center gap-4 px-4 py-3 rounded-xl mt-3">
              <Settings size={20} color="#9CA3AF" />
              <Text className="text-base text-[#9CA3AF]" style={{ fontFamily: 'Outfit_500Medium' }}>
                Settings
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </View>

      <View className="mt-4 bg-[#151517] border border-white/10 p-3.5 rounded-2xl flex-row items-center justify-between">
        <View className="flex-row items-center gap-3 flex-1">
          <View className="w-[42px] h-[42px] rounded-xl bg-finar-primary items-center justify-center">
            <Text className="text-base text-[#111]" style={{ fontFamily: 'Outfit_600SemiBold' }}>
              {(user?.name ?? 'G').charAt(0).toUpperCase()}
            </Text>
          </View>
          <View className="flex-1">
            <Text className="text-[13px] text-white" numberOfLines={1} style={{ fontFamily: 'Outfit_600SemiBold' }}>
              {truncate(user?.name ?? 'Guest', 13)}
            </Text>
            <Text className="text-[11px] text-[#4B5563] mt-0.5" numberOfLines={1} style={{ fontFamily: 'Outfit_400Regular' }}>
              {truncate(serverUrl.replace(/^https?:\/\//, ''), 18)}
            </Text>
          </View>
        </View>
        <TouchableOpacity
          onPress={logout}
          className="w-9 h-9 rounded-full bg-[#252528] items-center justify-center"
        >
          <LogOut size={16} color="#9CA3AF" />
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
