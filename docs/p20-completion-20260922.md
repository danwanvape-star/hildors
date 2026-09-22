# P20 completion compatibility — 0.1.64+65

Manufacturer confirmed that SEQ is meaningful only for status 01, not for status 02. The parser now accepts completion data of length 5 (02 plus four ignored bytes), while retaining existing length-1 compatibility. Frame decoder still checks CRC, boundaries and framing. Completion before the entire source has been sent remains an error. Other payload lengths are rejected. Stop-and-wait and exclusive upload remain unchanged.

Bounded diagnostics for upload response mismatch show command, payload length, first five response bytes and expected sequence. These contain no filenames or media data. Existing localized error text remains displayed. The manufacturer's literal first ACK decodes to command 31/data 01 00000001. This does not establish what the user's device actually returned during its failure.

Validation: 15 transport tests passed, including manufacturer literal frame, extended completion with arbitrary nonzero SEQ bytes, short completion compatibility, block boundaries, command isolation, cancellation and timeout. Hardware upload remains unverified. No backend changes. Roll back using a targeted revert and higher Android build number; no data migration. Branch codex/unified-us-p20-20260921.
