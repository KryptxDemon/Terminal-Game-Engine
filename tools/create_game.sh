#!/bin/bash

BASE_GAMES_DIR="../games"

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
START_SCENE_FILE="$GAME_DIR/scenes/scene_1.txt"

cat > "$CONFIG_FILE" <<EOF
GAME_NAME=$game_name
START_SCENE=scene_1
EOF

cat > "$START_SCENE_FILE" <<EOF
ID=scene_1
TEXT=This is the beginning of your story. Edit this scene to start your adventure.
CHOICE1=Go to a good ending|ending_good
CHOICE2=Go to a bad ending|ending_bad
EOF

cat > "$GAME_DIR/scenes/ending_good.txt" <<EOF
ID=ending_good
TEXT=This is the good ending of your custom game.
END=1
EOF

cat > "$GAME_DIR/scenes/ending_bad.txt" <<EOF
ID=ending_bad
TEXT=This is the bad ending of your custom game.
END=1
EOF

echo
echo "Game created successfully."
echo
echo "Created files:"
echo "  $CONFIG_FILE"
echo "  $START_SCENE_FILE"
echo "  $GAME_DIR/scenes/ending_good.txt"
echo "  $GAME_DIR/scenes/ending_bad.txt"
echo
echo "You can now edit the scene files to build your own story."
