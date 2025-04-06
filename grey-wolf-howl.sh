#!/bin/bash
# Banner
# Telecom recon (LTE/5G, SIP, cloud)
echo -e "\e[1;34m"
echo "🔥🔥🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"
echo "================================================================"
echo "             🐺 GREY WOLF HOWL 🐺"
echo "================================================================"
echo "        // 🌙 The Silent Hunters 🌙 //"
echo -e "\e[0m"

Usage() {
  echo "Usage: $0 <target> [-s] [-w small|medium|large]"
  exit 1
}

RUN_S=0 WL_LEVEL=""
[ $# -eq 0 ] && Usage
while getopts ":s-:w:" opt; do
  case "$opt" in
    s) RUN_S=1 ;;
    -) [ "$OPTARG" = "all" ] || [ "$OPTARG" = "a" ] && RUN_S=1 || { echo "Unknown option --$OPTARG"; Usage; } ;;
    w) WL_LEVEL="$OPTARG"; [ "$WL_LEVEL" != "small" ] && [ "$WL_LEVEL" != "medium" ] && [ "$WL_LEVEL" != "large" ] && { echo "Invalid -w: small, medium, large"; Usage; } ;;
    \?) echo "Invalid option: -$OPTARG"; Usage ;;
  esac
done
shift $((OPTIND - 1))

[ -z "$1" ] && { read -p "Enter target domain: " TARGET; } || TARGET="$1"
OUTDIR="/app/output/$TARGET"
mkdir -p "$OUTDIR"

[ $RUN_S -eq 0 ] && RUN_S=1  # Default to SIP scan

set_wordlist() {
  if [ -n "$WL_LEVEL" ]; then
    case "$WL_LEVEL" in
      small)  WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/quickhits.txt" ;;
      medium) WORDLIST="/app/wordlists/SecLists/Miscellaneous/cloudflare-bypass.txt" ;;
      large)  WORDLIST="/app/wordlists/SecLists/Discovery/Web-Content/big.txt" ;;
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

sip_scan() { echo "[*] Scanning SIP..."; svmap -o "$OUTDIR/sip_results.txt" "$TARGET" & }  # Placeholder—expand later

[ $RUN_S -eq 1 ] && sip_scan

wait
echo "[*] Done! Results in $OUTDIR"
