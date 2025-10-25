#!/bin/bash

source "${SCRIPT_DIR}/colors.sh"
source "${SCRIPT_DIR}/ascii_generator.sh"
source "${SCRIPT_DIR}/helpers.sh"

install_packages_silent "figlet" "lolcat"

info_box() {
    local message="$1"
    local information_icon="i"
    local message_with_icon=" ${BOLD}${BLACK}${BG_BRIGHT_CYAN}${information_icon}${NC} INFORMATION: ${message} "

    # Get the length of the message plus the icon and spaces
    local text_length=${#message_with_icon}
    
    # Define box-drawing characters
    local horizontal_line_char="─"
    local top_left_corner="┌"
    local top_right_corner="┐"
    local bottom_left_corner="└"
    local bottom_right_corner="┘"
    local vertical_line_char="│"

    # Print the top border
    printf "${BBLUE}${top_left_corner}"
    for ((i=0; i<text_length - 25; i++)); do
        printf "${horizontal_line_char}"
    done
    printf "${top_right_corner}${NC}\n"

    # Print the text line
    printf "${BBLUE}${vertical_line_char}${message_with_icon}${BBLUE}${vertical_line_char}${NC}\n"

    # Print the bottom border
    printf "${BBLUE}${bottom_left_corner}"
    for ((i=0; i<text_length - 25; i++)); do
        printf "${horizontal_line_char}"
    done
    printf "${bottom_right_corner}${NC}\n"
}

success_box() {
    local message="$1"
    local checkmark_icon="✅"
    local message_with_icon=" ${checkmark_icon} SUCCESS: ${message} "

    # Get the length of the message plus the icon and spaces
    local text_length=${#message_with_icon}
    
    # Define box-drawing characters
    local horizontal_line_char="─"
    local top_left_corner="┌"
    local top_right_corner="┐"
    local bottom_left_corner="└"
    local bottom_right_corner="┘"
    local vertical_line_char="│"

    # Print the top border
    printf "${GREEN}${top_left_corner}"
    for ((i=0; i<text_length + 1; i++)); do
        printf "${horizontal_line_char}"
    done
    printf "${top_right_corner}${NC}\n"

    # Print the text line
    printf "${GREEN}${vertical_line_char}${message_with_icon}${vertical_line_char}${NC}\n"

    # Print the bottom border
    printf "${GREEN}${bottom_left_corner}"
    for ((i=0; i<text_length + 1; i++)); do
        printf "${horizontal_line_char}"
    done
    printf "${bottom_right_corner}${NC}\n"
}

error_box() {
    local message="$1"
    local checkmark_icon="❌"
    local message_with_icon=" ${checkmark_icon}  ERROR: ${message} "

    # Get the length of the message plus the icon and spaces
    local text_length=${#message_with_icon}
    
    # Define box-drawing characters
    local horizontal_line_char="─"
    local top_left_corner="┌"
    local top_right_corner="┐"
    local bottom_left_corner="└"
    local bottom_right_corner="┘"
    local vertical_line_char="│"

    # Print the top border
    printf "${RED}${top_left_corner}"
    for ((i=0; i<text_length + 1; i++)); do
        printf "${horizontal_line_char}"
    done
    printf "${top_right_corner}${NC}\n"

    # Print the text line
    printf "${RED}${vertical_line_char}${message_with_icon}${vertical_line_char}${NC}\n"

    # Print the bottom border
    printf "${RED}${bottom_left_corner}"
    for ((i=0; i<text_length + 1; i++)); do
        printf "${horizontal_line_char}"
    done
    printf "${bottom_right_corner}${NC}\n"
}

warning_box() {
    local message="$1"
    local warning_icon="!"
    local message_with_icon=" ${BOLD}${BLACK}${BG_YELLOW}${warning_icon}${NC} INFORMATION: ${message} "

    # Get the length of the message plus the icon and spaces
    local text_length=${#message_with_icon}
    
    # Define box-drawing characters
    local horizontal_line_char="─"
    local top_left_corner="┌"
    local top_right_corner="┐"
    local bottom_left_corner="└"
    local bottom_right_corner="┘"
    local vertical_line_char="│"

    # Print the top border
    printf "${YELLOW}${top_left_corner}"
    for ((i=0; i<text_length - 24; i++)); do
        printf "${horizontal_line_char}"
    done
    printf "${top_right_corner}${NC}\n"

    # Print the text line
    printf "${YELLOW}${vertical_line_char}${message_with_icon}${YELLOW}${vertical_line_char}${NC}\n"

    # Print the bottom border
    printf "${YELLOW}${bottom_left_corner}"
    for ((i=0; i<text_length - 24; i++)); do
        printf "${horizontal_line_char}"
    done
    printf "${bottom_right_corner}${NC}\n"
}