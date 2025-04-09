#!/bin/bash
TARGET="$1"
shift
WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/quickhits.txt"  # Default

while [[ $# -gt 0 ]]; do
    case $1 in
        -w)
            shift
            case $1 in
                small)
                    WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/quickhits.txt"
                    ;;
                medium)
                    WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/common.txt"
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
echo "======================================================"
echo "          🐺 WOLF PACK ATTACK 🐺                      "
echo "======================================================"
echo "        // 🌙 The Full Pack Unleashed 🌙 //"
echo "🔥🔥🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"

mkdir -p /app/output/$TARGET

# Hunt Tools
echo "[*] Subdomain Enumeration..."
assetfinder --subs-only $TARGET > /app/output/$TARGET/subdomains.txt
subfinder -d $TARGET -o /app/output/$TARGET/subdomains_subfinder.txt
cat /app/output/$TARGET/subdomains_subfinder.txt | /root/go/bin/anew /app/output/$TARGET/subdomains.txt

echo "[*] Live Check..."
httpx -l /app/output/$TARGET/subdomains.txt -o /app/output/$TARGET/live_subdomains.txt

echo "[*] Port Scanning..."
naabu -l /app/output/$TARGET/subdomains.txt -o /app/output/$TARGET/ports.txt

echo "[*] URL Crawling..."
gau $TARGET > /app/output/$TARGET/gau_urls.txt

echo "[*] Advanced Crawling..."
katana -u "https://$TARGET" -o /app/output/$TARGET/katana_urls.txt

echo "[*] Vulnerability Scanning..."
nuclei -l /app/output/$TARGET/live_subdomains.txt -o /app/output/$TARGET/nuclei_results.txt

echo "[*] Nikto Scan..."
nikto -h $TARGET -output /app/output/$TARGET/nikto_results.txt

echo "[*] Link Finding..."
linkfinder -i "https://$TARGET" -o /app/output/$TARGET/linkfinder_results.html

# Fetch Tools
echo "[*] Spidering..."
gospider -s "https://$TARGET" -o /app/output/$TARGET/gospider_results.txt

echo "[*] Advanced Link Finding..."
python3 /opt/xnlinkfinder/xnlinkfinder.py -i "https://$TARGET" -o /app/output/$TARGET/xnlinkfinder_results.html

# Howl Tools
echo "[*] SIP Scanning..."
svmap $TARGET > /app/output/$TARGET/sipmap_results.txt  # sipvicious tool

echo "[*] Open5GS Setup (placeholder)..."
if [ -x /usr/local/bin/open5gs ]; then
    echo "Open5GS installed, running placeholder command..."
    # Add real Open5GS command if needed
else
    echo "Open5GS not fully installed, skipping..."
fi

# Content Discovery
echo "[*] Using wordlist: $WORDLIST"
echo "[*] Content Discovery..."
ffuf -u "http://FUZZ.$TARGET/" -w "$WORDLIST" -o /app/output/$TARGET/ffuf_results.json

echo "[*] Done! Results in /app/output/$TARGET"
ls -l /app/output/$TARGET/
