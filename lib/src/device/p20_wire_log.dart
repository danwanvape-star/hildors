/// Bounded application socket trace, not a PCAP/TCP packet capture.
class P20WireLog {
  final _lines = <String>[];
  int _characters = 0;
  void record(String direction, List<int> bytes, {bool media = false}) {
    final shown = (media ? const <int>[] : bytes.take(4096))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    final detail = media ? '[media omitted]' : shown;
    final line = [
      DateTime.now().toUtc().toIso8601String(),
      direction,
      'bytes=',
      bytes.length,
      detail,
      if (!media && bytes.length > 4096) '[truncated]'
    ].join(' ');
    _lines.add(line);
    _characters += line.length;
    while (_characters > 64000 && _lines.length > 1) {
      _characters -= _lines.removeAt(0).length;
    }
  }

  String get text => [
        'P20 application socket trace (not PCAP). RX logged before decoding; chunks are not TCP packet boundaries. TX is local enqueue, not device receipt. Media omitted. Bounded recent log.\n',
        _lines.join('\n')
      ].join();
}
