#!/bin/bash
FILE_PATH="$3"
HOST="$2"
HTTP_WORDLIST="$4"
HTTP_EXTENSIONS_FILE="$5"
##                   ##
###   XML PARSER    ###
##                   ##

#  
#  name: tcp_service_on 
#  @param: state of port={open, filtered} ; port name={http, ssh, ...} ; ssl={1 == YES, 0 == NO}
#  @return: 0 = {port found} ; 10 {port not found}
#  
tcp_service_on () {
    if [[ "$3" == '0' ]]; then 
        xmllint --xpath "//port[state[@state='$1'] and service[@name='$2']]" "$FILE_PATH/IG/NMAP/script-syn.xml" &> /dev/null
    elif [[ "$3" == '1' ]]; then 
        xmllint --xpath "//port[state[@state='$1'] and service[@name='$2' and @tunnel='ssl']]" "$FILE_PATH/IG/NMAP/script-syn.xml" &> /dev/null
    else 
        return 1    #ERROR
    fi
}

#  
#  name: udp_service_on 
#  @param: port name={rpcbind, mdns, ...}
#  @return: 0 = {port found} ; 10 {port not found}
# 
udp_service_on () {
    xmllint --xpath "//port[state[@state='open|filtered'] and service[@name='$1']]" "$FILE_PATH/IG/NMAP/udp.xml" &> /dev/null
}

#  
#  name: print_portid
#  @param: state of port={open, filtered} ; port name={http, ssh, ...} ; ssl={1 == YES, 0 == NO}
#  @return: portid
#
print_portid () {
    if [[ "$3" == '0' ]]; then
        xmllint --xpath "//port[state[@state='$1'] and service[@name='$2']]/@portid" "$FILE_PATH/IG/NMAP/script-syn.xml" | cut -c 2- | tr " " "\n" | cut -f2 -d'"'
    elif [[ "$3" == '1' ]]; then
        xmllint --xpath "//port[state[@state='$1'] and service[@name='$2' and @tunnel='ssl']]/@portid" "$FILE_PATH/IG/NMAP/script-syn.xml" | cut -c 2- | tr " " "\n" | cut -f2 -d'"'
    else 
        return 1    #ERROR
    fi
}


        if grep 'CVE:' "$3/IG/NMAP/CVE.txt"; then       
            
            # print_succ 'starting Metasploit research...'
            
            msfconsole -q -o "$3/VA/KNOWN_EXPLOITS/meta_module.txt" -x "db_rebuild_cache ; resource $3/IG/NMAP/CVE.txt ; exit -y" 
            
            # searchsploit
            # print_succ 'starting searchsploit...'
            
            searchsploit --www --nmap "$3/IG/NMAP/script-syn.xml" > "$3/VA/KNOWN_EXPLOITS/exploit-db.txt"
            searchsploit --www --nmap "$3/IG/NMAP/udp.xml" >> "$3/VA/KNOWN_EXPLOITS/exploit-db.txt"

        else
            # print_failure 'no exploits found!'
            touch "$3/VA/KNOWN_EXPLOITS/NO_cve_found.txt"
        fi
        #http nikto is like nmap checking ports if something is open or not/ responding or not
        tcp_service_on 'open' 'http' '0' && {
            # print_succ 'starting nikto...';
            for PORT in $(print_portid 'open' 'http' '0'); do
                # print_std "Nikto port: $PORT"
                nikto -Display PV -nolookup -ask no -Format htm -host $HOST:$PORT -output "$FILE_PATH/VA/nikto_$PORT.html" -Plugins "ms10_070;report_html;embedded;cookies;put_del_test;outdated;drupal(0:0);clientaccesspolicy;msgs;httpoptions;negotiate;parked;favicon;apache_expect_xss;headers" -Tuning 4890bcde > /dev/null
            done;
            
            # print_succ 'starting dirb...';
            for PORT in $(print_portid 'open' 'http' '0'); do
                # print_std "Dirb port: $PORT"
                dirb "http://$HOST:$PORT/" "$HTTP_WORDLIST" -r -l -o "$FILE_PATH/VA/dirb_$PORT.txt" -x "$HTTP_EXTENSIONS_FILE" -z 200 > /dev/null
            done;
        }
            
            #Dirb takes approximaly one hour to finish the wordlist with the following setting.
            #It doesn't search recursively.

        #https exact same thing
        tcp_service_on 'open' 'https' '0' && {
            # execute nikto and dirb for https protocol
            # print_succ 'starting nikto (https)...';
            for PORT in $(print_portid 'open' 'https' '0'); do
                # print_std "Nikto port: $PORT"
                nikto -ssl -port $PORT -Display PV -nolookup -ask no -Format htm -host $HOST -output "$FILE_PATH/VA/nikto_https_$PORT.html" -Plugins "ms10_070;report_html;embedded;cookies;put_del_test;outdated;drupal(0:0);clientaccesspolicy;msgs;httpoptions;negotiate;parked;favicon;apache_expect_xss;ssl;headers" -Tuning 4890bcde > /dev/null
            done;
            
            # print_succ 'starting dirb (https)...';
            for PORT in $(print_portid 'open' 'https' '0'); do
                # print_std "Dirb port: $PORT"
                dirb "https://$HOST:$PORT/" "$HTTP_WORDLIST" -r -l -o "$FILE_PATH/VA/dirb_https_$PORT.txt" -x "$HTTP_EXTENSIONS_FILE" -z 200 > /dev/null
            done;
        }
        
        #ssl/http
        tcp_service_on 'open' 'http' '1' && {
            # execute nikto and dirb for ssl/http protocol
            # print_succ 'starting nikto (ssl/http)...';
            for PORT in $(print_portid 'open' 'http' '1'); do
                # print_std "Nikto port: $PORT"
                nikto -ssl -port $PORT -Display PV -nolookup -ask no -Format htm -host $HOST -output "$FILE_PATH/VA/nikto_https_$PORT.html" -Plugins "ms10_070;report_html;embedded;cookies;put_del_test;outdated;drupal(0:0);clientaccesspolicy;msgs;httpoptions;negotiate;parked;favicon;apache_expect_xss;ssl;headers" -Tuning 4890bcde > /dev/null
            done;
            
            # print_succ 'starting dirb (ssl/http)...';
            for PORT in $(print_portid 'open' 'http' '1'); do
                # print_std "Dirb port: $PORT"
                dirb "https://$HOST:$PORT/" "$HTTP_WORDLIST" -r -l -o "$FILE_PATH/VA/dirb_https_$PORT.txt" -x "$HTTP_EXTENSIONS_FILE" -z 200 > /dev/null
            done;
        }
exit 0
        