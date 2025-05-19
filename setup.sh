#!/usr/bin/env bash
# build.sh - Build script for the P Compiler
#
# Usage:
#   ./build.sh [options]
#
# Options:
#   -c, --config <config>  Build configuration (Debug|Release, default: Release)
#   -v, --verbose          Display detailed build output
#   -h, --help             Show this help message
#   --skip-submodules      Skip updating git submodules
#   --install              Install P as a global dotnet tool after building
#   --version <version>    Specify version when installing (default: 1.0.0-local)

# Terminal colors
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'

# Default values
CONFIG="Release"
VERBOSE="q"
UPDATE_SUBMODULES=true
INSTALL_TOOL=false
TOOL_VERSION="1.0.0-local"

# Function to display usage information
usage() {
    echo -e "${BLUE}Build script for the P Compiler${NOCOLOR}"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -c, --config <config>  Build configuration (Debug|Release, default: Release)"
    echo "  -v, --verbose          Display detailed build output"
    echo "  -h, --help             Show this help message"
    echo "  --skip-submodules      Skip updating git submodules"
    echo "  --install              Install P as a global dotnet tool after building"
    echo "  --version <version>    Specify version when installing (default: 1.0.0-local)"
    echo
    exit 1
}


# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG="$2"
            if [[ "$CONFIG" != "Debug" && "$CONFIG" != "Release" ]]; then
                echo -e "${RED}ERROR: Invalid configuration: $CONFIG. Must be Debug or Release.${NOCOLOR}" >&2
                exit 1
            fi
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="n"
            shift
            ;;
        -h|--help)
            usage
            ;;
        --skip-submodules)
            UPDATE_SUBMODULES=false
            shift
            ;;
        --install)
            INSTALL_TOOL=true
            shift
            ;;
        --version)
            TOOL_VERSION="$2"
            shift 2
            ;;
        *)
            error_exit "Unknown option: $1"
            ;;
    esac
done

# Check prerequisites
if ! command_exists dotnet; then
    error_exit "dotnet is not installed. Please install .NET SDK."
fi

if ! command_exists git; then
    error_exit "git is not installed. Please install git."
fi

# Get script directory and navigate to project root
BLD_PATH=$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")
pushd "$BLD_PATH/.." > /dev/null || error_exit "Failed to navigate to project root directory"

# Set the binary path based on configuration
BINARY_PATH="${PWD}/Bld/Drops/${CONFIG}/Binaries/net8.0/p.dll"

# Initialize submodules if needed
if [ "$UPDATE_SUBMODULES" = true ]; then
    echo -e "${ORANGE} ---- Fetching git submodules ----${NOCOLOR}"
    git submodule update --init --recursive || error_exit "Failed to update git submodules"
else
    echo -e "${BLUE} ---- Skipping git submodules update ----${NOCOLOR}"
fi

echo -e "${ORANGE} ---- Building the PCompiler (${CONFIG} mode) ----${NOCOLOR}"

# Run the build with proper error handling
if [ "$VERBOSE" = "n" ]; then
    dotnet build -c "$CONFIG" -v n || error_exit "Build failed"
else
    dotnet build -c "$CONFIG" -v q || error_exit "Build failed"
fi

# Check if the binary exists
if [ -f "$BINARY_PATH" ]; then
    echo -e "${GREEN} ----------------------------------${NOCOLOR}"
    echo -e "${GREEN} P Compiler successfully built!${NOCOLOR}"
    echo -e "${GREEN} ----------------------------------${NOCOLOR}"
    echo -e "${GREEN} P Compiler located at:${NOCOLOR}"
    echo -e "${ORANGE} ${BINARY_PATH}${NOCOLOR}"
    echo -e "${GREEN} ----------------------------------${NOCOLOR}"
    echo -e "${GREEN} Recommended shortcuts:${NOCOLOR}"
    echo -e "${ORANGE} alias pl='dotnet ${BINARY_PATH}'${NOCOLOR}"
    echo -e "${GREEN} ----------------------------------${NOCOLOR}"
else
    error_exit "Build completed but binary not found at expected location: ${BINARY_PATH}"
fi


echo -e "${GREEN}Build completed successfully!${NOCOLOR}"
exit 0
