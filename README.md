# 🖥️ Linux Server Monitoring & Alerting System

A lightweight Linux server monitoring and alerting system built using **Bash, Docker, Prometheus, Node Exporter, Grafana, SMTP, and Cron**.

The project monitors important server health metrics such as **CPU, memory, disk usage, network connectivity, and logged-in users**. It provides both a terminal-based health report and a real-time Grafana dashboard.

The system also includes an automated **email alert and recovery notification mechanism** using SMTP.

---

## 🚀 Features

- 📊 CPU usage monitoring
- 🧠 Memory usage monitoring
- 💾 Disk usage monitoring
- 🌐 Network connectivity monitoring
- 👤 Logged-in user monitoring
- 🚨 WARNING and CRITICAL thresholds
- 📧 HTML email alerts using SMTP
- 🔄 Automatic recovery notifications
- 📝 Structured monitoring and error logs
- 🔁 Log rotation
- ⏰ Automated execution using Cron
- 📈 Prometheus metrics collection
- 📊 Grafana dashboard
- 🐳 Docker Compose based monitoring stack
- 🔧 Configurable thresholds
- 🛡️ No hard-coded SMTP credentials
- ⚡ Lightweight Bash-based monitoring

---
## 🏗️ Architecture

```text
                         Linux / WSL Host
                              │
                              │
                     ┌────────▼────────┐
                     │   monitor.sh    │
                     │  Bash Monitor   │
                     └────────┬────────┘
                              │
             ┌────────────────┼────────────────┐
             │                │                │
             ▼                ▼                ▼
           Logs          SMTP / Email       Terminal
             │                │                │
             │                ▼                │
             │        HTML Email Alert        │
             │                │                │
             │                ▼                │
             │             User Inbox         │
             │
             │
       Docker Monitoring Stack
             │
     ┌───────┼──────────┐
     │       │          │
     ▼       ▼          ▼
 Node     Prometheus   Grafana
Exporter      │          │
     │        │          │
     └────────►──────────►
              Metrics

```
---
## 🛠️ Technology Stack



## Project Structure
```text
server-monitor/
│
├── README.md
├── config.conf
├── docker-compose.yml
├── email-template.html
├── monitor.sh
├── send-email.sh
│
├── grafana/
│   ├── dashboards/
│   │   └── server-monitor.json
│   │
│   └── provisioning/
│       └── dashboards/
│           └── dashboards.yml
│
├── prometheus/
│   └── prometheus.yml
│
└── logs/
    └── .gitkeep
 ```
 ---
## ⚙️ Prerequisites

Make sure the following are installed:

-   Linux / WSL
-   Bash
-   Docker
-   Docker Compose
-   `mail`
-   `envsubst`
-   Cron

#### For Ubuntu/Debian:
```
sudo apt update
sudo apt install mailutils gettext-base
```
#### Check Installations
```
docker --version
docker compose version
mail --version
envsubst --version
```
---
## 📥 Installation

Clone the repository
```
git clone https://github.com/akshat11x/Server-and-monitoring-linux
```
Enter the project
```
cd server-monitor
```
Make scripts executable
```
chmod +x monitor.sh
chmod +x send-email.sh
```
---
## ⚙️ Configuration
The monitoring thresholds and email recipient are configured in:
```
config.conf
```
Eg.
```
WARNING_THRESHOLD=80
CRITICAL_THRESHOLD=90
EMAIL_TO="your-email@example.com"
```
---
## 📧 SMTP Configuration
The monitoring system uses the Linux `mail` command to send HTML emails.

The project does **not** store SMTP passwords or credentials inside the Git repository.

Your Linux mail client must be configured with an SMTP relay/provider.
The basic flow is:-
```
monitor.sh
     │
     ▼
send-email.sh
     │
     ▼
mail
     │
     ▼
SMTP Server
     │
     ▼
Recipient Inbox
```
First verify that the required commands are available:-
```
command -v mail
command -v envsubst
```
You should get paths similar to:
```
/usr/bin/mail
/usr/bin/envsubst
```
Then configure your system mail transport according to the SMTP provider you use.

⚠️ Never commit SMTP passwords, API keys, authentication tokens, or private credentials to GitHub.

---

## 📧 HTML Email Alerts

The project generates HTML-based email notifications using:
```
email-template.html
```
The template dynamically displays:

-   Server hostname
-   IP address
-   Timestamp
-   Previous status
-   Current status
-   CPU usage
-   Memory usage
-   Disk usage
-   Network status
-   Overall server status

Example flow:
```
Monitoring detects threshold violation
                │
                ▼
          Status changes
                │
                ▼
          Alert generated
                │
                ▼
         HTML template
                │
                ▼
          SMTP / mail
                │
                ▼
          Email inbox
```
## 🚨 Alert System

The monitor uses three states:
```
OK
WARNING
CRITICAL
```
Alerts are generated when the server changes state.
For example:
```
OK → WARNING
WARNING → CRITICAL
```
This prevents the system from sending the same alert repeatedly on every monitoring cycle.

---
## 🔄 Recovery Notifications
Recovery notifications are automatically generated when the server returns to a healthy state.

Example:
```
CRITICAL
   │
   │ Server resources recover
   ▼
WARNING
   │
   │ Server becomes healthy
   ▼
OK
```
The recovery email informs the administrator that the issue has been resolved.

---
## 🖥️ Running the Monitor Manually 

Run:
```
./monitor.sh
```
Example out:-
```
========================================
       LINUX SERVER HEALTH REPORT
========================================

Report generated at: Thu Sep 3 05:45:49 UTC 2026

Hostname        : server
IP Address      : 192.168.x.x
Uptime          : up 23 hours

CPU Usage       : 18.2 %
CPU status      : OK

Memory Usage    : 41 %
Memory Status   : OK

Disk Usage      : 1%
Disk Status     : OK

=======================================
Overall status  : OK
=======================================

Logged-in Users : 0
Network Status  : UP

========================================
```
Imp: This will be received after 3-4 seconds.

---
## 📜 Logs
Monitoring logs are stored inside:
```
logs/
```
Important files include:
```
monitor.log
error.log
alert.log
status.state
```
Monitor log
```
cat logs/monitor.log
```
Error log
```
cat logs/error.log
```
Alert log
```
cat logs/alert.log
```
Current status
```
cat logs/status.state
```

---
## 🔁 Log Rotation
To prevent logs from growing indefinitely, the monitoring script performs log rotation when log files exceed the configured size limit.

This helps prevent excessive disk usage caused by monitoring logs.

---

## ⏰ Cron Automation
The monitoring script can be executed automatically using Cron.

Open the user's crontab:
```
crontab -e
```
Add:
```
*/5 * * * * /path/to/server-monitor/monitor.sh >> /path/to/server-monitor/logs/cron.log 2>&1
```
This executes the monitoring script every **5 minutes**.

 ---
 ## Verify Cron
 List the current cron jobs:
 ```
 crontab -l
 ```
 Check cron log
 ```
 cat logs/cron.log
 ```
Make sure that script have executable permission
```
chmod +x monitor.sh
```
Use an absolute path in Cron. Cron does not necessarily run with the same working directory or environment as your interactive terminal.

---
## 🐳 Docker Monitoring Stack
The project uses Docker Compose for the visualization and metrics stack.

The stack consists of:
```
Node Exporter
      │
      ▼
Prometheus
      │
      ▼
Grafana
```
Start the stack:
```
docker compose up -d
```
Check running containers:
```
docker ps
```
Expected services:
```
prometheus
node-exporter
grafana
```

---
## 📊 Node Exporter
Node Exporter exposes Linux system metrics for Prometheus.

Check Node Exporter:
```
curl http://localhost:9100/metrics
```
You should see Prometheus-formatted metrics such as:
```
node_cpu_seconds_total
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes
node_filesystem_size_bytes
```
---
## 🔎 Prometheus
Prometheus collects metrics from Node Exporter.

Open:
```
http://localhost:9090
```
Check targets:
```
http://localhost:9090/targets
```
The Node Exporter target should show:
```
UP
```
Prometheus configuration is located at:
```
Prometheus configuration is located at:
```
---
## 📈 Grafana
Grafana provides visualization of the collected Linux server metrics.

Open:
```
http://localhost:3000
```
The project includes a preconfigured dashboard.

Dashboard:
```
Linux Server Monitoring Dashboard
```
The dashboard is automatically provisioned using:
```
grafana/provisioning/dashboards/dashboards.yml
```
Dashboard Defination
```
grafana/dashboards/server-monitor.json
```
---
## 📊 Dashboard Metrics
The Grafana dashboard provides visualization for metrics such as:

-   CPU usage
-   Memory usage
-   Disk usage
-   Network activity
-   System statistics
-   Linux host metrics

This provides a real-time visual representation of server health.

---

## Screenshots
Grafana Dashboard
```

```
Prometheus Targets
```
```
Critical Alert Email
```
```
Recovery Email
```

```

---
## 🔐 Security Considerations
The following security practices are followed:

-   SMTP credentials are not stored in the repository.
-   Secrets should never be committed to Git.
-   Runtime logs are excluded using `.gitignore`.
-   Environment files are excluded from Git.
-   Monitoring configuration is separated from the main script.
-   Email templates are separated from monitoring logic.

Before publishing the repository, verify:
```
git status
```

and make sure no credentials or private configuration files are staged.

---
## 🧹 Stop the Monitoring Stack
stop containers:
```
docker compose down
```
---

##  🔮 Future Improvements

Possible future improvements include:
-   Dockerizing the Bash monitoring agent while preserving host monitoring.
-   Slack/Telegram notifications
-   More detailed network monitoring
-   Process-level monitoring
-   Service availability checks
-   Configurable monitoring intervals
-   Centralized log management
-   Alert history dashboard
-   HTTPS for Grafana
-   Authentication and RBAC
-   Kubernetes deployment
-   Ansible-based installation
-   CI/CD pipeline

---
# 👨‍💻 Author

**Akshat Jain**

B.Tech — Information Technology

Interested in:
-   DevOps
-   Cloud Infrastructure
-   Linux
-   Backend Development
-   Monitoring & Observability


