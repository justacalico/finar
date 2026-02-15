import React, { useEffect } from 'react';
import { View, Text, ActivityIndicator } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withDelay,
  withSequence,
} from 'react-native-reanimated';

export function SplashScreen() {
  const logoScale = useSharedValue(0.6);
  const logoOpacity = useSharedValue(0);
  const titleOpacity = useSharedValue(0);
  const titleY = useSharedValue(12);
  const spinnerOpacity = useSharedValue(0);

  useEffect(() => {
    logoOpacity.value = withDelay(80, withTiming(1, { duration: 400 }));
    logoScale.value = withDelay(
      80,
      withSequence(
        withTiming(1.05, { duration: 350 }),
        withTiming(1, { duration: 150 })
      )
    );
    titleOpacity.value = withDelay(280, withTiming(1, { duration: 400 }));
    titleY.value = withDelay(280, withTiming(0, { duration: 400 }));
    spinnerOpacity.value = withDelay(500, withTiming(1, { duration: 300 }));
  }, []);

  const logoAnimated = useAnimatedStyle(() => ({
    opacity: logoOpacity.value,
    transform: [{ scale: logoScale.value }],
  }));
  const titleAnimated = useAnimatedStyle(() => ({
    opacity: titleOpacity.value,
    transform: [{ translateY: titleY.value }],
  }));
  const spinnerAnimated = useAnimatedStyle(() => ({
    opacity: spinnerOpacity.value,
  }));

  return (
    <View className="flex-1 bg-finar-bg items-center justify-center">
      <Animated.View
        style={logoAnimated}
        className="w-20 h-20 rounded-[20px] bg-finar-primary items-center justify-center shadow-finar-glow"
      >
        <Text className="text-4xl text-finar-text-on-primary">▶</Text>
      </Animated.View>
      <Animated.Text
        style={[titleAnimated, { fontFamily: 'Outfit_600SemiBold' }]}
        className="text-[36px] font-semibold text-finar-text-primary mt-6 tracking-tight"
      >
        Finar
      </Animated.Text>
      <Animated.View style={spinnerAnimated} className="mt-12">
        <ActivityIndicator size="small" color="#00E5B8" />
      </Animated.View>
    </View>
  );
}
