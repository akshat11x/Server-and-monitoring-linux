# Linux Server Monitoring System

A Bash-based Linux server monitoring tool that checks system health, applies configurable thresholds, generates logs and health reports, and sends email alerts when the server health status changes.

## Features

- CPU usage monitoring
- Memory usage monitoring
- Disk usage monitoring
- Network connectivity monitoring
- Logged-in user detection
- Server hostname and IP detection
- Configurable warning and critical thresholds
- Health status classification:
  - OK
  - WARNING
  - CRITICAL
- Status-change alert detection
- Recovery notifications
- Email notifications
- Log rotation
- Persistent monitoring state
- Health report generation
- Exit codes suitable for automation
- Docker support

## Project Structure

```text
server-monitor/
├── monitor.sh
├── config.conf
├── Dockerfile
├── logs/
├── reports/
├── .gitignore
└── README.md
