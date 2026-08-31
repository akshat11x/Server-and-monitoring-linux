#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LOG_DIR="$SCRIPT_DIR/logs"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
MONITOR_LOG="$LOG_DIR/monitor.log"
ERROR_LOG="$LOG_DIR/error.log"

ALERT_LOG="$LOG_DIR/alert.log"
STATE_FILE="$LOG_DIR/status.state"

rotate_logs() {
    local file_size
    local file_name="$1"

    if [ ! -f "$file_name" ]; then
        return
    fi

    file_size=$(du -b "$file_name" | awk '{print $1}')
    

    if [ "$file_size" -gt 1048576 ]; then
        mv "$file_name" "$file_name.1"
        touch "$file_name"
    fi
}

mkdir -p "$LOG_DIR"
rotate_logs "$MONITOR_LOG"
rotate_logs "$ALERT_LOG"
rotate_logs "$ERROR_LOG"

log_info(){
	local message="$1"
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $message" >> "$MONITOR_LOG"
}

log_error(){
	local message="$1"
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" | tee -a "$ERROR_LOG" >&2
}

log_warning(){
	local message="$1"
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $message" >> "$MONITOR_LOG"
}

send_email(){
	local subject="$1"
	local body="$2"

	if ! command -v mail > /dev/null 2>&1; then
        	log_error "mail command not found. Cannot send email."
        	return 1
	fi

	echo "$body" | mail -s "$subject" "$EMAIL_TO"

	 if [ $? -eq 0 ]; then
        	log_info "Email sent: $subject"
    	 else
        	log_error "Failed to send email: $subject"
         	return 1
    fi

}


log_info "Monitoring started"

#============================
#check the files
#============================

if [ ! -f "$CONFIG_FILE" ]; then
	log_error "Config file $CONFIG_FILE not found"
	exit 1
fi
source "$CONFIG_FILE"

if [ -f "$STATE_FILE" ]; then
	PREVIOUS_STATUS=$(cat "$STATE_FILE")
else
	PREVIOUS_STATUS="UNKNOWN"
fi
#=============================
#Check command
#=============================

check_command(){
	local command="$1"
	if ! command -v "$1" > /dev/null 2>&1; then
		log_error "Command $command not found"
		exit 1
	fi
}

#==============================
#Threshold function
#==============================
check_status() {
    local usage="$1"
    local warning_threshold="$2"
    local critical_threshold="$3"

    if awk "BEGIN {exit !($usage >= $critical_threshold)}"; then
        echo "CRITICAL"
    elif awk "BEGIN {exit !($usage >= $warning_threshold)}"; then
	echo "WARNING"
    else
    	echo "OK"
    fi
}

log_health_status() {
    local name="$1"
    local usage="$2"
    local status="$3"

    if [ "$status" = "CRITICAL" ]; then
        log_error "$name usage: $usage% - $status"
    elif [ "$status" = "WARNING" ]; then
        log_warning "$name usage: $usage% - $status"
    else
        log_info "$name usage: $usage% - $status"
    fi
}

generate_alert() {
    local timestamp
    local subject
    local body

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    subject="[$OVERALL_STATUS] Server Health Alert - $HOSTNAME"

    body="
Server Health Alert
===================

Time     : $timestamp
Hostname : $HOSTNAME
IP       : $IP_ADDRESS

Status changed:
$PREVIOUS_STATUS -> $OVERALL_STATUS

CPU      : $CPU_USAGE% - $CPU_STATUS
Memory   : $MEMORY_USAGE% - $MEMORY_STATUS
Disk     : $DISK_USAGE_NUMBER% - $DISK_STATUS
Network  : $NETWORK_STATUS

Overall Status : $OVERALL_STATUS

Please check the server.
"

    # Save alert to alert.log
    {
        echo "========================================"
        echo "[$timestamp] ALERT: Status changed from $PREVIOUS_STATUS to $OVERALL_STATUS"
        echo
        echo "CPU     : $CPU_USAGE% - $CPU_STATUS"
        echo "Memory  : $MEMORY_USAGE% - $MEMORY_STATUS"
        echo "Disk    : $DISK_USAGE_NUMBER% - $DISK_STATUS"
        echo "Network : $NETWORK_STATUS"
        echo "Overall : $OVERALL_STATUS"
        echo "========================================"
    } >> "$ALERT_LOG"

    # Send email
    send_email "$subject" "$body"
}

generate_recovery_alert() {
    local timestamp
    local subject
    local body

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    subject="[RECOVERY] Server Health Recovered - $HOSTNAME"

    body="
Server Health Recovery
======================

Time     : $timestamp
Hostname : $HOSTNAME
IP       : $IP_ADDRESS

Status changed:
$PREVIOUS_STATUS -> $OVERALL_STATUS

CPU      : $CPU_USAGE% - $CPU_STATUS
Memory   : $MEMORY_USAGE% - $MEMORY_STATUS
Disk     : $DISK_USAGE_NUMBER% - $DISK_STATUS
Network  : $NETWORK_STATUS

Overall Status : $OVERALL_STATUS

The server has recovered to a healthy state.
"

    {
        echo "========================================"
        echo "[$timestamp] RECOVERY: Status changed from $PREVIOUS_STATUS to $OVERALL_STATUS"
        echo
        echo "CPU     : $CPU_USAGE% - $CPU_STATUS"
        echo "Memory  : $MEMORY_USAGE% - $MEMORY_STATUS"
        echo "Disk    : $DISK_USAGE_NUMBER% - $DISK_STATUS"
        echo "Network : $NETWORK_STATUS"
        echo "Overall : $OVERALL_STATUS"
        echo "========================================"
    } >> "$ALERT_LOG"

    send_email "$subject" "$body"
}
        

# ==============================
# Server Information
# ==============================

check_command "hostname"
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

check_command "uptime"
UPTIME=$(uptime -p)

check_command "date"
TIMESTAMP=$(date)

# ==============================
# Disk Usage
# ==============================
check_command "df"
DISK_USAGE=$(df -h | awk '$6 == "/" {print $5}')
DISK_USAGE_NUMBER=${DISK_USAGE%\%}
if [ -z "$DISK_USAGE" ]; then
	log_error "Unable to determine disk usage"
    exit 1
fi

# ==============================
# Memory Usage
# ==============================

check_command "free"
TOTAL_MEMORY=$(free | grep "Mem:" | awk '{print $2}')
USED_MEMORY=$(free | grep "Mem:" | awk '{print $3}')

if [ -z "$TOTAL_MEMORY" ] || [ -z "$USED_MEMORY" ]; then
	log_error "Unable to determine memory usage"
    exit 1
fi

MEMORY_USAGE=$((USED_MEMORY * 100 / TOTAL_MEMORY))

# ==============================
# Users
# ==============================
check_command "who"
USERS=$(who | wc -l)

# ==============================
# CPU Usage and info
# ==============================

check_command "top"
CPU_USAGE=$(top -bn1 | grep '%Cpu' | awk '{print 100-$8}')
if [ -z "$CPU_USAGE" ]; then
	log_error "Unable to determine cpu usage"
    exit 1
fi

# ==============================
# Network Status
# ==============================
check_command "ping"
if ping -c4 8.8.8.8 > /dev/null 2>&1; then
        NETWORK_STATUS="UP"
else
	log_error "Network status down"
        NETWORK_STATUS="DOWN"
fi

CPU_STATUS=$(check_status "$CPU_USAGE" "$WARNING_THRESHOLD" "$CRITICAL_THRESHOLD")
MEMORY_STATUS=$(check_status "$MEMORY_USAGE" "$WARNING_THRESHOLD" "$CRITICAL_THRESHOLD")
DISK_STATUS=$(check_status "$DISK_USAGE_NUMBER" "$WARNING_THRESHOLD" "$CRITICAL_THRESHOLD")

if [ "$CPU_STATUS" = "CRITICAL" ] || \
   [ "$MEMORY_STATUS" = "CRITICAL" ] || \
   [ "$DISK_STATUS" = "CRITICAL" ] || \
   [ "$NETWORK_STATUS" = "DOWN" ]; then

    OVERALL_STATUS="CRITICAL"

elif [ "$CPU_STATUS" = "WARNING" ] || \
     [ "$MEMORY_STATUS" = "WARNING" ] || \
     [ "$DISK_STATUS" = "WARNING" ]; then

    OVERALL_STATUS="WARNING"

else
    OVERALL_STATUS="OK"
fi

# ==============================
# Alert Detection
# ==============================

if [ "$OVERALL_STATUS" = "WARNING" ] || \
   [ "$OVERALL_STATUS" = "CRITICAL" ]; then

    if [ "$OVERALL_STATUS" != "$PREVIOUS_STATUS" ]; then
        generate_alert
    fi
elif [ "$OVERALL_STATUS" = "OK" ] && \
     [ "$PREVIOUS_STATUS" != "OK" ] && \
     [ "$PREVIOUS_STATUS" != "UNKNOWN" ]; then

    generate_recovery_alert

fi

echo "$OVERALL_STATUS" > "$STATE_FILE"

# ==============================
# Log Health Results
# ==============================

log_health_status "CPU" "$CPU_USAGE" "$CPU_STATUS"
log_health_status "Memory" "$MEMORY_USAGE" "$MEMORY_STATUS"
log_health_status "Disk" "$DISK_USAGE_NUMBER" "$DISK_STATUS"
log_info "Network status: $NETWORK_STATUS"
log_info "Overall status: $OVERALL_STATUS"

# ==============================
# Health Report
# ==============================
check_command "tee"
{
echo "========================================"
echo "       LINUX SERVER HEALTH REPORT"
echo "========================================"

echo "Report generated at: $TIMESTAMP"
echo
echo "Hostname        : $HOSTNAME"
echo "IP Address      : $IP_ADDRESS"
echo "Uptime          : $UPTIME"
echo
echo "CPU Usage       : $CPU_USAGE %"
echo "CPU status      : $CPU_STATUS"
echo
echo "Memory Usage    : $MEMORY_USAGE %"
echo "Memory Status   : $MEMORY_STATUS"
echo
echo "Disk Usage      : $DISK_USAGE"
echo "Disk Status     : $DISK_STATUS"
echo
echo "======================================="
echo "Overall status  : $OVERALL_STATUS" 
echo "======================================="
echo
echo "Logged-in Users : $USERS"
echo "Network Status  : $NETWORK_STATUS"

echo "========================================"
} | tee -a "$MONITOR_LOG"


if [ "$OVERALL_STATUS" = "CRITICAL" ]; then
    exit 2
elif [ "$OVERALL_STATUS" = "WARNING" ]; then
    exit 1
else
    exit 0
fi


