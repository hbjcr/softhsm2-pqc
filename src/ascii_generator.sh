#!/bin/bash

# Figlet examples: https://www.askapache.com/design/introducing-figlet-generator/

title() {
    if [ -n "$1" ]; then
        figlet -f slant "$1" | lolcat
    fi
}

subtitle() {
    if [ -n "$1" ]; then
        figlet -f small "$1" | lolcat
    fi
}

subtitle2() {
    if [ -n "$1" ]; then
        echo "$1" | lolcat -a
    fi
}