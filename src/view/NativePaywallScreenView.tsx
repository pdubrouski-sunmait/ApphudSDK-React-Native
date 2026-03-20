import React, { type ComponentProps, type ReactElement } from 'react';
import {
  requireNativeComponent,
  View,
  UIManager,
  StyleSheet,
  findNodeHandle,
  type NativeSyntheticEvent,
  type ViewStyle,
  type ViewProps,
} from 'react-native';
import {
  type ApphudProduct,
  type ApphudPurchaseResult,
  type PlacementsOptions,
} from '../module';
import { LoadingContent } from './LoadingContent';
import { ErrorContent } from './ErrorContent';
import { type LoadingViewError } from './types';

/**
 * Native paywall screen view bridged from the native layer.
 *
 * This component is a thin wrapper around the native `PaywallScreenView`
 * and is not intended to be used directly. Prefer using
 * {@link PaywallScreenView} instead.
 *
 * The native view is responsible for:
 * - loading and rendering the paywall UI
 * - handling user interactions
 * - emitting lifecycle and purchase-related events
 */
const NativePaywallScreenView = requireNativeComponent<{
  /**
   * Paywall placement identifier.
   * Determines which paywall configuration should be displayed.
   */
  placementIdentifier: string;

  /**
   * Called when the paywall starts loading.
   */
  onStartLoading?: (
    event: NativeSyntheticEvent<{ placementIdentifier: string }>
  ) => void;

  /**
   * Called when the native paywall view is fully received and rendered.
   */
  onReceiveView?: (event: NativeSyntheticEvent<{}>) => void;

  /**
   * Called when an error occurs while loading the paywall.
   */
  onLoadingError?: (
    event: NativeSyntheticEvent<{
      placementIdentifier: string;
      error: LoadingViewError;
    }>
  ) => void;

  /**
   * Called when a purchase transaction starts.
   */
  onTransactionStarted?: (
    event: NativeSyntheticEvent<{ result: ApphudProduct | null }>
  ) => void;

  /**
   * Called when a purchase transaction completes.
   */
  onTransactionCompleted?: (
    event: NativeSyntheticEvent<{ result: ApphudPurchaseResult | null }>
  ) => void;

  /**
   * Called when the user taps the close button.
   */
  onCloseButtonTapped?: (event: NativeSyntheticEvent<undefined>) => void;

  /**
   * Style applied to the native view.
   */
  style?: ViewStyle;
  /**
   * Options for requesting placements, such as retry attempts and force refresh.
   * This prop is optional and can be used to customize the behavior of placement requests.
   * If not provided, default options will be used.
   *
   * Use as const or use the `useMemo` (`useRef`) hook for remove rerendering on every render due to object reference change.
   *
   * Example usage:
   * ```tsx
   * const REQUEST_PLACEMENTS_OPTIONS = { maxAttempts: 4, forceRefresh: true };
   *
   * <PaywallScreenView
   *   placementIdentifier={placementId}
   *   requestPlacementsOptions={REQUEST_PLACEMENTS_OPTIONS}
   * />
   * ```
   */
  requestPlacementsOptions?: Partial<PlacementsOptions>;
}>('PaywallScreenView');

type Props = ComponentProps<typeof NativePaywallScreenView> &
  ViewProps & {
    /**
     * Custom renderer for the loading state.
     */
    renderLoading?: () => ReactElement;

    /**
     * Custom renderer for the error state.
     */
    renderError?: (
      error: LoadingViewError,
      onReload: () => void
    ) => ReactElement;
  };

/**
 * React component that displays a native paywall screen.
 * The way for usage - react-navigation screen (modal)
 *
 * This component:
 * - wraps the native paywall view
 * - manages loading and error overlay states
 * - provides default UI for loading and error states
 * - exposes lifecycle and purchase-related callbacks
 *
 * The paywall content itself is rendered natively.
 *
 * @example
 * ```tsx
 * <PaywallScreenView
 *   placementIdentifier={placementId}
 *   onTransactionCompleted={(event) => {
 *     console.log(event.nativeEvent.result);
 *   }}
 * />
 * ```
 */
export const PaywallScreenView: React.FC<Props> = ({
  onStartLoading,
  onLoadingError,
  onReceiveView,
  style,
  renderLoading = () => <LoadingContent />,
  renderError = (error: any, onReload: () => void) => (
    <ErrorContent error={error} onReload={onReload} />
  ),
  ...props
}) => {
  const nativeView = React.useRef(null);

  const [isLoading, setIsLoading] = React.useState(false);
  const [error, setError] = React.useState<LoadingViewError | null>(null);

  const commonStyles = StyleSheet.compose(
    [innerStyles.flex, innerStyles.background],
    style
  );

  const reload = React.useCallback(() => {
    const reactTag = findNodeHandle(nativeView.current);
    const command =
      UIManager.getViewManagerConfig('PaywallScreenView').Commands.reload;

    if (!command) {
      return;
    }

    UIManager.dispatchViewManagerCommand(reactTag, command, []);
  }, []);

  const _onStartLoading = React.useCallback<
    NonNullable<Props['onStartLoading']>
  >(
    (event) => {
      setIsLoading(true);
      setError(null);
      onStartLoading?.(event);
    },
    [onStartLoading]
  );

  const _onLoadingError = React.useCallback<
    NonNullable<Props['onLoadingError']>
  >(
    (event) => {
      setIsLoading(false);
      setError(event.nativeEvent.error);
      onLoadingError?.(event);
    },
    [onLoadingError]
  );

  const _onReceiveView = React.useCallback<NonNullable<Props['onReceiveView']>>(
    (event) => {
      setIsLoading(false);
      onReceiveView?.(event);
    },
    [onReceiveView]
  );

  return (
    <View style={commonStyles}>
      <NativePaywallScreenView
        ref={nativeView}
        style={innerStyles.flex}
        {...props}
        onStartLoading={_onStartLoading}
        onLoadingError={_onLoadingError}
        onReceiveView={_onReceiveView}
      />
      {(isLoading || error !== null) && (
        <View style={[innerStyles.overload, innerStyles.background]}>
          {isLoading && renderLoading()}
          {error !== null && renderError(error, reload)}
        </View>
      )}
    </View>
  );
};

const innerStyles = StyleSheet.create({
  background: {
    backgroundColor: 'white',
  },
  flex: {
    flex: 1,
  },
  overload: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
});
