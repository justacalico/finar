import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  useWindowDimensions,
  RefreshControl,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../context/AuthContext';
import { useLibrary } from '../context/LibraryContext';
import { SectionRow } from '../components/SectionRow';
import { MediaCard } from '../components/MediaCard';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { BREAKPOINTS } from '../utils/responsive';
import { getBackdropImageUrl, getHeroTitle } from '../api/itemImages';
import type { MediaItem, Library } from '../api/models';
import { Image } from 'expo-image';

type NavTab = 'home' | 'search' | 'library' | 'downloads';

export function HomeScreen() {
  const { width } = useWindowDimensions();
  const navigation = useNavigation();
  const { api, state: authState, logout } = useAuth();
  const {
    homeData,
    libraries,
    isLoading,
    loadHomeData,
    featuredItem,
  } = useLibrary();

  const [navIndex, setNavIndex] = useState<NavTab>('home');
  const [refreshing, setRefreshing] = useState(false);

  const serverUrl = api.serverUrl ?? '';
  const isWide = width >= BREAKPOINTS.tablet;
  const showSidebar = isWide;

  const onRefresh = async () => {
    setRefreshing(true);
    await loadHomeData();
    setRefreshing(false);
  };

  const navigateToDetail = (itemId: string) => {
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Detail', {
      itemId,
    });
  };

  const navigateToLibrary = (libraryId: string, collectionType?: string) => {
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Library', {
      libraryId,
      isMusic: collectionType?.toLowerCase() === 'music',
    });
  };

  const navigateToPlayer = (item: MediaItem) => {
    (navigation as { navigate: (name: string, params: object) => void }).navigate('Player', {
      itemId: item.id,
    });
  };

  if (isLoading && !homeData) {
    return (
      <View style={styles.centered}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  const content = (
    <ScrollView
      style={styles.scroll}
      contentContainerStyle={styles.scrollContent}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.primary} />
      }
    >
      {featuredItem && (
        <TouchableOpacity
          style={styles.hero}
          onPress={() => navigateToDetail(featuredItem.id)}
          activeOpacity={0.95}
        >
          <Image
            source={{
              uri: getBackdropImageUrl(serverUrl, featuredItem, { width: 1200 }),
            }}
            style={StyleSheet.absoluteFill}
            contentFit="cover"
          />
          <View style={styles.heroOverlay} />
          <View style={styles.heroContent}>
            <Text style={styles.heroTitle} numberOfLines={2}>
              {getHeroTitle(featuredItem)}
            </Text>
            {featuredItem.overview && (
              <Text style={styles.heroOverview} numberOfLines={2}>
                {featuredItem.overview}
              </Text>
            )}
            <View style={styles.heroActions}>
              <TouchableOpacity
                style={styles.heroPlayButton}
                onPress={() => navigateToPlayer(featuredItem)}
              >
                <Text style={styles.heroPlayText}>Play</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.heroInfoButton}
                onPress={() => navigateToDetail(featuredItem.id)}
              >
                <Text style={styles.heroInfoText}>Info</Text>
              </TouchableOpacity>
            </View>
          </View>
        </TouchableOpacity>
      )}

      {homeData?.continueWatching && homeData.continueWatching.length > 0 && (
        <SectionRow
          title="Continue Watching"
          items={homeData.continueWatching}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          showProgress
          cardWidth={isWide ? 170 : 140}
        />
      )}
      {homeData?.nextUp && homeData.nextUp.length > 0 && (
        <SectionRow
          title="Next Up"
          items={homeData.nextUp}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {homeData?.recentlyAdded && homeData.recentlyAdded.length > 0 && (
        <SectionRow
          title="Recently Added"
          items={homeData.recentlyAdded}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {homeData?.recommended && homeData.recommended.length > 0 && (
        <SectionRow
          title="Recommended For You"
          items={homeData.recommended}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {homeData?.topRated && homeData.topRated.length > 0 && (
        <SectionRow
          title="Top Rated"
          items={homeData.topRated}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {homeData?.favorites && homeData.favorites.length > 0 && (
        <SectionRow
          title="My Favorites"
          items={homeData.favorites}
          serverUrl={serverUrl}
          onItemPress={navigateToDetail}
          cardWidth={isWide ? 170 : 120}
        />
      )}
      {libraries.length > 0 && (
        <View style={[styles.section, { paddingHorizontal: spacing.md }]}>
          <Text style={styles.sectionTitle}>Libraries</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.libraryRow}>
            {libraries.map((lib) => (
              <TouchableOpacity
                key={lib.id}
                style={styles.libraryCard}
                onPress={() => navigateToLibrary(lib.id, lib.collectionType)}
              >
                <Text style={styles.libraryIcon}>{getLibraryIcon(lib.collectionType)}</Text>
                <Text style={styles.libraryName} numberOfLines={2}>
                  {lib.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      )}
      <View style={{ height: 100 }} />
    </ScrollView>
  );

  if (showSidebar) {
    const user = authState.status === 'authenticated' ? authState.user : null;
    return (
      <View style={styles.root}>
        <View style={styles.sidebar}>
          <View style={styles.sidebarLogo}>
            <Text style={styles.sidebarLogoIcon}>▶</Text>
            <Text style={styles.sidebarLogoText}>Finar</Text>
          </View>
          <TouchableOpacity
            style={[styles.navItem, navIndex === 'home' && styles.navItemActive]}
            onPress={() => setNavIndex('home')}
          >
            <Text style={styles.navIcon}>🏠</Text>
            <Text style={styles.navLabel}>Home</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.navItem, navIndex === 'search' && styles.navItemActive]}
            onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Search')}
          >
            <Text style={styles.navIcon}>🔍</Text>
            <Text style={styles.navLabel}>Search</Text>
          </TouchableOpacity>
          {libraries.slice(0, 8).map((lib) => (
            <TouchableOpacity
              key={lib.id}
              style={styles.navItem}
              onPress={() => navigateToLibrary(lib.id, lib.collectionType)}
            >
              <Text style={styles.navIcon}>{getLibraryIcon(lib.collectionType)}</Text>
              <Text style={styles.navLabel} numberOfLines={1}>
                {lib.name}
              </Text>
            </TouchableOpacity>
          ))}
          <View style={styles.sidebarFooter}>
            <Text style={styles.userName}>{user?.name ?? 'Guest'}</Text>
            <TouchableOpacity onPress={() => logout()}>
              <Text style={styles.logoutText}>Sign out</Text>
            </TouchableOpacity>
          </View>
          <TouchableOpacity
            style={styles.navItem}
            onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Settings')}
          >
            <Text style={styles.navIcon}>⚙</Text>
            <Text style={styles.navLabel}>Settings</Text>
          </TouchableOpacity>
        </View>
        <View style={styles.main}>{content}</View>
      </View>
    );
  }

  return (
    <View style={styles.root}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Finar</Text>
        <TouchableOpacity
          onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Settings')}
        >
          <Text style={styles.headerIcon}>⚙</Text>
        </TouchableOpacity>
      </View>
      {content}
      <View style={styles.bottomNav}>
        <TouchableOpacity
          style={[styles.bottomNavItem, navIndex === 'home' && styles.bottomNavItemActive]}
          onPress={() => setNavIndex('home')}
        >
          <Text style={styles.bottomNavIcon}>🏠</Text>
          <Text style={styles.bottomNavLabel}>Home</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.bottomNavItem}
          onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Search')}
        >
          <Text style={styles.bottomNavIcon}>🔍</Text>
          <Text style={styles.bottomNavLabel}>Search</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.bottomNavItem}
          onPress={() => (navigation as { navigate: (n: string) => void }).navigate('Library', { libraryId: '', isMusic: false })}
        >
          <Text style={styles.bottomNavIcon}>📚</Text>
          <Text style={styles.bottomNavLabel}>Library</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

function getLibraryIcon(collectionType?: string): string {
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

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.background,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
  loadingText: {
    color: colors.textSecondary,
    fontSize: 16,
  },
  sidebar: {
    width: 260,
    backgroundColor: colors.backgroundSecondary,
    borderRightWidth: 1,
    borderRightColor: colors.divider,
    paddingVertical: spacing.lg,
  },
  sidebarLogo: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.lg,
    gap: spacing.sm,
  },
  sidebarLogoIcon: {
    fontSize: 24,
  },
  sidebarLogoText: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  navItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    gap: spacing.sm,
  },
  navItemActive: {
    backgroundColor: colors.primary + '20',
    borderLeftWidth: 3,
    borderLeftColor: colors.primary,
  },
  navIcon: {
    fontSize: 20,
  },
  navLabel: {
    fontSize: 15,
    color: colors.textSecondary,
    flex: 1,
  },
  sidebarFooter: {
    marginTop: 'auto',
    padding: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
  },
  userName: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  logoutText: {
    fontSize: 13,
    color: colors.primary,
    marginTop: 4,
  },
  main: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    paddingTop: 48,
    backgroundColor: colors.background,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  headerIcon: {
    fontSize: 22,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  hero: {
    height: 320,
    marginBottom: spacing.lg,
    borderRadius: radius.lg,
    overflow: 'hidden',
    marginHorizontal: spacing.md,
  },
  heroOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.5)',
  },
  heroContent: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    padding: spacing.lg,
  },
  heroTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  heroOverview: {
    fontSize: 14,
    color: colors.textSecondary,
    marginTop: spacing.sm,
  },
  heroActions: {
    flexDirection: 'row',
    gap: spacing.md,
    marginTop: spacing.md,
  },
  heroPlayButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
    borderRadius: radius.md,
  },
  heroPlayText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textOnPrimary,
  },
  heroInfoButton: {
    backgroundColor: colors.glassBorder,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.sm,
    borderRadius: radius.md,
  },
  heroInfoText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  section: {
    marginBottom: spacing.lg,
  },
  sectionTitle: {
    fontSize: 22,
    fontWeight: '600',
    color: colors.textPrimary,
    marginBottom: spacing.md,
  },
  libraryRow: {
    flexDirection: 'row',
    gap: spacing.md,
    paddingBottom: spacing.sm,
  },
  libraryCard: {
    width: 160,
    padding: spacing.md,
    backgroundColor: colors.surface,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.glassBorder,
    alignItems: 'center',
  },
  libraryIcon: {
    fontSize: 32,
    marginBottom: spacing.sm,
  },
  libraryName: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textPrimary,
    textAlign: 'center',
  },
  bottomNav: {
    flexDirection: 'row',
    backgroundColor: colors.backgroundSecondary,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
    paddingBottom: 24,
    paddingTop: spacing.sm,
  },
  bottomNavItem: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  bottomNavItemActive: {
    backgroundColor: colors.primary + '15',
  },
  bottomNavIcon: {
    fontSize: 24,
  },
  bottomNavLabel: {
    fontSize: 10,
    color: colors.textSecondary,
    marginTop: 4,
  },
});
