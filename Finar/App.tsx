import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
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
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <StatusBar style="light" />
        <AppContent />
      </AuthProvider>
    </SafeAreaProvider>
  );
}
