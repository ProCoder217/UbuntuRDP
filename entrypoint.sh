#!/bin/bash
set -e

# Arguments passed from Docker CMD
PROTOCOL=$1
DESKTOP_ENV=$2

# Create a session file for xrdp to know which desktop to start
if [ "$PROTOCOL" = "xrdp" ]; then
    SESSION_CMD="exec $(which start${DESKTOP_ENV})"
    # Special cases for some DEs that have different startup commands
    if [ "$DESKTOP_ENV" = "xfce" ]; then
        SESSION_CMD="exec startxfce4"
    elif [ "$DESKTOP_ENV" = "kde" ]; then
        SESSION_CMD="exec startplasma-x11"
    fi
    echo "$SESSION_CMD" > /home/user/.xsession
    chown user:user /home/user/.xsession
fi

# Start the selected remote desktop service in the foreground
if [ "$PROTOCOL" = "xrdp" ]; then
    echo "✅ Starting XRDP service..."
    # Using exec replaces the script process with xrdp, running it in the foreground
    exec /usr/sbin/xrdp -n
elif [ "$PROTOCOL" = "vnc" ]; then
    echo "✅ Starting VNC Server..."
    # Create VNC directory and set a blank password for the 'user' account
    mkdir -p /home/user/.vnc
    echo "" | su - user -c "vncpasswd -f > /home/user/.vnc/passwd"
    chmod 600 /home/user/.vnc/passwd
    
    # Start VNC server as 'user' on display :1 and run it in the foreground (-fg)
    # This ensures the container stays running.
    su - user -c "vncserver :1 -geometry 1280x800 -depth 24 -fg"
fi
