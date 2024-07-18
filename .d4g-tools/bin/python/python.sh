#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
set -Eeuo pipefail

# IMPORTANT AND NECESSARY: Load common functions
source "$LIB_DIR"/common.sh

# TODO INSTALL PYTHON ?

# Check if Poetry is installed
if command_exists poetry && poetry --version &>/dev/null; then
    info "Poetry is already installed. Version: $(poetry --version)"
else
    info "Poetry is not installed. Installing now..."

    # Install Poetry
    curl -sSL https://install.python-poetry.org | python3 -

    # Add poetry to PATH
    # shellcheck disable=SC2016
    # TODO: Add poetry to PATH . Check compatibility with macos, linux and wsl2!
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc
    # shellcheck disable=SC1090
    source ~/.bashrc

    echo "Poetry has been installed."
fi

echo "Configuring Poetry to use virtual environment in project directory..."

# Configure Poetry to use a virtual environment in the project
poetry config virtualenvs.in-project true

echo "Poetry is now configured to use a virtual environment in the project directory."

# Check if the virtual environment exists in the project directory
if [ -d ".venv" ]; then
    echo "Virtual environment in project directory exists."
fi

# Analyze project content and create pyproject.toml file if not exists
if [ ! -f pyproject.toml ]; then
    echo "Creating pyproject.toml file..."
    # TODO pass the project name, authors and some other option as argument (see d4g.ini)
    poetry init #--no-interaction
else
    echo "pyproject.toml file already exists. Skipping initialization."
fi

# Install project dependencies
echo "Installing project dependencies..."
poetry install

echo "Script execution complete."
