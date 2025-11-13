# Telegram Notifications Setup Guide

This guide will help you configure Telegram notifications for reconFTW Hidden Services Edition.

## Overview

The Telegram notification feature automatically sends you alerts when:
- 🔐 **Credentials are found** (username/password from brute force attacks)
- 🚨 **Vulnerabilities are discovered** (high/critical findings)
- 💉 **SQL injection data is extracted**
- 🚀 **Scans start and complete**
- 📊 **Summary reports** with statistics

## Setup Instructions

### Step 1: Create a Telegram Bot

1. Open Telegram and search for `@BotFather`
2. Start a chat with BotFather
3. Send the command: `/newbot`
4. Follow the prompts to choose a name and username for your bot
5. BotFather will give you a **bot token** that looks like:
   ```
   123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   ```
6. **Save this token** - you'll need it for configuration

### Step 2: Get Your Chat ID

#### Method 1: Using @userinfobot
1. Search for `@userinfobot` in Telegram
2. Start a chat with the bot
3. It will send you your **Chat ID** (a number like `123456789`)

#### Method 2: Using @getmyid_bot
1. Search for `@getmyid_bot` in Telegram
2. Start a chat and click "Start"
3. It will show your **Chat ID**

#### Method 3: Using the API
1. Send a message to your bot (the one you created with BotFather)
2. Visit this URL in your browser (replace TOKEN with your bot token):
   ```
   https://api.telegram.org/botTOKEN/getUpdates
   ```
3. Look for `"chat":{"id":123456789}` in the response
4. That number is your **Chat ID**

### Step 3: Configure reconftw-hs.cfg

Edit the configuration file:

```bash
nano reconftw-hs.cfg
```

Find the Telegram section and update these values:

```bash
# Telegram Notification Settings
TELEGRAM_ENABLED=true                    # Enable notifications
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"     # Replace with your bot token
TELEGRAM_CHAT_ID="YOUR_CHAT_ID"         # Replace with your chat ID
TELEGRAM_NOTIFY_START=true              # Notify when scan starts
TELEGRAM_NOTIFY_COMPLETE=true           # Notify when scan completes
TELEGRAM_NOTIFY_CREDENTIALS=true        # Notify when credentials found
TELEGRAM_NOTIFY_VULNS=true              # Notify on vulnerabilities
```

**Example:**
```bash
TELEGRAM_ENABLED=true
TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_CHAT_ID="987654321"
TELEGRAM_NOTIFY_START=true
TELEGRAM_NOTIFY_COMPLETE=true
TELEGRAM_NOTIFY_CREDENTIALS=true
TELEGRAM_NOTIFY_VULNS=true
```

### Step 4: Test Your Configuration

Run a test scan to verify notifications are working:

```bash
./reconftw-hs.sh -d example.onion
```

You should receive:
1. A "Scan Started" message when the scan begins
2. Real-time notifications as findings are discovered
3. A "Scan Completed" message with summary
4. A file attachment with all credentials found (if any)

## Notification Examples

### Scan Start Notification
```
🚀 Scan Started

📍 Target: example.onion
📅 Time: 2025-11-13 12:00:00
🔧 Mode: Hidden Services Edition

Starting reconnaissance...
```

### Credentials Found
```
🔐 Credentials Found

📍 Hidden Service: example.onion
🔧 Service: Web Login
👤 Username: admin
🔑 Password: password123
📅 Time: 2025-11-13 12:15:30

ℹ️ Additional Info:
Found via brute force attack
```

### Vulnerability Found
```
🔍 Vulnerability/Exposure Found

📍 Hidden Service: example.onion
🔎 Finding: [critical] SQL Injection at /login.php
📅 Time: 2025-11-13 12:20:15
```

### Scan Complete
```
✅ Scan Completed

📍 Target: example.onion
⏱️ Duration: 01:23:45
📅 Time: 2025-11-13 13:23:45
📂 Output: /path/to/reports/example.onion

Scan finished successfully.
```

### Summary Report
```
📊 Scan Summary

📍 Hidden Service: example.onion
📅 Time: 2025-11-13 13:23:45

📈 Statistics:
🔐 Credentials Found: 3
🚨 Vulnerabilities: 12
📁 Directories: 45
```

## Notification Types

### Credential Notifications
Automatically sent when:
- Web login credentials are found (hydra)
- HTTP Basic Auth credentials are found
- FTP credentials are discovered
- SSH credentials are found
- SQL injection extracts user data

### Vulnerability Notifications
Sent for:
- Critical severity findings
- High severity findings
- Exposed credentials in code
- API keys and tokens
- Sensitive data exposure

### Scan Status Notifications
- **Start**: When reconnaissance begins
- **Complete**: When all scans finish
- **Summary**: Final statistics and report

## Output Files

All credentials are also saved locally in:
```
reports/example.onion/credentials_found.txt
```

This file contains:
- Timestamp of discovery
- Hidden service domain
- Service type (web, FTP, SSH, etc.)
- Username and password
- Additional context

## Using Telegram Channels

To send notifications to a channel instead of a personal chat:

1. Create a Telegram channel
2. Add your bot as an administrator to the channel
3. Get the channel ID:
   - For public channels: Use `@channelname`
   - For private channels: Use the numeric ID (e.g., `-100123456789`)
4. Update `TELEGRAM_CHAT_ID` in config

## Troubleshooting

### Bot not sending messages
- Verify you've started a chat with your bot (send `/start`)
- Check that TELEGRAM_ENABLED=true
- Verify bot token and chat ID are correct
- Check internet connectivity

### Messages not formatted correctly
- Ensure you're using the latest version
- Check that special characters in findings are not breaking Markdown

### Test notification manually
```bash
# Source the config and library
source reconftw-hs.cfg
source lib/telegram-notify.sh

# Send a test message
send_telegram_message "🧪 Test notification from reconFTW-HS"
```

### Check Telegram API
Visit in browser (replace with your token):
```
https://api.telegram.org/botYOUR_TOKEN/getMe
```

Should return bot info if token is valid.

## Privacy & Security

⚠️ **Important Security Considerations:**

1. **Keep your bot token secret** - treat it like a password
2. **Never commit tokens to git** - they're excluded by default
3. **Use a private chat** - don't send credentials to public channels
4. **Secure your bot** - only you should have access to the chat
5. **Delete messages** - Telegram doesn't store messages indefinitely, but be aware

## Advanced Configuration

### Disable specific notifications

To only get credential notifications:
```bash
TELEGRAM_NOTIFY_START=false
TELEGRAM_NOTIFY_COMPLETE=false
TELEGRAM_NOTIFY_CREDENTIALS=true
TELEGRAM_NOTIFY_VULNS=false
```

### Multiple notification targets

To send to multiple chats, modify `lib/telegram-notify.sh`:
```bash
TELEGRAM_CHAT_ID="123456789,987654321"  # Comma-separated
```

## Useful Telegram Bot Commands

Send these to your bot:
- `/start` - Initialize the bot
- `/help` - Get help (if you implement it)
- `/status` - Check bot status (if you implement it)

## Example Workflow

```bash
# 1. Configure Telegram
nano reconftw-hs.cfg
# Set TELEGRAM_ENABLED=true and add credentials

# 2. Run a scan
./reconftw-hs.sh -d target.onion

# 3. Monitor Telegram
# You'll receive real-time updates on your phone

# 4. Review results
# Check the credentials_found.txt file in reports
cat reports/target.onion/credentials_found.txt
```

## Support

If you have issues:
1. Check bot token is valid
2. Verify chat ID is correct
3. Ensure bot has permission to message you
4. Check logs: `tail -f reports/target.onion/reconftw.log`

---

**Happy hunting! Stay secure and use responsibly.**
