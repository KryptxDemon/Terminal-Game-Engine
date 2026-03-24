#!/bin/bash

BASE_GAMES_DIR="games"

choose_game() {
    mapfile -t game_dirs < <(find "$BASE_GAMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

    if [ "${#game_dirs[@]}" -eq 0 ]; then
        echo "No games found."
        exit 1
    fi

    echo "=============================="
    echo "         SELECT GAME"
    echo "=============================="
    echo

    for i in "${!game_dirs[@]}"; do
        config_file="${game_dirs[$i]}/config.txt"
        if [ -f "$config_file" ]; then
            display_name=$(grep '^GAME_NAME=' "$config_file" | cut -d'=' -f2-)
        else
            display_name="(Missing config)"
        fi
        echo "$((i+1)). $(basename "${game_dirs[$i]}") - $display_name"
    done

    echo
    read -p "Choose a game: " game_choice

    if ! [[ "$game_choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input."
        exit 1
    fi

    if [ "$game_choice" -lt 1 ] || [ "$game_choice" -gt "${#game_dirs[@]}" ]; then
        echo "Invalid game selection."
        exit 1
    fi

    index=$((game_choice - 1))
    GAME_DIR="${game_dirs[$index]}"
}

choose_scene() {
    mapfile -t scene_files < <(find "$GAME_DIR/scenes" -maxdepth 1 -type f -name "*.txt" | sort)

    if [ "${#scene_files[@]}" -eq 0 ]; then
        echo "No scenes found."
        exit 1
    fi

    echo
    echo "=============================="
    echo "        SELECT SCENE"
    echo "=============================="
    echo

    for i in "${!scene_files[@]}"; do
        echo "$((i+1)). $(basename "${scene_files[$i]}")"
    done

    echo
    read -p "Choose a scene to delete: " scene_choice

    if ! [[ "$scene_choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input."
        exit 1
    fi

    if [ "$scene_choice" -lt 1 ] || [ "$scene_choice" -gt "${#scene_files[@]}" ]; then
        echo "Invalid scene selection."
        exit 1
    fi

    index=$((scene_choice - 1))
    SCENE_FILE="${scene_files[$index]}"
}

choose_game
choose_scene

echo
echo "Selected file: $SCENE_FILE"
read -p "Are you sure you want to delete this scene? (y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

cp "$SCENE_FILE" "$SCENE_FILE.bak_$(date '+%Y%m%d_%H%M%S')"
rm -f "$SCENE_FILE"

echo "Scene deleted. Backup kept beside the original filename."
