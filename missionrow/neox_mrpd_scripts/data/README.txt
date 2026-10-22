This folder holds the server's own persisted state. The files appear the
first time something is written and are plain JSON, so they can be read,
edited or deleted while the server is stopped.

  killhouse_scores.json    kill house leaderboard
  range_scores.json        shooting range leaderboard
  range_stats.json         per-officer AimLab totals, keyed by identifier
  projector_boards.json    the current board for each briefing projector
  projector_presets.json   saved projector presets, per projector
  cctv_cameras.json        cameras added in game with /cctv_setup
  cctv_bookmarks.json      each officer's bookmarked cameras
  cctv_alerts.json         the shared incident log (newest first, capped at 50)

Deleting a file resets that feature; nothing else depends on it.
Writes are batched about once a second and flushed when the resource stops.
