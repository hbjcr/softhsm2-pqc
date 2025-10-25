#!/bin/bash

# ANSI color codes
# Escape code: \e or \033

# Reset to default
readonly NC='\e[0m' # No Color

# Regular Colors
readonly BLACK='\e[0;30m'
readonly RED='\e[0;31m'
readonly GREEN='\e[0;32m'
readonly YELLOW='\e[0;33m'
readonly BLUE='\e[0;34m'
readonly MAGENTA='\e[0;35m'
readonly CYAN='\e[0;36m'
readonly WHITE='\e[0;37m'

# Bright Colors
readonly BBLACK='\e[1;30m'
readonly BRED='\e[1;31m'
readonly BGREEN='\e[1;32m'
readonly BYELLOW='\e[1;33m'
readonly BBLUE='\e[1;34m'
readonly BMAGENTA='\e[1;35m'
readonly BCYAN='\e[1;36m'
readonly BWHITE='\e[1;37m'

# Other Styles
readonly BOLD='\e[1m'
readonly UNDERLINE='\e[4m'
readonly INVERT='\e[7m'

# Background Regular Colors
readonly BG_BLACK='\e[40m'
readonly BG_RED='\e[41m'
readonly BG_GREEN='\e[42m'
readonly BG_YELLOW='\e[43m'
readonly BG_BLUE='\e[44m'
readonly BG_MAGENTA='\e[45m'
readonly BG_CYAN='\e[46m'
readonly BG_WHITE='\e[47m'

# Bright Colors
readonly BG_BRIGHT_BLACK='\e[100m'
readonly BG_BRIGHT_RED='\e[101m'
readonly BG_BRIGHT_GREEN='\e[102m'
readonly BG_BRIGHT_YELLOW='\e[103m'
readonly BG_BRIGHT_BLUE='\e[104m'
readonly BG_BRIGHT_MAGENTA='\e[105m'
readonly BG_BRIGHT_CYAN='\e[106m'
readonly BG_BRIGHT_WHITE='\e[107m'
