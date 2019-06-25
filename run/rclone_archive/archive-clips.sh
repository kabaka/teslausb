#!/bin/bash -eu

log "Moving clips to rclone archive..."

source /root/.teslaCamRcloneConfig

NUM_FILES_MOVED=0

function keep_car_awake() {
  # If the tesla_api.py script is installed, send the car a wake_up command.
  if [ -f /root/bin/tesla_api.py ]
  then
    /root/bin/tesla_api.py wake_up_vehicle >> "$LOG_FILE"
  fi
}

for file_name in "$CAM_MOUNT"/TeslaCam/saved* "$CAM_MOUNT"/TeslaCam/SavedClips/*; do
  [ -e "$file_name" ] || continue
  DIR_NAME="$(basename $file_name)"
  log "Creating destination directory $file_name"
  rclone --config /root/.config/rclone/rclone.conf mkdir "$drive:$path/$DIR_NAME/" >> "$LOG_FILE" 2>&1 || echo ""
  log "Moving contents of $file_name"
  rclone --config /root/.config/rclone/rclone.conf move "$file_name" "$drive:$path/$DIR_NAME/" >> "$LOG_FILE" 2>&1 || echo ""
  log "Moved $file_name"
  NUM_FILES_MOVED=$((NUM_FILES_MOVED + 1))

  # XXX
  keep_car_awake || true
done

log "Moved files for $NUM_FILES_MOVED directories."

rmdir --ignore-fail-on-non-empty "$CAM_MOUNT/TeslaCam/SavedClips"/* || true

log "Erased remaining SavedClips contents."

/root/bin/send-push-message "$NUM_FILES_MOVED"

log "Finished moving clips to rclone archive"
