# Use a standard Ubuntu LTS base image
FROM ubuntu:22.04

# Arguments to customize the build
ARG PROTOCOL
ARG DESKTOP_ENV
ARG DEBIAN_FRONTEND=noninteractive

# 1. Overwrite sources.list to use main Ubuntu archives instead of regional/Azure mirrors
# This ensures faster and more reliable package downloads during the build process.
RUN <<EOF > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
EOF

# 2. Update sources and install core utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    wget \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# 3. Install the chosen Desktop Environment
RUN apt-get update && \
    case ${DESKTOP_ENV} in \
        xfce) apt-get install -y --no-install-recommends xfce4 xfce4-goodies ;; \
        gnome) apt-get install -y --no-install-recommends gnome-panel gnome-shell gnome-terminal ;; \
        kde) apt-get install -y --no-install-recommends kde-plasma-desktop ;; \
        mate) apt-get install -y --no-install-recommends ubuntu-mate-core ;; \
        cinnamon) apt-get install -y --no-install-recommends cinnamon-core ;; \
        lxqt) apt-get install -y --no-install-recommends lxqt-core ;; \
    esac && \
    rm -rf /var/lib/apt/lists/*

# 4. Install the chosen Remote Protocol
RUN apt-get update && \
    case ${PROTOCOL} in \
        xrdp) apt-get install -y --no-install-recommends xrdp ;; \
        vnc) apt-get install -y --no-install-recommends tigervnc-standalone-server tigervnc-common ;; \
    esac && \
    rm -rf /var/lib/apt/lists/*

# 5. Configure users with blank passwords as requested
RUN useradd -m -s /bin/bash user && \
    usermod -aG sudo user && \
    echo "root:" | chpasswd && \
    echo "user:" | chpasswd && \
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 6. Add and configure the startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose standard ports for RDP and VNC
EXPOSE 3389 5901

ENTRYPOINT ["/entrypoint.sh"]
# Pass the build arguments to the entrypoint script at runtime
CMD [ "${PROTOCOL}", "${DESKTOP_ENV}" ]
