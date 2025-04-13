#!/bin/bash
echo "Running fetch script..."  # Debug
TARGET="$1"
shift
WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/api/api-endpoints-short.txt"  # API-focused default
RUN_SUBDOMAINS="n"
RUN_LIVE="n"
RUN_URLS="n"
RUN_JS="n"
RUN_CONTENT="n"
RUN_VULNS="n"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s)
            RUN_SUBDOMAINS="y"
            shift
            ;;
        -l)
            RUN_LIVE="y"
            shift
            ;;
        -u)
            RUN_URLS="y"
            shift
            ;;
        -j)
            RUN_JS="y"
            shift
            ;;
        -c)
            RUN_CONTENT="y"
            shift
            ;;
        -v)
            RUN_VULNS="y"
            shift
            ;;
        -all)
            RUN_SUBDOMAINS="y"
            RUN_LIVE="y"
            RUN_URLS="y"
            RUN_JS="y"
            RUN_CONTENT="y"
            RUN_VULNS="y"
            shift
            ;;
        -w)
            shift
            case $1 in
                small)
                    WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/api/api-endpoints-short.txt"
                    ;;
                medium)
                    WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/api-endpoints.txt"
                    ;;
                large)
                    WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/raft-large-words.txt"
                    ;;
                *)
                    echo "Invalid wordlist level: $1 (use small|medium|large)"
                    exit 1
                    ;;
            esac
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo "🔥🔥🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"
echo "================================================================"
echo "          🐺 GREY WOLF FETCH 🐺"
echo "================================================================"
echo "        // 🌙 API Hunters Unleashed 🌙 //"
echo

mkdir -p /app/output/$TARGET

if [ "$RUN_SUBDOMAINS" = "y" ]; then
    echo "[*] Subdomain Enumeration..."
    assetfinder --subs-only $TARGET > /app/output/$TARGET/subdomains.txt
    subfinder -d $TARGET -o /app/output/$TARGET/subdomains_subfinder.txt
    cat /app/output/$TARGET/subdomains_subfinder.txt | /root/go/bin/anew /app/output/$TARGET/subdomains.txt
fi

if [ "$RUN_LIVE" = "y" ]; then
    echo "[*] Live Check..."
    if [ -s /app/output/$TARGET/subdomains.txt ]; then
        naabu -l /app/output/$TARGET/subdomains.txt -o /app/output/$TARGET/ports.txt
        httpx -l /app/output/$TARGET/subdomains.txt -tech-detect -o /app/output/$TARGET/live_subdomains.txt
    else
        echo "No subdomains found, skipping live check..."
    fi
fi

if [ "$RUN_URLS" = "y" ]; then
    echo "[*] URL Crawling..."
    gau $TARGET > /app/output/$TARGET/gau_urls.txt
    katana -u "https://$TARGET" -o /app/output/$TARGET/katana_urls.txt
    cat /app/output/$TARGET/gau_urls.txt /app/output/$TARGET/katana_urls.txt | /root/go/bin/anew /app/output/$TARGET/urls.txt
fi

if [ "$RUN_JS" = "y" ]; then
    echo "[*] JS Recon..."
    if [ -s /app/output/$TARGET/live_subdomains.txt ]; then
        linkfinder -i "https://$TARGET" -o /app/output/$TARGET/linkfinder_results.html
        python3 /opt/xnlinkfinder/xnlinkfinder.py -i "https://$TARGET" -o /app/output/$TARGET/xnlinkfinder_results.html
    else
        echo "No live subdomains, skipping JS recon..."
    fi
fi

if [ "$RUN_CONTENT" = "y" ]; then
    echo "[*] Using wordlist: $WORDLIST"
    echo "[*] Content Discovery..."
    if [ -s /app/output/$TARGET/live_subdomains.txt ]; then
        ffuf -u "http://FUZZ.$TARGET/" -w "$WORDLIST" -o /app/output/$TARGET/content.json
    else
        echo "No live subdomains, skipping content discovery..."
    fi
fi

if [ "$RUN_VULNS" = "y" ]; then
    echo "[*] Vulnerability Scanning..."
    if [ -s /app/output/$TARGET/live_subdomains.txt ]; then
        nuclei -l /app/output/$TARGET/live_subdomains.txt -t api/ -o /app/output/$TARGET/vuln_results.txt
    else
        echo "No live subdomains, skipping vuln scanning..."
    fi
fi

echo "[*] Done! Results in /app/output/$TARGET"
ls -l /app/output/$TARGET/
