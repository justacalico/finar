import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useAuth } from '../context/AuthContext';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';

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
      <View style={styles.container}>
        <View style={styles.formCard}>
          <Text style={styles.quickTitle}>Quick Connect</Text>
          <Text style={styles.quickSubtitle}>
            Enter this code in your Jellyfin dashboard
          </Text>
          <View style={styles.codeBox}>
            <Text style={styles.codeText}>{quickConnectCode}</Text>
          </View>
          {quickConnectPolling && (
            <ActivityIndicator color={colors.primary} style={styles.codeSpinner} />
          )}
          <TouchableOpacity
            style={[styles.button, styles.buttonOutlined]}
            onPress={() => {
              setQuickConnectCode(null);
              setQuickConnectPolling(false);
            }}
          >
            <Text style={styles.buttonTextOutlined}>Cancel</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.logoSection}>
          <View style={styles.logoBox}>
            <Text style={styles.logoIcon}>▶</Text>
          </View>
          <Text style={styles.brandTitle}>Finar</Text>
          <Text style={styles.tagline}>Your Jellyfin Experience</Text>
        </View>

        <View style={styles.formCard}>
          <Text style={styles.welcomeTitle}>Welcome</Text>
          <Text style={styles.welcomeSubtitle}>Sign in to your Jellyfin server</Text>

          <TextInput
            style={styles.input}
            placeholder="Server URL (e.g. https://jellyfin.example.com)"
            placeholderTextColor={colors.textTertiary}
            value={serverUrl}
            onChangeText={setServerUrl}
            autoCapitalize="none"
            autoCorrect={false}
            keyboardType="url"
          />
          <TextInput
            style={styles.input}
            placeholder="Username"
            placeholderTextColor={colors.textTertiary}
            value={username}
            onChangeText={setUsername}
            autoCapitalize="none"
          />
          <TextInput
            style={styles.input}
            placeholder="Password"
            placeholderTextColor={colors.textTertiary}
            value={password}
            onChangeText={setPassword}
            secureTextEntry={!showPassword}
          />
          <TouchableOpacity
            onPress={() => setShowPassword((p) => !p)}
            style={styles.showPassword}
          >
            <Text style={styles.showPasswordText}>
              {showPassword ? 'Hide' : 'Show'} password
            </Text>
          </TouchableOpacity>

          {error && (
            <View style={styles.errorBox}>
              <Text style={styles.errorText}>{error}</Text>
            </View>
          )}

          <TouchableOpacity
            style={[styles.button, styles.buttonPrimary]}
            onPress={handleLogin}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color={colors.textOnPrimary} />
            ) : (
              <Text style={styles.buttonTextPrimary}>Sign In</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.buttonOutlined]}
            onPress={handleQuickConnect}
            disabled={isLoading}
          >
            <Text style={styles.buttonTextOutlined}>Quick Connect</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: spacing.xl,
    paddingTop: 48,
    paddingBottom: 48,
  },
  logoSection: {
    alignItems: 'center',
    marginBottom: spacing.xxl,
  },
  logoBox: {
    width: 76,
    height: 76,
    borderRadius: 18,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoIcon: {
    fontSize: 44,
    color: colors.textOnPrimary,
  },
  brandTitle: {
    fontSize: 44,
    fontWeight: '700',
    color: colors.primary,
    marginTop: spacing.md,
    letterSpacing: -1,
  },
  tagline: {
    fontSize: 14,
    color: colors.textTertiary,
    marginTop: 4,
    letterSpacing: 1.5,
  },
  formCard: {
    backgroundColor: colors.surface,
    borderRadius: radius.xl,
    padding: spacing.xl,
    borderWidth: 1,
    borderColor: colors.glassBorder,
    maxWidth: 420,
    alignSelf: 'center',
    width: '100%',
  },
  welcomeTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  welcomeSubtitle: {
    fontSize: 14,
    color: colors.textSecondary,
    marginTop: spacing.sm,
    marginBottom: spacing.lg,
  },
  input: {
    backgroundColor: colors.backgroundSecondary,
    borderRadius: radius.md,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.md,
    fontSize: 16,
    color: colors.textPrimary,
    borderWidth: 1,
    borderColor: colors.glassBorder,
    marginBottom: spacing.md,
  },
  showPassword: {
    alignSelf: 'flex-end',
    marginBottom: spacing.md,
  },
  showPasswordText: {
    fontSize: 14,
    color: colors.primary,
  },
  errorBox: {
    backgroundColor: colors.error + '20',
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.error + '50',
  },
  errorText: {
    color: colors.error,
    fontSize: 14,
  },
  button: {
    paddingVertical: spacing.md,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 56,
    marginBottom: spacing.md,
  },
  buttonPrimary: {
    backgroundColor: colors.primary,
  },
  buttonTextPrimary: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textOnPrimary,
  },
  buttonOutlined: {
    borderWidth: 1,
    borderColor: colors.glassBorder,
  },
  buttonTextOutlined: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  quickTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: spacing.sm,
  },
  quickSubtitle: {
    fontSize: 16,
    color: colors.textSecondary,
    marginBottom: spacing.lg,
  },
  codeBox: {
    backgroundColor: colors.primary + '20',
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.xl,
    borderRadius: radius.lg,
    marginBottom: spacing.md,
    alignItems: 'center',
  },
  codeText: {
    fontSize: 42,
    fontWeight: '700',
    color: colors.primary,
    letterSpacing: 8,
  },
  codeSpinner: {
    marginBottom: spacing.md,
  },
});
