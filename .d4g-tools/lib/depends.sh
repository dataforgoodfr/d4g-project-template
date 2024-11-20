#!/usr/bin/env bash
# Dependencies used by d4g-tools
set -Eeuo pipefail

# if ! command -v brew &>/dev/null; then
# echo "Installing Homebrew 'OS: $OSTYPE'"
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Script to recognize OS and install Homebrew if it doesn't exist
# if [[ "$OSTYPE" == "linux-gnu"* ]]; then
#     # Linux or WSL
#     # shellcheck disable=SC2016
#     echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>/home/"$USER"/.profile
#     eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# fi
# fi

# Install crudini to simply read ini files
# if ! command -v crudini &>/dev/null; then
#     brew install crudini
# fi

# Install gum to format messages and more
# sudo mkdir -p /etc/apt/keyrings
# curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
# echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
# sudo apt install gum

# Start by making sure node is installed
# we won't install because the user might have strong opinions about how to install node
if ! command -v node &>/dev/null; then
    error "Please install node >=18 before running this script."
    exit 1
fi
# Make sure node version is >18
NODE_VERSION=$(node -v)
if [ "$(echo "$NODE_VERSION" | cut -c 2-3)" -lt 18 ]; then
    error "Please install node version 18 or higher before running this script."
    exit 1
fi

# TODO brew??
# Install brew if not installed.
# We will use brew to install dependencies on macOS and linux
if ! command -v brew &>/dev/null; then
    error "Please install brew before running this script. Brew is compatible with macOS, linux, and WSL2 (https://docs.brew.sh/Homebrew-on-Linux)."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # exit 1
fi

# # Technically bitwarden-cli is available on brew,
# # but it still depends on node, so we will install it using npm.
# if ! command -v bw &>/dev/null; then
#     info "Installing bw cli"
#     npm install -g @bitwarden/cli
# fi

# TODO lefthook??
for package in jq gum lefthook; do
    if ! command -v $package &>/dev/null; then
        info "Installing $package"
        brew install $package
    else
        success "$package is already installed"
    fi
done

# Install curl
if ! command -v curl &>/dev/null; then
    if ! command -v brew &>/dev/null; then
        sudo apt install -y curl &>/dev/null
    else
        brew install curl &>/dev/null
    fi
fi

# Install gnuplot
if ! command -v gnuplot &>/dev/null; then
    if ! command -v brew &>/dev/null; then
        sudo apt install -y gnuplot &>/dev/null
    else
        brew install gnuplot &>/dev/null
    fi
fi

# TODO loop between messages (info, debug,...) and dependencies => to discuss with pg
# info "Installed all dependencies, preparing repo."

# # Install the pre-commit hooks
# lefthook install

# # Prompt user to create .env
# gum confirm "Would you like to create the .env file from .env.dist ? This *WILL* overwrite your existing .env file." && cp .env.dist .env

# tfenv install
# tfenv use

# # All done.
# success "All done ! Please refer to the README.md for further instructions."
