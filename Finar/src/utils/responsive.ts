import { Dimensions, ScaledSize } from 'react-native';

export const BREAKPOINTS = {
  mobile: 600,
  tablet: 900,
  desktop: 1200,
  largeDesktop: 1800,
} as const;

export type DeviceType = 'mobile' | 'tablet' | 'desktop' | 'largeDesktop';

export function getDeviceType(width: number): DeviceType {
  if (width < BREAKPOINTS.mobile) return 'mobile';
  if (width < BREAKPOINTS.tablet) return 'tablet';
  if (width < BREAKPOINTS.desktop) return 'desktop';
  return 'largeDesktop';
}

export function isMobile(width: number) {
  return width < BREAKPOINTS.mobile;
}

export function isTablet(width: number) {
  return width >= BREAKPOINTS.mobile && width < BREAKPOINTS.tablet;
}

export function isDesktop(width: number) {
  return width >= BREAKPOINTS.tablet;
}

export function useIsNarrow(): boolean {
  const { width } = Dimensions.get('window');
  return width < BREAKPOINTS.tablet;
}

export function getResponsiveValue<T>(
  width: number,
  values: { mobile: T; tablet?: T; desktop?: T; largeDesktop?: T }
): T {
  const device = getDeviceType(width);
  return (
    (device === 'largeDesktop' && (values.largeDesktop ?? values.desktop ?? values.tablet ?? values.mobile)) ??
    (device === 'desktop' && (values.desktop ?? values.tablet ?? values.mobile)) ??
    (device === 'tablet' && (values.tablet ?? values.mobile)) ??
    values.mobile
  );
}

export function gridColumns(width: number): number {
  return getResponsiveValue(width, { mobile: 2, tablet: 3, desktop: 4, largeDesktop: 6 });
}

export function horizontalPadding(width: number): number {
  return getResponsiveValue(width, { mobile: 16, tablet: 24, desktop: 32, largeDesktop: 48 });
}

export function sidebarWidth(width: number): number {
  return getResponsiveValue(width, { mobile: 0, tablet: 80, desktop: 240, largeDesktop: 280 });
}

export function showSidebar(width: number): boolean {
  return isDesktop(width);
}

export function useBottomNav(width: number): boolean {
  return !isDesktop(width);
}

export type DimensionsSubscription = (dims: { window: ScaledSize; screen: ScaledSize }) => void;
