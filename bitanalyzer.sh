#!/usr/bin/env bash

## ------------------ DESCRIPTION ------------------------ ##
##                                                         ##
## This script extracts data from blockchain.com. I used a ##
## table format to print this results and check it easily  ##
##                                                         ##
## ------------------------------------------------------- ##

## Author: Spore Studio

# Palette
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purplecolor="\e[0;35m\033[1m"
turquoiseColour="\e[0;36\033[1m"
grayColour="\e[0;37m\033[1m"

# Exit function
trap ctrl_c INT

function ctrl_c() {
    echo -e "\n${yellowColor}[*]${endColour}${grayColour} Exiting...${endColour}"

    rm ut.t* 2>/dev/null
    tput cnorm; exit 1
}


## Global variables ##
main_url="https://www.blockchain.com/explorer/mempool/btc/"
inspect_transaction_url="https://www.blockchain.com/explorer/transactions/btc/"
inspect_address_url="https://www.blockchain.com/explorer/addresses/btc/"


function helpPanel() {
    echo -e "\n${yellowColour} BitCoin Analyzer${endColour}"
    echo -e "\n${yellowColour}[*] Author:${endColour}${grayColour} Spore Studio\n${endColour}"
    echo -e "${yellowColour}[*] Use: ${endColour}"
    for i in $(seq 1 80); do echo -ne "${yellowColour}-"; done; echo -ne "${endColour}"
    echo -e "\n\n\t${grayColour}[-e] Exploration mode:${endColour}" 
    echo -e "\t\t${grayColour}unconfirmed_transacions:\t List unconfirmed transactions.${endColour}"
    echo -e "\t\t${grayColour}inspect:\t\t\t Inspect a hash transaction.${endColour}"
    echo -e "\t\t${grayColour}address:\t\t\t Inspect the address of a trasanction.${endColour}"
    echo -e "\n\t${grayColour}[-h] Show this help panel\n${endColour}"

    tput cnorm; exit 1
}


function dependencies() {
    tput civis
    clear
    dependencies=(html2text curl)

    echo -e "${yellowColour}[*]${endColour}${grayColour} Checking necessary dependencies...${endColour}"
    sleep 2

    for program in "${dependencies[@]}"; do
        echo -ne "\n${yellowColour}[*]${endColour}${grayColour} $program...${endColour}"

        # Check status code of the program
        test -f /usr/bin/$program

        if [ "$(echo $?)"  == "0" ]; then
            echo -e "${greenColour}(V)${endColour}"
        else
            echo -e "${redColour}(X)${endColour}\n"
            echo -e "${yellowColour}[*]${endColour}${grayColour} Instaling tool...${endColour}"
            if hash apt >/dev/null 2>$1; then
                sudo apt install -y html2text curl
                sudo apt autoremove
            elif hash dnf >/dev/null 2>$1; then
                sudo dnf install -y html2text curl
            elif hash pacman >/dev/null 2>$1; then
                sudo pacman -S --noconfirm html2text curl
            else
                echo -e "\n${redColour}Error: No suported package manager (apt, dnf, pacman) found. Cannot install requiered packages."
                tput cnorm; exit 1
            fi
        fi
        sleep 2

    done
}

## -- Table functions -- ##
function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}
## --- --- ##


function unconfirmedTransactions() {
    echo '' > ut.tmp

    while [ "$(cat ut.tmp | wc -l)" == "1" ]; do
        curl -s "$main_url" | html2text > ut.tmp
    done

    hashes=$(cat ut.tmp | grep "Hash" -A 1 | grep -vE "Hash" | awk '{print $1}' | cut -c 1-9)

    echo "Hash_Quantity_Bitcoin_Hour" > ut.table

    for hash in $hashes; do
        echo "${hash}_$(cat ut.tmp | grep "$hash" -A 1 | sed -n 's/.*\(\$[0-9]*\.[0-9]*\).*/\1/p')_$(cat ut.tmp | grep "$hash" -A 1 | paste -sd ' ' - | grep -oE '\b[0-9]+\.[0-9]{1,8} BTC')_$(cat ut.tmp | grep "$hash" -A 1 | grep -oP '\d{2}:\d{2}:\d{2}')" >> ut.table
    done

    printTable '_' "$(cat ut.table)"

    rm -f ut.t* 2>/dev/null
    tput cnorm
}


function inspectTransaction() {
    inspect_transaction=$1

    tput cnorm
}


# main function
paremeter_counter=0; while getopts "e:n:i:a:h:" arg; do
    case $arg in
        e) exploration_mode=$OPTARG; let paremeter_counter+=1;;
        n) number_output=$OPTARG; let parameter_counter+=1;;
        i) inspect_transaction=$OPTARG; let parameter_counter+=1;;
        a) inspect_address=$OPTARG; let parameter_counter+=1;;
        h) helpPanel;;
    esac
done

tput civis 

if [ $paremeter_counter -eq 0 ]; then
    helpPanel
else
    if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
        dependencies
        clear

        if [ ! "$number_output" ]; then
            number_output=100
            unconfirmedTransactions $number_output
        else unconfirmedTransactions
            unconfirmedTransactions $number_output
        fi
    elif [ "$(echo $exploration_mode)" == "inspect_transaction" ]; then
        inspectTransaction $inspect_transaction
    fi
fi