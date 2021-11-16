#!/bin/bash

# Script parsing csv file and create motd banner on servers from file
# where columns: name;sid;product;environment;scheduler;backint

if [[ -n $1 && -n $2 ]]
then
        list=$(tail -n +2 $1|grep "$2;")
elif [[ -n $1 ]]
then
	list=$(tail -n +2 $1)
else
        echo "Usage: banners.sh <file.csv> [server name]"
        exit 1
fi

i=1
IFS=
echo "${list}" | while IFS=';' read -r name sid product environment scheduler backint
do
        if [[ -z ${name} ]]
        then
                echo "WARNING: Empty name in line $i" 1>&2
        elif [[ $(ssh -qno StrictHostKeyChecking=no ${name} dmidecode -s system-manufacturer) != "VMware, Inc." && ! "${name}" =~ "chp" && ! "${name}" =~ "chd" && ! "${name}" =~ "chq" && ! "${name}" =~ "hdb" ]]
        then
                echo "WARNING: ${name} - Not VMware VM" 1>&2
        else
                {
                            if [[ "${name}" =~ "sap" || "${name}" =~ "chp" || "${name}" =~ "chd" || "${name}" =~ "chq" || "${name}" =~ "hdb" ]]
                            then
                                sapservices=$(ssh -qno StrictHostKeyChecking=no $name "grep -s '^LD.*' /usr/sap/sapservices | grep -Ev 'JAA|DAA|JDA' | cut -d'/' -f4,5 | paste -s")
                            fi
                            echo "============================================="
                            echo "- Server Name      : ${name}"
                            echo "- SID              : ${sid}"
                            echo "- Product          : ${product}"
                            echo "- Environment      : ${environment}"
 [[ -n "${scheduler}" ]] && echo "- Backup scheduler : ${scheduler}"
   [[ -n "${backint}" ]] && echo "- Backint software : ${backint}"
 [[ -n ${sapservices} ]] && echo "- SAP Services     : ${sapservices}" 
                        echo "============================================="
                } | ssh -qo StrictHostKeyChecking=no ${name} "cat > /etc/motd"
                if [[ $? -eq 0 ]]
                then
                        echo "SUCCESS: ${name} - Banner configured"
                else
                        echo "ERROR: ${name} - Banner configuration failed" 1>&2
                fi
        fi
        ((i++))
done
