class ReconnectBackoff {
  ReconnectBackoff({
    this.delays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 15),
      Duration(seconds: 30),
    ],
  }) : assert(delays.isNotEmpty);

  final List<Duration> delays;
  int _attempt = 0;

  int get attempt => _attempt;

  Duration next() {
    final index = _attempt.clamp(0, delays.length - 1).toInt();
    _attempt++;
    return delays[index];
  }

  void reset() => _attempt = 0;
}
