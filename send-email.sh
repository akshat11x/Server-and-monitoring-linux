#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CONFIG_FILE="$SCRIPT_DIR/config.conf"
EMAIL_TEMPLATE="$SCRIPT_DIR/email-template.html"

# =============================
# Load configuration
# =============================

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.conf not found."
    exit 1
fi

source "$CONFIG_FILE"


# =============================
# Arguments
# =============================

SUBJECT="$1"


# =============================
# Validate required commands
# =============================

if ! command -v mail > /dev/null 2>&1; then
    echo "Error: mail command not found."
    exit 1
fi

if ! command -v envsubst > /dev/null 2>&1; then
    echo "Error: envsubst command not found."
    echo "Install it using: sudo apt install gettext-base"
    exit 1
fi


# =============================
# Validate template
# =============================

if [ ! -f "$EMAIL_TEMPLATE" ]; then
    echo "Error: email-template.html not found."
    exit 1
fi


# =============================
# Determine colors
# =============================

case "$OVERALL_STATUS" in
    CRITICAL)
        HEADER_COLOR="#dc3545"
        STATUS_ICON="🔴"
	ALERT_TITLE="Alert"
        STATUS_BACKGROUND="#fef2f2"
        ;;
    WARNING)
        HEADER_COLOR="#ffc107"
        STATUS_ICON="🟡"
	 ALERT_TITLE="Warning"
        STATUS_BACKGROUND="#fffbeb"
        ;;
    OK)
        HEADER_COLOR="#28a745"
        STATUS_ICON="🟢"
	ALERT_TITLE="Recovered"
        STATUS_BACKGROUND="#f0fdf4"
        ;;
    *)
        HEADER_COLOR="#6c757d"
        STATUS_ICON="⚪"
	ALERT_TITLE="Status"
        STATUS_BACKGROUND="#f3f4f6"
        ;;
esac


case "$CPU_STATUS" in
    CRITICAL) CPU_COLOR="#dc3545" ;;
    WARNING)  CPU_COLOR="#ffc107" ;;
    *)         CPU_COLOR="#28a745" ;;
esac

case "$MEMORY_STATUS" in
    CRITICAL) MEMORY_COLOR="#dc3545" ;;
    WARNING)  MEMORY_COLOR="#ffc107" ;;
    *)         MEMORY_COLOR="#28a745" ;;
esac

case "$DISK_STATUS" in
    CRITICAL) DISK_COLOR="#dc3545" ;;
    WARNING)  DISK_COLOR="#ffc107" ;;
    *)         DISK_COLOR="#28a745" ;;
esac

if [ "$NETWORK_STATUS" = "DOWN" ]; then
    NETWORK_COLOR="#dc3545"
else
    NETWORK_COLOR="#28a745"
fi


# =============================
# Export variables for template
# =============================

export HOSTNAME
export IP_ADDRESS
export TIMESTAMP
export PREVIOUS_STATUS
export OVERALL_STATUS

export CPU_USAGE
export CPU_STATUS
export CPU_COLOR

export MEMORY_USAGE
export MEMORY_STATUS
export MEMORY_COLOR

export DISK_USAGE
export DISK_USAGE_NUMBER
export DISK_STATUS
export DISK_COLOR

export NETWORK_STATUS
export NETWORK_COLOR

export HEADER_COLOR
export STATUS_ICON

export ALERT_TITLE
export STATUS_BACKGROUND


# =============================
# Generate HTML email
# =============================

HTML_EMAIL=$(mktemp /tmp/server-health-email.XXXXXX.html)

if [ $? -ne 0 ]; then
    echo "Error: Could not create temporary HTML file."
    exit 1
fi

trap 'rm -f "$HTML_EMAIL"' EXIT

envsubst < "$EMAIL_TEMPLATE" > "$HTML_EMAIL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate HTML email."
    exit 1
fi


# =============================
# Send email
# =============================

mail \
    -a "Content-Type: text/html; charset=UTF-8" \
    -s "$SUBJECT" \
    "$EMAIL_TO" < "$HTML_EMAIL"

if [ $? -eq 0 ]; then
    echo "Email sent successfully: $SUBJECT"
    exit 0
else
    echo "Failed to send email: $SUBJECT"
    exit 1
fi
