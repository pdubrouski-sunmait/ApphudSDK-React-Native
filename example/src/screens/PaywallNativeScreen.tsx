import React from 'react';
import {
  type RouteProp,
  useRoute,
  useNavigation,
} from '@react-navigation/native';
import { PaywallScreenView } from '@apphud/react-native-apphud-sdk';

const REQUEST_PLACEMENTS_OPTIONS = { maxAttempts: 4, forceRefresh: true };

const PaywallNativeScreen = () => {
  const route = useRoute<RouteProp<Record<string, Record<string, any>>>>();
  const navigation = useNavigation();

  return (
    <PaywallScreenView
      placementIdentifier={route.params.placementIdentifier}
      onTransactionCompleted={({ nativeEvent: { result } }) => {
        console.log(
          'RN: onTransactionCompleted transaction completed',
          JSON.stringify(result)
        );
        navigation.goBack();
      }}
      onCloseButtonTapped={() => {
        console.log('RN: onCloseButtonTapped close button tapped');
        navigation.goBack();
      }}
      requestPlacementsOptions={REQUEST_PLACEMENTS_OPTIONS}
    />
  );
};

export default PaywallNativeScreen;
