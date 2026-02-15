import "./global.css";
import React from 'react';
import { View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
  useFonts,
  Outfit_400Regular,
  Outfit_500Medium,
  Outfit_600SemiBold,
} from '@expo-google-fonts/outfit';
import { AuthProvider, useAuth } from './src/context/AuthContext';
import { LibraryProvider } from './src/context/LibraryContext';
import { RootNavigator } from './src/navigation/RootNavigator';
import { SplashScreen } from './src/screens/SplashScreen';
import { LoginScreen } from './src/screens/LoginScreen';

function AppContent() {
  const { state } = useAuth();

  if (state.status === 'initial' || state.status === 'loading') {
    return <SplashScreen />;
  }
  if (state.status !== 'authenticated') {
    return <LoginScreen />;
  }
  return (
    <LibraryProvider>
      <RootNavigator />
    </LibraryProvider>
  );
}

export default function App() {
  const [fontsLoaded] = useFonts({
    Outfit_400Regular,
    Outfit_500Medium,
    Outfit_600SemiBold,
  });

  if (!fontsLoaded) {
    return (
      <View className="flex-1 bg-finar-bg" />
    );
  }

  return (
    <SafeAreaProvider>
      <AuthProvider>
        <StatusBar style="light" />
        <AppContent />
      </AuthProvider>
    </SafeAreaProvider>
  );
}
