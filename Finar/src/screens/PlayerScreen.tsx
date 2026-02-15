import React, { useEffect, useState, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Dimensions,
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { Video, ResizeMode, AVPlaybackStatus } from 'expo-av';
import { useJellyfinApi } from '../context/AuthContext';
import { createMediaService } from '../api/mediaService';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';

type RouteParams = { itemId: string };

export function PlayerScreen() {
  const route = useRoute();
  const navigation = useNavigation();
  const { itemId } = (route.params ?? {}) as RouteParams;
  const api = useJellyfinApi();
  const mediaService = React.useMemo(() => createMediaService(api), [api]);
  const videoRef = useRef<Video>(null);
  const [streamUrl, setStreamUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(true);
  const [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0);
  const playSessionIdRef = useRef<string | null>(null);
  const reportedPositionRef = useRef(0);

  useEffect(() => {
    if (!itemId) return;
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const streamInfo = await mediaService.getStreamInfo(itemId);
        if (cancelled) return;
        setStreamUrl(streamInfo.url);
        playSessionIdRef.current = streamInfo.playSessionId ?? null;
        await api.reportPlaybackStart({
          itemId,
          mediaSourceId: streamInfo.mediaSource.id,
          playSessionId: streamInfo.playSessionId ?? undefined,
          positionTicks: 0,
          playMethod: streamInfo.isTranscoding ? 'Transcode' : 'DirectPlay',
        });
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'Failed to load stream');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [itemId, api, mediaService]);

  const reportProgress = async (posTicks: number) => {
    try {
      await api.reportPlaybackProgress({
        itemId,
        positionTicks: posTicks,
        isPaused: !isPlaying,
        playSessionId: playSessionIdRef.current ?? undefined,
      });
    } catch {
      /* ignore */
    }
  };

  const handlePlaybackStatusUpdate = (status: AVPlaybackStatus) => {
    if (!status.isLoaded) return;
    const posMs = status.positionMillis ?? 0;
    const durMs = status.durationMillis ?? 0;
    setPosition(posMs);
    setDuration(durMs);
    const posTicks = Math.round(posMs * 10000);
    if (Math.abs(posTicks - reportedPositionRef.current) > 10000000) {
      reportedPositionRef.current = posTicks;
      reportProgress(posTicks);
    }
  };

  useEffect(() => {
    return () => {
      const posTicks = Math.round(position * 10000);
      api.reportPlaybackStopped({
        itemId,
        positionTicks: posTicks,
        playSessionId: playSessionIdRef.current ?? undefined,
      }).catch(() => {});
    };
  }, [itemId]);

  const togglePlayPause = async () => {
    if (!videoRef.current) return;
    if (isPlaying) {
      await videoRef.current.pauseAsync();
    } else {
      await videoRef.current.playAsync();
    }
    setIsPlaying(!isPlaying);
  };

  const goBack = () => {
    (navigation as { goBack: () => void }).goBack();
  };

  const formatTime = (ms: number) => {
    const s = Math.floor(ms / 1000);
    const m = Math.floor(s / 60);
    const h = Math.floor(m / 60);
    if (h > 0) {
      return `${h}:${String(m % 60).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
    }
    return `${m}:${String(s % 60).padStart(2, '0')}`;
  };

  const { width, height } = Dimensions.get('window');

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.primary} />
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }
  if (error || !streamUrl) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorText}>{error ?? 'No stream URL'}</Text>
        <TouchableOpacity style={styles.backButton} onPress={goBack}>
          <Text style={styles.backButtonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Video
        ref={videoRef}
        source={{ uri: streamUrl }}
        style={{ width, height }}
        useNativeControls
        resizeMode={ResizeMode.CONTAIN}
        shouldPlay={isPlaying}
        onPlaybackStatusUpdate={handlePlaybackStatusUpdate}
      />
      <TouchableOpacity style={styles.closeButton} onPress={goBack}>
        <Text style={styles.closeButtonText}>✕</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.black,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
  loadingText: {
    color: colors.textSecondary,
    marginTop: spacing.md,
  },
  errorText: {
    color: colors.error,
    textAlign: 'center',
    paddingHorizontal: spacing.lg,
  },
  backButton: {
    marginTop: spacing.lg,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.md,
    backgroundColor: colors.primary,
    borderRadius: 8,
  },
  backButtonText: {
    color: colors.textOnPrimary,
    fontWeight: '600',
  },
  closeButton: {
    position: 'absolute',
    top: 48,
    right: spacing.md,
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.glassBackground,
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeButtonText: {
    color: colors.textPrimary,
    fontSize: 20,
  },
});
