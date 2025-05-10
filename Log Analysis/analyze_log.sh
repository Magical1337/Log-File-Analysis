#!/bin/bash

LOG_FILE="sample_access.log" 

# 1. Request Counts
echo "=== Request Counts ==="
total_requests=$(wc -l < "$LOG_FILE")
get_requests=$(grep -c '"GET ' "$LOG_FILE")
post_requests=$(grep -c '"POST ' "$LOG_FILE")
echo "Total Requests: $total_requests"
echo "GET Requests: $get_requests"
echo "POST Requests: $post_requests"
echo ""

# 2. Unique IP Addresses
echo "=== Unique IP Addresses ==="
unique_ips=$(cut -d' ' -f1 "$LOG_FILE" | sort | uniq)
unique_ip_count=$(echo "$unique_ips" | wc -l)
echo "Unique IPs: $unique_ip_count"

echo "Requests by IP (GET/POST):"
while read -r ip; do
    get_count=$(grep "^$ip" "$LOG_FILE" | grep -c '"GET ')
    post_count=$(grep "^$ip" "$LOG_FILE" | grep -c '"POST ')
    echo "$ip: GET=$get_count, POST=$post_count"
done <<< "$unique_ips"
echo ""

# 3. Failure Requests
echo "=== Failure Requests (4xx & 5xx) ==="
failures=$(awk '$9 ~ /^4|^5/ {count++} END {print count+0}' "$LOG_FILE")
fail_percent=$(awk -v fail="$failures" -v total="$total_requests" 'BEGIN {printf "%.2f", (fail/total)*100}')
echo "Failed Requests: $failures"
echo "Failure Percentage: $fail_percent%"
echo ""

# 4. Top User (Most Active IP)
echo "=== Top User ==="
top_ip=$(cut -d' ' -f1 "$LOG_FILE" | sort | uniq -c | sort -nr | head -1)
echo "Most Active IP: $top_ip"
echo ""

# 5. Daily Request Averages
echo "=== Daily Averages ==="
days=$(awk -F'[:[]' '{print $2}' "$LOG_FILE" | cut -d: -f1 | sort | uniq -c)
total_days=$(echo "$days" | wc -l)
avg_per_day=$(awk -v total="$total_requests" -v days="$total_days" 'BEGIN {printf "%.2f", total/days}')
echo "Average Requests Per Day: $avg_per_day"
echo ""

# 6. Failure Analysis Per Day
echo "=== Failure Analysis (by Day) ==="
awk '$9 ~ /^4|^5/ {gsub(/\[|\]/,"",$4); split($4,a,":"); print a[1]}' "$LOG_FILE" | sort | uniq -c | sort -nr
echo ""

# Additional Insights

# Requests Per Hour
echo "=== Requests Per Hour ==="
awk -F'[:[]' '{print $2":"$3}' "$LOG_FILE" | sort | uniq -c
echo ""

# Hourly Request Trend Analysis
echo "Hourly Request Trends:"
previous_count=0
for hour in $(seq -f "%02g" 0 23); do
    current_count=${hourly_requests["$hour"]}
    
    if [ -z "$current_count" ]; then
        current_count=0
    fi
    
    if (( current_count > previous_count )); then
        echo "Hour $hour: Increasing trend ($current_count requests)"
    elif (( current_count < previous_count )); then
        echo "Hour $hour: Decreasing trend ($current_count requests)"
    else
        echo "Hour $hour: No change ($current_count requests)"
    fi
    
    previous_count=$current_count
done

# Status Code Breakdown
echo "=== Status Code Breakdown ==="
awk '{print $9}' "$LOG_FILE" | sort | grep -E '^[0-9]{3}$' | uniq -c | sort -nr
echo ""

# Most Active User by Method
echo "=== Most Active IP by Method ==="
echo "GET:"
grep '"GET ' "$LOG_FILE" | cut -d' ' -f1 | sort | uniq -c | sort -nr | head -1
echo "POST:"
grep '"POST ' "$LOG_FILE" | cut -d' ' -f1 | sort | uniq -c | sort -nr | head -1
echo ""

# Patterns in Failures (hourly)
echo "=== Failure Patterns by Hour ==="
awk '$9 ~ /^4|^5/ {split($4,a,":"); gsub(/\[|\]/,"",a[1]); print a[2]":00"}' "$LOG_FILE" | sort | uniq -c | sort -nr
