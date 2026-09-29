# Connection diagnostics, build 0.1.68+69

The CS_P20_999999 single-list device remains unverified on physical hardware. Its manufacturer app connects, but Hildors fails after selecting single-list mode. Phone Wi-Fi address 192.168.4.2 does not establish device port or firmware framing.

This change adds bounded in-memory connection stages (TCP start/connected/failure, probe failure, verified), mode and destination, numeric socket error code, and raw TX/RX during the read-only brightness probe. Raw RX precedes parsing, so malformed frames remain visible. No general settings commands are traced. Probe tracing stops in finally on success or failure; existing upload trace still omits media. No automatic disk persistence or log transmission.

On the phone: install build 69, connect device Wi-Fi, exit manufacturer app, select single-list mode, reproduce once, then My > App settings > Copy device communication log. Paste the text for diagnosis. Upload is unnecessary. This is application socket tracing, not PCAP.

No changes to frame checksums, port, brightness acceptance, upload gating, file format or stop-and-wait behavior. Single-list upload remains disabled pending its separate protocol verification.

Validation: 52 focused tests passed (device detection, wire log, single transport, dual transport, capability UI). The new trace assertions first failed on absent probe logs before implementation. Final dart analyze lib test: no issues. git diff --check: passed. Physical hardware and iOS validation remain outstanding. Revert this diagnostic change to remove trace events/UI; no backend or data migration required.
