#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_GAMES_DIR="$SCRIPT_DIR/../games"

echo "=============================="
echo "       CREATE NEW GAME"
echo "=============================="
echo

read -p "Enter folder name for the new game (example: mystery_game): " folder_name

if [ -z "$folder_name" ]; then
    echo "Error: folder name cannot be empty."
    exit 1
fi

GAME_DIR="$BASE_GAMES_DIR/$folder_name"

if [ -d "$GAME_DIR" ]; then
    echo "Error: a game with that folder name already exists."
    exit 1
fi

read -p "Enter display name for the game: " game_name

if [ -z "$game_name" ]; then
    echo "Error: game name cannot be empty."
    exit 1
fi

mkdir -p "$GAME_DIR/scenes"

CONFIG_FILE="$GAME_DIR/config.txt"

read -p "Enter the starting scene ID (example: intro): " start_scene

if [ -z "$start_scene" ]; then
    echo "Error: starting scene ID cannot be empty."
    exit 1
fi

cat > "$CONFIG_FILE" <<EOF
GAME_NAME=$game_name
START_SCENE=$start_scene
EOF

echo
echo "Game created successfully."
echo
echo "Created:"
echo "  $CONFIG_FILE"
echo "  $GAME_DIR/scenes/"
echo
echo "Create new scenes by /tools/add_scene.sh"