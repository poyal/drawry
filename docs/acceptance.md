# Native acceptance scenarios

## Automated

- Kotlin core: multi-chunk encryption/decryption, wrong AAD and truncation cleanup, password/recovery restore, wrong password cleanup, model constraints, independent PBKDF2/DRY2 vector, Swift-produced backup.
- Swift CoreCheck: same crypto boundary, independent vector and Kotlin-produced backup. XCTest suite runs under full Xcode.
- Ink core (both OSes): missing v1 strokes decode to empty; v2 metadata round-trips; all rotation/crop transforms invert; eraser hit testing; finite coordinates, colors and 256-stroke/20,000-point bounds. Cross-OS backup fixtures contain ink v2.
- Android instrumented: SQLCipher file is not plaintext SQLite; draft survives unrelated trash operations; restore merge keeps current records, replace applies backup; lock settings stay local; bad passwords leave existing data; expired trash purges media; native onboarding/editor/calendar launch.
- Android ink: rendered pixels for all 8 rotation/crop combinations, unchanged source bitmap, encrypted draft/save/backup restoration and 3 share ratios. On the dedicated `drawry-sketchbook-qa` AVD only: seed synthetic samples, capture screens, select thumbnails, enter full-screen viewer, draw/undo/redo/apply/save and reopen to assert the new stroke was persisted. Do not seed or run this flow against personal diaries.
- CI is configured to build Android debug and unsigned release and check iOS simulator build/UI tests. Confirm actual remote job results after pushing; local execution results are recorded separately in `VALIDATION_STATUS.md`.
- `ShowcaseSeedTest` is opt-in manual-demo setup, not a routine regression test. It preserves existing diaries/drafts/preferences and adds public sample photos only when explicitly requested. The current `drawry-sketchbook-qa` AVD now holds manual-test data: do not rerun the full instrumentation suite or reset it. See [handoff](../HANDOFF.md).

## Device acceptance before release

Use an iOS 17 device, current iPhone, API 26 Android and current Android; include a 4GB RAM device and a 16KB page-size device/emulator.

1. Save media-only entries and entries with every optional field. Reopen, modify, rearrange and remove media. Ensure rapid save taps do not duplicate records.
2. Change timezone and calendar month; civil diary dates stay fixed and feed/calendar counts agree.
3. Edit rotated photos with text/emoji/filter/crop; undo/redo; reopen; back up to the other OS and confirm the stored rendered image is retained.
   Draw dots and long strokes with every pen color/width. Erase whole strokes, undo/redo, rotate/crop repeatedly, then restore and re-edit on the other OS. Two-finger pan/zoom must not create a stroke. Original bytes must remain unchanged. Test point/stroke-limit alerts, large images and interrupted drafts.
4. JPEG, PNG, HEIC/HEIF, WebP, transparency, orientation, HDR, H.264/HEVC MOV/MP4, corrupt media and unsupported codecs: import/play where supported or show an actionable error without a crash.
5. Verify 10 media / 300MiB and video bounds, memory, thermal behavior and scrolling. Import/render/backup/restore must not exhaust memory. Cancel and low-disk paths must keep earlier data intact.
6. Interrupt during draft save, final save, backup authentication and generation switch; reopening recovers the last committed state and cleans abandoned files.
7. Deny photo/camera/microphone/authentication permissions. Android Photo Picker falls back to supported system document selection; denied capture permissions do not block library import.
8. With locking enabled, cold launch reveals no diary; background snapshots are obscured; grace intervals work; biometric/device-code failure does not unlock. Revisit while video, editor or share sheets are open.
9. Share each aspect/theme/field choice and inspect exported JPEG metadata for source GPS/EXIF. Cancelling the picker must not transmit content. Viewing caches clear on background; share files clear after completion or expiry/startup.
10. Export password/recovery backups on both OSes; test opposite-OS merge/replace, corruption, unsupported version and insufficient disk. Confirm existing state is unchanged until commit.
11. Restore a deleted record before 30 days; purge manually and after expiry. Full erase requires confirmation and device authentication; external backups are explicitly outside its scope.

UI defaults: Korean; system light/dark mode; iOS tabs/navigation/forms and Android navigation bar/FAB/sheets. Check VoiceOver/TalkBack, large text, rotation, keyboard and tablets. Advanced tablet layouts and cross-platform pixel-identical fonts are not part of v2.

Sketchbook acceptance: card/2/3-column selection remains in settings and survives relaunch; feed is photo-first; compose remains compact with 1–10 media; calendar thumbnails and counts match records. Check portrait/landscape/square photos, long Korean/emoji text, empty/deleted media and keyboard obstruction. Local Android QA covers light/dark and 150% font-scale smoke flows, not a complete accessibility certification or iOS runtime validation.

## Visual completion gates

- Approve one final app-icon direction and verify installed launcher assets on both platforms. The five concepts are not production icons yet.
- Test OS launch screen and first-run introduction separately; returning users must reach home/lock without repeated onboarding.
- Audit primary/secondary/destructive/icon buttons, enabled/disabled/loading states, labels, touch targets and screen-reader names across every screen.
- Audit icon weight/style/size/selected states and distinguish decorative marks from interactive controls.
- Compare spacing, typography, surfaces, navigation bars, safe areas and empty/loading/error states on feed, editor, tools, calendar, settings and share.
- Run the same checks with realistic multi-photo, multi-date samples; retain existing manual-test diaries. Detailed open tasks and acceptance criteria: [TODO.md](../TODO.md).
