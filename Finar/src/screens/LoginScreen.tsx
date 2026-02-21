import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withDelay,
  FadeIn,
  FadeInDown,
} from 'react-native-reanimated';
import { Play } from 'lucide-react-native';
import { useAuth } from '../context/AuthContext';

export function LoginScreen() {
  const { login, state, connectToServer, initiateQuickConnect, checkQuickConnect } = useAuth();
  const [serverUrl, setServerUrl] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [quickConnectCode, setQuickConnectCode] = useState<string | null>(null);
  const [quickConnectPolling, setQuickConnectPolling] = useState(false);

  const isLoading = state.status === 'loading';
  const error = state.status === 'error' ? state.message : null;

  const handleLogin = async () => {
    const url = serverUrl.trim();
    if (!url) return;
    if (!username.trim()) return;
    await login(url, username.trim(), password);
  };

  const handleQuickConnect = async () => {
    const url = serverUrl.trim();
    if (!url) return;
    const connected = await connectToServer(url);
    if (!connected) return;
    const code = await initiateQuickConnect();
    if (code) {
      setQuickConnectCode(code);
      setQuickConnectPolling(true);
      const interval = setInterval(async () => {
        const ok = await checkQuickConnect(code);
        if (ok) {
          clearInterval(interval);
          setQuickConnectPolling(false);
          setQuickConnectCode(null);
        }
      }, 2000);
      setTimeout(() => {
        clearInterval(interval);
        setQuickConnectPolling(false);
        setQuickConnectCode(null);
      }, 5 * 60 * 1000);
    }
  };

  if (quickConnectCode) {
    return (
      <View className="flex-1 bg-finar-bg">
        <LinearGradient
          colors={['#0D0D0F', '#0f1520', '#0D0D0F']}
          locations={[0, 0.5, 1]}
          className="absolute inset-0"
        />
        <Animated.View
          entering={FadeIn.duration(400)}
          className="flex-1 justify-center items-center px-8"
        >
          <View className="bg-finar-surface/90 border border-finar-glass-border rounded-finar-xl p-8 max-w-[420px] w-full">
            <Text
              className="text-2xl font-semibold text-finar-text-primary mb-2"
              style={{ fontFamily: 'Outfit_600SemiBold' }}
            >
              Quick Connect
            </Text>
            <Text className="text-base text-finar-text-secondary mb-6">
              Enter this code in your Jellyfin dashboard
            </Text>
            <View className="bg-finar-primary/20 py-4 px-8 rounded-finar-lg items-center mb-4">
              <Text
                className="text-[42px] font-bold text-finar-primary tracking-[8px]"
                style={{ fontFamily: 'Outfit_600SemiBold' }}
              >
                {quickConnectCode}
              </Text>
            </View>
            {quickConnectPolling && (
              <ActivityIndicator color="#00E5B8" className="mb-4" />
            )}
            <TouchableOpacity
              className="py-4 rounded-finar-md border border-finar-glass-border items-center"
              onPress={() => {
                setQuickConnectCode(null);
                setQuickConnectPolling(false);
              }}
            >
              <Text
                className="text-base font-semibold text-finar-text-primary"
                style={{ fontFamily: 'Outfit_600SemiBold' }}
              >
                Cancel
              </Text>
            </TouchableOpacity>
          </View>
        </Animated.View>
      </View>
    );
  }

  return (
    <View className="flex-1 bg-finar-bg">
      <LinearGradient
        colors={['#0D0D0F', '#0d1520', '#0f1a26', '#0D0D0F']}
        locations={[0, 0.35, 0.65, 1]}
        className="absolute inset-0"
      />
      <KeyboardAvoidingView
        className="flex-1"
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', paddingVertical: 48, paddingHorizontal: 32 }}
          keyboardShouldPersistTaps="handled"
        >
          <Animated.View
            entering={FadeInDown.delay(100).duration(500)}
            className="items-center mb-12"
          >
            <View className="w-[76px] h-[76px] rounded-[18px] bg-finar-primary items-center justify-center shadow-finar-glow">
              <Play size={40} color="#0D0D0F" fill="#0D0D0F" />
            </View>
            <Text
              className="text-[44px] font-semibold text-finar-primary mt-4 tracking-tight"
              style={{ fontFamily: 'Outfit_600SemiBold' }}
            >
              Finar
            </Text>
            <Text
              className="text-sm text-finar-text-tertiary mt-1 tracking-widest"
              style={{ fontFamily: 'Outfit_400Regular' }}
            >
              Your Jellyfin Experience
            </Text>
          </Animated.View>

          <Animated.View
            entering={FadeIn.delay(300).duration(500)}
            className="bg-finar-surface/95 border border-finar-glass-border rounded-finar-xl p-8 max-w-[420px] w-full self-center"
          >
            <Text
              className="text-[28px] font-semibold text-finar-text-primary"
              style={{ fontFamily: 'Outfit_600SemiBold' }}
            >
              Welcome
            </Text>
            <Text
              className="text-sm text-finar-text-secondary mt-2 mb-6"
              style={{ fontFamily: 'Outfit_400Regular' }}
            >
              Sign in to your Jellyfin server
            </Text>

            <TextInput
              className="bg-finar-bg-secondary rounded-finar-md px-4 py-4 text-base text-finar-text-primary border border-finar-glass-border mb-4"
              placeholder="Server URL (e.g. https://jellyfin.example.com)"
              placeholderTextColor="#707070"
              value={serverUrl}
              onChangeText={setServerUrl}
              autoCapitalize="none"
              autoCorrect={false}
              keyboardType="url"
            />
            <TextInput
              className="bg-finar-bg-secondary rounded-finar-md px-4 py-4 text-base text-finar-text-primary border border-finar-glass-border mb-4"
              placeholder="Username"
              placeholderTextColor="#707070"
              value={username}
              onChangeText={setUsername}
              autoCapitalize="none"
            />
            <TextInput
              className="bg-finar-bg-secondary rounded-finar-md px-4 py-4 text-base text-finar-text-primary border border-finar-glass-border mb-2"
              placeholder="Password"
              placeholderTextColor="#707070"
              value={password}
              onChangeText={setPassword}
              secureTextEntry={!showPassword}
            />
            <TouchableOpacity
              onPress={() => setShowPassword((p) => !p)}
              className="self-end mb-4"
            >
              <Text
                className="text-sm text-finar-primary"
                style={{ fontFamily: 'Outfit_500Medium' }}
              >
                {showPassword ? 'Hide' : 'Show'} password
              </Text>
            </TouchableOpacity>

            {error && (
              <Animated.View
                entering={FadeIn.duration(200)}
                className="bg-finar-error/20 rounded-finar-md p-4 mb-4 border border-finar-error/50"
              >
                <Text className="text-sm text-finar-error">{error}</Text>
              </Animated.View>
            )}

            <TouchableOpacity
              className="bg-finar-primary py-4 rounded-finar-md items-center justify-center min-h-[56px] mb-4"
              onPress={handleLogin}
              disabled={isLoading}
            >
              {isLoading ? (
                <ActivityIndicator color="#0D0D0F" />
              ) : (
                <Text
                  className="text-base font-semibold text-finar-text-on-primary"
                  style={{ fontFamily: 'Outfit_600SemiBold' }}
                >
                  Sign In
                </Text>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              className="py-4 rounded-finar-md border border-finar-glass-border items-center justify-center min-h-[56px]"
              onPress={handleQuickConnect}
              disabled={isLoading}
            >
              <Text
                className="text-base font-semibold text-finar-text-primary"
                style={{ fontFamily: 'Outfit_600SemiBold' }}
              >
                Quick Connect
              </Text>
            </TouchableOpacity>
          </Animated.View>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}
