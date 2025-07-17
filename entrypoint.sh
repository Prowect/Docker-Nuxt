#!/bin/sh

export BASH_COLOR_PRIMARY='\033[1;36m'
export BASH_COLOR_DARK='\033[1;30m'
export BASH_COLOR_RESET='\033[0m'
export BASH_COLOR_ERROR='\033[0;31m'
export BASH_COLOR_SUCCESS='\033[0;32m'
export BASH_COLOR_WARNING='\033[0;33m'

echo -e "
$BASH_COLOR_PRIMARY          ##########         
$BASH_COLOR_PRIMARY       #################       
$BASH_COLOR_PRIMARY    #####           #####     $BASH_COLOR_DARK  _____                            _   
$BASH_COLOR_PRIMARY  #####   #########   #####   $BASH_COLOR_DARK |  __ \                          | |  
$BASH_COLOR_PRIMARY  ####  #############  ####   $BASH_COLOR_DARK | |__) | __ _____      _____  ___| |_ 
$BASH_COLOR_PRIMARY  ###   #############   ###   $BASH_COLOR_DARK |  ___/ '__/ _ \ \ /\ / / _ \/ __| __|
$BASH_COLOR_PRIMARY  ###   #############  ####   $BASH_COLOR_DARK | |   | | | (_) \ V  V /  __/ (__| |_ 
$BASH_COLOR_PRIMARY  ###     #########   #####   $BASH_COLOR_DARK |_|   |_|  \___/ \_/\_/ \___|\___|\__|
$BASH_COLOR_PRIMARY   ##   ##         #####
$BASH_COLOR_PRIMARY        #############
$BASH_COLOR_PRIMARY          ##########
$BASH_COLOR_RESET"

echo -e "${BASH_COLOR_DARK}Starting Docker ${BASH_COLOR_SUCCESS}Nuxt${BASH_COLOR_DARK} ...${BASH_COLOR_RESET}"

# Setup nuxt if not present
NUXT_CONFIG_FILE="/app/nuxt.config.ts"
NODE_MODULES_DIRECTORY="/app/node_modules"
NUXT_SERVER_INDEX_FILE="/app/.output/server/index.mjs"
if [[ ! -f "$NUXT_CONFIG_FILE" ]]; then
    echo -e "${BASH_COLOR_WARNING}No nuxt source files detected. Installing a new nuxt instance ...${BASH_COLOR_RESET}"

    npm create nuxt . --yes -- --yes --force --packageManager=npm --gitInit=false --no-modules
    echo -e "${BASH_COLOR_SUCCESS}Nuxt has been installed${BASH_COLOR_RESET}"
elif [[ ! -d "$NODE_MODULES_DIRECTORY" ]] && [[ ! -f "$NUXT_SERVER_INDEX_FILE" ]]; then
    echo -e "${BASH_COLOR_WARNING}Installing node modules ...${BASH_COLOR_RESET}"

    npm install
fi

# cleanup sockets (required to avoid "EADDRINUSE: address already in use")
echo "Cleaning up sockets under /tmp/nitro"
rm -rf /tmp/nitro/worker-*

# Allows you to add /entrypoint.sh using your own Dockerfile - to automatically be executed
ADDITIONAL_ENTRYPOINT_FILE="/entrypoint.sh"
if [[ -f "$ADDITIONAL_ENTRYPOINT_FILE" ]]; then
    echo -e "${BASH_COLOR_WARNING}Found additional entrypoint. Running ${ADDITIONAL_ENTRYPOINT_FILE} ...${BASH_COLOR_RESET}"
    chmod +x $ADDITIONAL_ENTRYPOINT_FILE
    exec $ADDITIONAL_ENTRYPOINT_FILE
fi

# Run nuxt or execute given CMD
if [ -z "$*" ] || [ "$@" == "build" ]; then
    NUXT_BUILD_DIRECTORY="/app/.output";
    if [[ ! -d "$NUXT_BUILD_DIRECTORY" ]]; then
        echo -e "${BASH_COLOR_WARNING}Building nuxt ...${BASH_COLOR_RESET}"
        npm run build

        echo -e "${BASH_COLOR_WARNING}Deleting node modules ...${BASH_COLOR_RESET}"
        rm -rf /app/node_modules
        echo "Build complete"
    fi

    if [ -z "$*" ]; then
        echo -e "${BASH_COLOR_SUCCESS}Starting nuxt ...${BASH_COLOR_RESET}"
        node .output/server/index.mjs
    fi
else
    exec "$@"
fi