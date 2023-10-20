#!/bin/bash

# Variables
LOG_FILE="/home/ubuntu/script/all.log"
CLEAR_LOG="/home/ubuntu/script/clear.log"
nginx_log_file="/var/log/nginx/access.log"
output500="/home/ubuntu/script/500.log"
output400="/home/ubuntu/script/400.log"
cpu_output_file="/var/www/html/stat/cpu.html"

touch "$output500"
touch "$output400"
touch "$cpu_output_file"
touch "$CLEAR_LOG"

#-----------get number of last line of nginx logs--------------------
last_access_line=$(wc -l < /var/log/nginx/access.log)
last_error_line=$(wc -l < /var/log/nginx/error.log)

while true; do
    # Get new lines from access.log and error.log
    new_access_lines=$(awk -v last_line="$last_access_line" 'NR > last_line' /var/log/nginx/access.log)
    new_error_lines=$(awk -v last_line="$last_error_line" 'NR > last_line' /var/log/nginx/error.log)

    # Update the last processed line numbers
    last_access_line=$(wc -l < /var/log/nginx/access.log)
    last_error_line=$(wc -l < /var/log/nginx/error.log)

    # Write new lines to LOG_FILE
    { echo "$new_access_lines"; echo "$new_error_lines"; } | awk '!seen[$0]++' >> "$LOG_FILE"

    #---------------------Clear LOG_FILE---------------------
    size=$(stat -c %s "$LOG_FILE")
    if [ "$size" -gt 300000 ]; then
        > "$LOG_FILE"
        echo "Log file successfully cleared at $(date)" >> "$CLEAR_LOG"
    fi

    #---------------Get 500 codes-----------------------------
    echo "$new_access_lines" | awk '!seen[$0]++ && $9 >= 500 && $9 <= 599' >> "$output500"

    #-------------Get 400 codes-------------------------------
    echo "$new_access_lines" | awk '!seen[$0]++ && $9 >= 400 && $9 <= 499' >> "$output400"

    #--------------CPU usage----------------------------------
    echo "" > "$cpu_output_file"
    cpu_metrics=$(top -bn1 | awk '/%Cpu/ {print "User: "$2"%, System: "$4"%, Idle: "$8"%, Load Avg: "$12" "$13" "$14}')
    echo "<p>CPU Metrics: $cpu_metrics</p>" >> "$cpu_output_file"

    sleep 5
done
