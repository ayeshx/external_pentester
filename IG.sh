#!/bin/bash
nmap -vvv -oA "$3/IG/NMAP/cve" --script nmap-vulners,vulscan --script-args vulscandb=openvas.csv -sV -p80,443,22,25,110,445 "$2"
nmap -vvv -oA "$3/IG/NMAP/script-syn" -PE -PS80,443,22,25,110,445 -PU -PP -PA80,443,22,25,110,445 -sS -p- -sV --allports -O --fuzzy --script "(default or auth or vuln or exploit) and not http-enum" "$2" | grep 'Hosts that seem down' > /dev/null && { print_failure 'Host down' ; rm -fR "$3"; continue; }
grep -v '|' "$3/IG/NMAP/script-syn.nmap" > "$3/IG/NMAP/syn.nmap"

nmap -vvv -oA "$3/IG/NMAP/udp" -PE -PS80,443,22,25,110,445 -PU -PP -PA80,443,22,25,110,445 -sU --top-ports 200 -sV --allports "$2" > /dev/null || failure "NMAP ERROR (UDP-SCAN); exit with code $?"
service postgresql start
msfconsole -q -o "$3/IG/metasploit_scan.txt" -x "setg rhosts $2 ; resource $4 ; exit -y"
exit 0