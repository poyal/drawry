# Drawry Native v2 interoperability contract

Swift and Kotlin implementations are independent. This contract and `../fixtures/crypto-v2.json` are the interoperability boundary. All keys in fixtures are public test data.

## Data

UTF-8 JSON uses the field names in `Diary`, `Media`, `Weather`, `EditRecipe`, `Preferences`, `Snapshot`. Optional values may be absent or null. Required fields must be present. UUIDs are lowercase canonical strings. Epoch timestamps are integer **milliseconds**. `entryDate` is a Gregorian `yyyy-MM-dd` civil date; `entryTimeMinutes` and the recorded `utcOffsetMinutes` are separate and must not be recomputed when a device changes timezone.

Media array order is display order. Each media has its own random 256-bit key, standard padded Base64 encoding, original/thumbnail filenames and optional rendered filename. Filenames are relative ASCII basenames matching `[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}`, without `..`. No absolute paths are portable. Native database schemas are internal; backups never transport SQLite database files.

Limits: 10 media, 3 videos, 30,000 ms per video, 60,000 ms combined video duration and 314,572,800 imported bytes per diary. These limits are enforced before committing a diary, including on backup restore.

Edit recipe v1 contains clockwise quarter turns (0–3), a centered square crop after rotation, filter (`original`, `mono`, `warm`, `cool`), and text/emoji overlays. Overlays use normalized x/y coordinates with x at text center and y at its baseline; size is a fraction of rendered width. The current UI writes white text. Rendering uses OS fonts/emoji, so pixel identity after **re-editing** across OS versions is not guaranteed. The encrypted rendered JPEG is transported unchanged to preserve the saved appearance.

### Edit recipe v2: photo ink

New readers accept recipe versions 1 and 2. `strokes` defaults to `[]` when absent, including in Swift's custom decoder. Version 1 must have no strokes. The first committed ink stroke promotes a recipe to version 2; deleting strokes does not require a downgrade. Older native apps reject v2 via their existing recipe-version validation instead of silently dropping ink. No DB schema rewrite or DRBK2/DRY2 format change is required.

Each stroke is `{id,color,width,points:[{x,y}]}`. `id` is a unique canonical UUID; `color` is opaque `#RRGGBB`; `width` is a finite fraction of the orientation-normalized original image's shorter dimension (valid range 0.001–0.05; UI presets 0.003/0.006/0.012). Points are finite normalized original-image coordinates in [0,1]. Maximum 256 strokes and 20,000 total points per image, at least one point per stroke. Duplicate IDs and malformed/oversized ink are rejected before restore commit.

Coordinates are stored before quarter-turn rotation and center crop. The viewport inverts that transform when accepting input, so changing rotation/crop never rewrites or destroys hidden stroke points. Stroke widths follow the same image scale. Render order is transformed/filtered photo, then ink, then existing text/emoji overlays. Ink uses an opaque polyline with round caps and joins, with a filled round dot for one-point strokes; crop clips the drawing. Filters do not recolor ink. Erasing removes a whole intersected stroke and participates in recipe undo/redo. Pressure and video ink are unsupported.

The displayed saved JPEG/thumbnail and exported share image include ink. The original is unchanged. Cross-platform backup transports both the editable stroke metadata and the already rendered encrypted image; the latter preserves exact saved pixels across platforms. Tiny antialiasing/font differences may appear only after rerendering on another OS.

## DRY2 encrypted files

All integer fields are unsigned big-endian. AES-256-GCM uses a 16-byte tag. Keys and nonce prefixes come from OS CSPRNGs.

| Field | Bytes |
| --- | ---: |
| ASCII `DRY2` | 4 |
| Chunk size, exactly 4,194,304 | 4 |
| Total plaintext length | 8 |
| Random nonce prefix | 8 |

For chunk index `i` starting at zero:

- Nonce = 8-byte prefix + uint32(i).
- AAD = the complete 24-byte header + UTF-8 context + uint32(i).
- Record = ciphertext + 16-byte GCM tag. Plaintext size is `min(chunkSize, remainingLength)`.
- After the last nonempty chunk, append one authenticated **empty** record using the next index. Empty files have only this record.
- Require the exact declared length, the terminal tag and EOF. Reject truncation, changed order, incorrect context, changed header, invalid tags and trailing bytes.
- Media context is its encrypted basename. Backup payload context is lowercase hexadecimal SHA-256 of the exact header JSON bytes below.

Decrypt-to-file deletes partial plaintext on failure. Backup restore consumers stage encrypted media and do not publish them before final authentication.

## DRBK2 backups

Envelope: ASCII `DRBK2` (5 bytes), uint32 header length (1–65,536), exact UTF-8 header JSON bytes, then a DRY2 encrypted payload.

Header: `version:2`, `iterations:210000`, `salt`, `passwordWrap`, `recoveryWrap`. Base64 uses the standard alphabet and padding. Salt is 16 bytes. A random 32-byte backup data key is independently wrapped by:

- PBKDF2-HMAC-SHA256(password UTF-8 bytes, salt, 210,000, 32 bytes), AAD `drawry-password-v2`.
- A random 32-byte recovery key, AAD `drawry-recovery-v2`.

Each wrapped value is `nonce[12] || ciphertext[32] || tag[16]`, encoded as Base64. Passwords have at least eight Unicode scalars when creating a backup, are not trimmed or normalized, and use identical UTF-8 bytes on both OSes. A supplied nonempty password takes precedence over the recovery key. Unknown versions and iteration counts are rejected.

Decrypted payload: uint32 manifest length (1–32MiB), UTF-8 manifest JSON, then media file bytes in manifest order. Manifest has `snapshot` and `files:[{name,length,sha256}]`. `snapshot` includes version 2, creation time, all saved diaries including trash, and transferable preferences. Files are sorted by basename, exactly match referenced media files, and have unique names. SHA-256 values are lowercase hexadecimal. Each file is itself DRY2 encrypted. There is no ZIP archive or plaintext archive staging file.

Drafts, device keys, app-lock credentials, absolute paths and temporary files are not exported. `lockEnabled` and `graceSeconds` are not transferred; destination security preferences are retained. New devices configure locking independently.

## Applying a restore

1. Authenticate, parse and validate the entire backup in a fresh staging directory. Bound metadata lengths, validate names and checksums and authenticate every media file.
2. Show creation time and record counts before applying.
3. Merge keeps destination diaries with matching IDs and adds only new IDs. It preserves destination preferences. Replace uses backup diaries and transferable preferences. Both retain destination locking preferences, clear the active draft and purge expired trash.
4. Build a fresh media generation; copy referenced encrypted files. Conflicting filenames across different diaries are rejected, not overwritten.
5. Commit diary rows, preferences and generation pointer in one SQL transaction. Only then remove the former media generation. Startup removes unreferenced generations after an interrupted operation.

DRBK1/DRY1 Flutter compatibility is deliberately unsupported. No implicit destructive migration runs on upgrade.
