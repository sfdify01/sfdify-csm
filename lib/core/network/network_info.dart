abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // For web, we can use a simple fetch to check connectivity
    // In a real app, you might want to use connectivity_plus package
    return true;
  }
}
