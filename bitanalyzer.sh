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
    exit 1
}

sleep 100