#!/bin/bash
# Banner
echo -e "\e[1;34m"
echo "🔥🔥🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"
echo "================================================================"
echo "             🐺 GREY WOLF HUNT 🐺"
echo "================================================================"
echo "        // 🌙 The Silent Hunters 🌙 //"
echo -e "\e[0m"
# General bug bounty recon inspired by Jason Haddix’s methodology

Usage() {
  echo "Usage: $0 <target> [-s] [-l] [-u] [-j] [-c] [-v] [-a|-all] [-w small|medium|large]"
  exit 1
}

RUN_S=0 RUN_L=0 RUN_U=0 RUN_J=0 RUN_C=0 RUN_V=0 RUN_ALL=0 WL_LEVEL=""
[ $# -eq 0 ] && Usage
while getopts ":slujcv-:w:" opt; do
  case "$opt" in
    s) RUN_S=1 ;;
    l) RUN_L=1 ;;
    u) RUN_U=1 ;;
    j) RUN_J=1 ;;
    c) RUN_C=1 ;;
    v) RUN_V=1 ;;
    -) [ "$OPTARG" = "all" ] || [ "$OPTARG" = "a" ] && RUN_ALL=1 || { echo "Unknown option --$OPTARG"; Usage; } ;;
    w) WL_LEVEL="$OPTARG"; [ "$WL_LEVEL" != "small" ] && [ "$WL_LEVEL" != "medium" ] && [ "$WL_LEVEL" != "large" ] && { echo "Invalid -w: small, medium, large"; Usage; } ;;
    \?) echo "Invalid option: -$OPTARG"; Usage ;;
  esac
done
shift $((OPTIND - 1))

[ -z "$1" ] && { read -p "Enter target domain: " TARGET; } || TARGET="$1"
OUTDIR="/app/output/$TARGET"
mkdir -p "$OUTDIR"

[ $RUN_S -eq 0 ] && [ $RUN_L -eq 0 ] && [ $RUN_U -eq 0 ] && [ $RUN_J -eq 0 ] && [ $RUN_C -eq 0 ] && [ $RUN_V -eq 0 ] && [ $RUN_ALL -eq 0 ] && { RUN_S=1; RUN_L=1; RUN_C=1; }
[ $RUN_ALL -eq 1 ] && { RUN_S=1; RUN_L=1; RUN_U=1; RUN_J=1; RUN_C=1; RUN_V=1; }

set_wordlist() {
  if [ -n "$WL_LEVEL" ]; then
    case "$WL_LEVEL" in
      small)  WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/quickhits.txt" ;;
      medium) WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/common.txt" ;;
      large)  WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/raft-large-directories.txt" ;;
    esac
    echo "[*] Using wordlist: $WORDLIST (level: $WL_LEVEL)"
  else
    DEFAULT_WL="/app/wordlists/SecLists/Discovery/Web-Content/quickhits.txt"
    echo "No wordlist level specified (-w small|medium|large)."
    read -p "Use default ($DEFAULT_WL)? [y/N]: " choice
    if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
      WORDLIST="$DEFAULT_WL"
      echo "[*] Using default wordlist: $WORDLIST"
    else
      read -p "Enter custom wordlist path: " WL
      [ -f "$WL" ] || { echo "Wordlist not found at $WL!"; exit 1; }
      WORDLIST="$WL"
      echo "[*] Using custom wordlist: $WORDLIST"
    fi
  fi
}

subdomain_enum() { echo "[*] Subdomain Enumeration..."; assetfinder "$TARGET" 2>/dev/null > "$OUTDIR/assetfinder.txt" & subfinder -d "$TARGET" -silent 2>/dev/null > "$OUTDIR/subfinder.txt" & wait; cat "$OUTDIR/assetfinder.txt" "$OUTDIR/subfinder.txt" | anew > "$OUTDIR/subdomains.txt"; }
live_check() { [ ! -f "$OUTDIR/subdomains.txt" ] && { echo "[-] Run -s first!"; return; }; echo "[*] Live Check..."; naabu -list "$OUTDIR/subdomains.txt" -silent 2>/dev/null > "$OUTDIR/live_subdomains.txt" & httpx -l "$OUTDIR/live_subdomains.txt" -title -status-code -web-server 2>/dev/null > "$OUTDIR/httpx_results.txt" & wait; }
url_gather() { echo "[*] Gathering URLs..."; gau "$TARGET" 2>/dev/null > "$OUTDIR/gau_urls.txt" & katana -u "https://$TARGET" 2>/dev/null >> "$OUTDIR/gau_urls.txt" & wait; cat "$OUTDIR/gau_urls.txt" | anew > "$OUTDIR/urls.txt"; }
js_recon() { [ ! -f "$OUTDIR/urls.txt" ] && { echo "[-] Run -u first!"; return; }; echo "[*] JS Recon..."; grep "\.js" "$OUTDIR/urls.txt" | sort -u > "$OUTDIR/js_urls.txt"; : > "$OUTDIR/js-findings.txt"; while read -r js_url; do linkfinder -i "$js_url" -o cli 2>/dev/null >> "$OUTDIR/js-findings.txt"; done < "$OUTDIR/js_urls.txt"; }
content_discovery() { set_wordlist; echo "[*] Content Discovery..."; ffuf -w "$WORDLIST" -u "https://$TARGET/FUZZ" -mc 200,403 -o "$OUTDIR/ffuf_results.json" 2>/dev/null & }
vuln_scanning() { [ ! -f "$OUTDIR/live_subdomains.txt" ] && { echo "[-] Run -l first!"; return; }; echo "[*] Vulnerability Scanning..."; nuclei -l "$OUTDIR/live_subdomains.txt" -o "$OUTDIR/nuclei_results.txt" 2>/dev/null & while read -r domain; do nikto -host "$domain" -output "$OUTDIR/nikto_$domain.txt" 2>/dev/null & done < "$OUTDIR/live_subdomains.txt"; wait; }

[ $RUN_S -eq 1 ] && subdomain_enum
[ $RUN_L -eq 1 ] && [ $RUN_S -eq 1 ] && wait && live_check
[ $RUN_U -eq 1 ] && url_gather
[ $RUN_J -eq 1 ] && [ $RUN_U -eq 1 ] && wait && js_recon
[ $RUN_C -eq 1 ] && content_discovery
[ $RUN_V -eq 1 ] && [ $RUN_L -eq 1 ] && wait && vuln_scanning

wait
echo "[*] Done! Results in $OUTDIR"
