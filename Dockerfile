FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    bash curl git python3 python3-pip golang unzip cmake make gcc libssl-dev iproute2 iptables dnsmasq mongodb-clients \
    && rm -rf /var/lib/apt/lists/*

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
    cd /opt/xnlinkfinder && pip3 install -r requirements.txt

# Howl tools
RUN git clone https://github.com/Open5GS/open5gs.git /opt/open5gs && \
    cd /opt/open5gs && mkdir build && cd build && cmake .. && make && make install
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
