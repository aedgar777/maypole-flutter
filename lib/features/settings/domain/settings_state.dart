/// Represents the state of the settings feature
class SettingsState {
  final bool isLoading;
  final String? error;
  final bool uploadInProgress;
  final double? uploadProgress;

  const SettingsState({
    this.isLoading = false,
    this.error,
    this.uploadInProgress = false,
    this.uploadProgress,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    bool? uploadInProgress,
    double? uploadProgress,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      uploadInProgress: uploadInProgress ?? this.uploadInProgress,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}
