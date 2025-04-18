#!/bin/bash
TARGET="$1"
shift
WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/quickhits.txt"  # Default
RUN_ALL="n"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s)
            shift
            ;;
        -a)
            RUN_ALL="y"
            shift
            ;;
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
echo "             🐺 GREY WOLF HUNT 🐺                     "
echo "======================================================"
echo "        // 🌙 The Silent Hunters 🌙 //"
echo "🔥🔥🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"

mkdir -p /app/output/$TARGET

echo "[*] Subdomain Enumeration..."
assetfinder --subs-only $TARGET > /app/output/$TARGET/subdomains.txt
subfinder -d $TARGET -o /app/output/$TARGET/subdomains_subfinder.txt
cat /app/output/$TARGET/subdomains_subfinder.txt | /root/go/bin/anew /app/output/$TARGET/subdomains.txt

echo "[*] Live Check..."
httpx -l /app/output/$TARGET/subdomains.txt -o /app/output/$TARGET/live_subdomains.txt

if [ "$RUN_ALL" = "y" ]; then
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
fi

echo "[*] Using wordlist: $WORDLIST"
echo "[*] Content Discovery..."
ffuf -u "http://FUZZ.$TARGET/" -w "$WORDLIST" -o /app/output/$TARGET/ffuf_results.json

echo "[*] Done! Results in /app/output/$TARGET"
ls -l /app/output/$TARGET/
