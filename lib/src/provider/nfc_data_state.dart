import 'dart:typed_data';
import 'package:nfc_between_worlds/src/models/nfc_data.dart';

class NfcDataState {
  final bool shouldResetWorldValues;
  final bool isProcessing;
  final bool shouldUpdate;
  final bool shouldTeleportToSlimeHub;
  final bool shouldReturnToMenu;
  final String? gameCheat;
  final List<String> items;
  final String nfcType;
  final NfcData latestNfcData;
  final Uint8List nfcUtf8Type;

  NfcDataState({
    required this.shouldResetWorldValues,
    required this.shouldReturnToMenu,
    required this.shouldUpdate,
    required this.items,
    required this.shouldTeleportToSlimeHub,
    required this.latestNfcData,
    this.gameCheat,
    this.nfcType = '',
    this.isProcessing = false,
    required this.nfcUtf8Type,
  });

  NfcDataState copyWith({
    final bool? shouldResetWorldValues,
    final bool? isProcessing,
    final bool? shouldUpdate,
    final bool? shouldTeleportToSlimeHub,
    final bool? shouldReturnToMenu,
    final String? gameCheat,
    final List<String>? items,
    final String? nfcType,
    final NfcData? latestNfcData,
    final Uint8List? nfcUtf8Type,
  }) {
    return NfcDataState(
      latestNfcData: latestNfcData ?? this.latestNfcData,
      shouldResetWorldValues: shouldResetWorldValues ?? false,
      shouldReturnToMenu: shouldReturnToMenu ?? false,
      shouldUpdate: shouldUpdate ?? false,
      items: items ?? [],
      shouldTeleportToSlimeHub: shouldTeleportToSlimeHub ?? false,
      gameCheat: gameCheat,
      nfcType: nfcType ?? this.nfcType,
      nfcUtf8Type: nfcUtf8Type ?? this.nfcUtf8Type,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
