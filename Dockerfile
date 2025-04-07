FROM ubuntu:22.04

# Install base dependencies including Go, MongoDB setup, and libpcap-dev
RUN apt-get update && apt-get install -y wget gnupg && \
    # Install Go 1.22
    wget https://go.dev/dl/go1.22.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.7.linux-amd64.tar.gz && \
    rm go1.22.7.linux-amd64.tar.gz && \
    # Add MongoDB repository
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc > /etc/apt/trusted.gpg.d/mongodb-server-7.0.asc && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && apt-get install -y \
    bash curl git python3 python3-pip unzip cmake make gcc libssl-dev iproute2 iptables dnsmasq mongodb-org-tools mongodb-mongosh libpcap-dev && \
    apt-get purge -y wget gnupg && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Set Go environment
ENV PATH="$PATH:/usr/local/go/bin"

# Hunt tools
RUN go install github.com/tomnomnom/assetfinder@latest && \
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest && \
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install github.com/tomnomnom/anew@latest && \
    go install github.com/lc/gau/v2/cmd/gau@latest && \
    go install github.com/projectdiscovery/katana/cmd/katana@latest && \
    go install github.com/ffuf/ffuf/v2@latest && \
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

RUN git clone https://github.com/m4ll0k/LinkFinder.git /opt/linkfinder && \
    cd /opt/linkfinder && pip3 install -r requirements.txt && \
    ln -s /opt/linkfinder/linkfinder.py /usr/local/bin/linkfinder

RUN git clone https://github.com/sullo/nikto.git /opt/nikto && \
    ln -s /opt/nikto/program/nikto.pl /usr/local/bin/nikto

# Fetch tools
RUN go install github.com/jaeles-project/gospider@latest
RUN git clone https://github.com/xnl-h4ck3r/xnLinkFinder.git /opt/xnlinkfinder && \
    cd /opt/xnlinkfinder && pip3 install requests termcolor urllib3 pyyaml beautifulsoup4

# Howl tools
RUN git clone --branch v2.7.1 https://github.com/Open5GS/open5gs.git /opt/open5gs && \
    cd /opt/open5gs && ls -la && test -f CMakeLists.txt && cmake -S . -B build && cd build && make && make install || echo "Open5GS build failed, skipping for now"
RUN pip3 install sipvicious

# SecLists
RUN git clone https://github.com/danielmiessler/SecLists.git /app/wordlists/SecLists
COPY wordlists/api-endpoints-short.txt /app/wordlists/SecLists/Discovery/Web-Content/api/api-endpoints-short.txt

WORKDIR /app
COPY *.sh .
RUN chmod +x *.sh
ENV PATH="$PATH:/root/go/bin:/usr/local/bin"
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["./grey-wolf-wrapper.sh"]
