#!/usr/bin/env bash

# Check for root administrative access
if [ "$EUID" -ne 0 ]; then
  echo "Error: Run this script with sudo."
  exit 1
fi

LOG_FILE="lattice_telemetry_$(date +%Y%m%d_%H%M%S).csv"
echo "Timestamp,Core,Latency_Nanoseconds" > "$LOG_FILE"

echo "Initializing micro-jitter telemetry logging..."
echo "Recording hardware metrics to $LOG_FILE. Press [CTRL+C] to stop."

# Loop sampling loop over the designated isolated cores (Cores 2-15)
while true; do
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  for core in {2..15}; do
    # Sample hardware scheduler wake delay via internal timers
    LATENCY=$(taskset -c "$core" perl -MTime::HiRes=time -e '
      $start = time;
      select(undef, undef, undef, 0.001);
      $delay = (time - $start - 0.001) * 1000000000;
      print int($delay);
    ')
    
    # Write structural metrics to local database ledger
    echo "$TIMESTAMP,$core,$LATENCY" >> "$LOG_FILE"
  done
  sleep 1
done
