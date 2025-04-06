#!/bin/bash
# Banner
echo -e "\e[1;34m"
echo "🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"
echo "================================================================"
echo "             🐺 GREY WOLF FETCH 🐺"
echo "================================================================"
echo "        // 🌙 The Silent Hunters 🌙 //"
echo -e "\e[0m"
# API-specific recon

Usage() {
  echo "Usage: $0 <target> [-s] [-u] [-j] [-f] [-v] [-a|-all] [-w small|medium|large]"
  exit 1
}

RUN_S=0 RUN_U=0 RUN_J=0 RUN_F=0 RUN_V=0 RUN_ALL=0 WL_LEVEL=""
[ $# -eq 0 ] && Usage
while getopts ":sujfv-:w:" opt; do
  case "$opt" in
    s) RUN_S=1 ;;
    u) RUN_U=1 ;;
    j) RUN_J=1 ;;
    f) RUN_F=1 ;;
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

[ $RUN_S -eq 0 ] && [ $RUN_U -eq 0 ] && [ $RUN_J -eq 0 ] && [ $RUN_F -eq 0 ] && [ $RUN_V -eq 0 ] && [ $RUN_ALL -eq 0 ] && { RUN_S=1; RUN_U=1; RUN_F=1; }
[ $RUN_ALL -eq 1 ] && { RUN_S=1; RUN_U=1; RUN_J=1; RUN_F=1; RUN_V=1; }

set_wordlist() {
  if [ -n "$WL_LEVEL" ]; then
    case "$WL_LEVEL" in
      small)  WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/api/api-endpoints-short.txt" ;;
      medium) WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/api/api-endpoints.txt" ;;
      large)  WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/raft-large-files.txt" ;;
    esac
    echo "[*] Using wordlist: $WORDLIST (level: $WL_LEVEL)"
  else
    DEFAULT_WL="/app/wordlists/SecLists/Discovery/Web-Content/api/api-endpoints-short.txt"
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

subdomain_enum() { echo "[*] Subdomain Enumeration..."; subfinder -d "$TARGET" -silent > "$OUTDIR/subdomains.txt" & }
api_url_gather() { echo "[*] Gathering API URLs..."; gospider -s "https://$TARGET" | grep -i "api" > "$OUTDIR/api_urls.txt" & }
js_api_recon() { [ ! -f "$OUTDIR/api_urls.txt" ] && { echo "[-] Run -u first!"; return; }; echo "[*] JS API Recon..."; grep "\.js" "$OUTDIR/api_urls.txt" | while read -r js_url; do python3 /opt/xnlinkfinder/xnLinkFinder.py -i "$js_url" -o "$OUTDIR/api_js_findings_$(basename "$js_url").txt" & done; wait; cat "$OUTDIR/api_js_findings_"*.txt > "$OUTDIR/api_js_findings.txt" 2>/dev/null; }
api_fuzzing() { set_wordlist; echo "[*] Fuzzing API endpoints..."; ffuf -w "$WORDLIST" -u "https://$TARGET/api/FUZZ" -mc 200,201,403 -H "Accept: application/json" -o "$OUTDIR/api_fuzz.json" & }
vuln_scanning() { [ ! -f "$OUTDIR/subdomains.txt" ] && { echo "[-] Run -s first!"; return; }; echo "[*] Scanning API vulns..."; nuclei -l "$OUTDIR/subdomains.txt" -t api/ -o "$OUTDIR/api_vulns.txt" & }

[ $RUN_S -eq 1 ] && subdomain_enum
[ $RUN_U -eq 1 ] && api_url_gather
[ $RUN_J -eq 1 ] && [ $RUN_U -eq 1 ] && wait && js_api_recon
[ $RUN_F -eq 1 ] && api_fuzzing
[ $RUN_V -eq 1 ] && [ $RUN_S -eq 1 ] && wait && vuln_scanning

wait
echo "[*] Done! Results in $OUTDIR"
