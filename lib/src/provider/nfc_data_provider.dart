import 'package:flutter/material.dart';
import 'package:klondike/src/provider/nfc_data_notifier.dart';


class NfcDataProvider extends InheritedWidget {
  const NfcDataProvider({
    super.key,
    required this.nfcDataNotifier,
    required super.child,
  });

  final NfcDataNotifier nfcDataNotifier;
  static NfcDataNotifier of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<NfcDataProvider>();
    if (provider == null) {
      throw Exception('No NfcProvider found in context');
    }
    return provider.nfcDataNotifier;
  }

  @override
  bool updateShouldNotify(NfcDataProvider oldWidget) {
    return nfcDataNotifier != oldWidget.nfcDataNotifier;
  }
}
