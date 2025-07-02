#!/bin/bash

# Configuration
THRESHOLD=10
ALERT_EMAIL="pratik.sutar@yash.com"
CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/ec2/logs/disk_monitor.log"  # Log file location

# Function to write to log file
write_log() {
    echo "[$CURRENT_DATE] $1" >> "$LOG_FILE"
}

# Function to purge previous records
purge_log(){
    if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 200 ]; then
        tail -n 2000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
        write_log "Log file rotated - kept last 200 lines"
    fi
}

# Purging previous records
purge_log

write_log "========== DISK MONITORING STARTED =========="
df -hP | awk 'NR>1 && $1 !~ /(tmpfs|devtmpfs)/' | while read -r line; do
    usage=$(echo $line | awk '{print $5}' | sed 's/%//')
    mountpoint=$(echo $line | awk '{print $6}')
    if [ "$usage" -ge "$THRESHOLD" ]; then
	write_log "[ALERT] Disk usage at $mountpoint is ${usage}% alert sent to $ALERT_EMAIL"
	echo "[ALERT] Disk usage at $mountpoint is ${usage}% at $CURRENT_DATE" | mail -s "Disk Usage Alert" $ALERT_EMAIL
    else
         write_log "[SAFE] Mount point $mountpoint is below the threshold of $THRESHOLD%"
    fi
done
write_log "========== DATABASE MONITORING COMPLETED =========="
write_log "---------------------------------------------------"
write_log "---------------------------------------------------"

