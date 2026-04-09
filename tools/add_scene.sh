#!/bin/bash

BASE_GAMES_DIR="../games"

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

add_choice_line() {
    local choice_number="$1"

    echo
    echo "Choice $choice_number"
    read -p "Choice text: " choice_text
    read -p "Target scene ID: " target_scene

    if [ -z "$choice_text" ] || [ -z "$target_scene" ]; then
        echo "Choice text and target scene are required."
        return 1
    fi

    echo
    echo "Effect examples:"
    echo "  gold:+10"
    echo "  health:-20"
    echo "  reputation:+1"
    echo "  item:+key"
    echo "  item:-key"
    echo "  random_treasure:50"
    echo "  Multiple effects: gold:+10,item:+key"
    read -p "Effects (optional): " effects

    echo
    echo "Requirement examples:"
    echo "  requires:item:key"
    echo "  requires:gold:10"
    echo "  requires:health:50"
    echo "  requires:reputation:2"
    read -p "Requirement (optional): " requirement

    line="CHOICE$choice_number=$choice_text|$target_scene"

    if [ -n "$effects" ]; then
        line="$line|$effects"
    fi

    if [ -n "$requirement" ]; then
        line="$line|$requirement"
    fi

    echo "$line" >> "$SCENE_FILE"
}

choose_game

SCENES_DIR="$GAME_DIR/scenes"

echo
read -p "Enter new scene ID (example: scene_4 or castle_gate): " scene_id

if [ -z "$scene_id" ]; then
    echo "Scene ID cannot be empty."
    exit 1
fi

SCENE_FILE="$SCENES_DIR/$scene_id.txt"

if [ -f "$SCENE_FILE" ]; then
    echo "Scene already exists: $SCENE_FILE"
    exit 1
fi

echo
read -p "Enter scene text: " scene_text

if [ -z "$scene_text" ]; then
    echo "Scene text cannot be empty."
    exit 1
fi

echo
read -p "Is this an ending scene? (y/n): " is_end

{
    echo "ID=$scene_id"
    echo "TEXT=$scene_text"
} > "$SCENE_FILE"

if [[ "$is_end" == "y" || "$is_end" == "Y" ]]; then
    echo "END=1" >> "$SCENE_FILE"
    echo
    echo "Ending scene created successfully: $SCENE_FILE"
    exit 0
fi

echo
read -p "How many choices do you want to add? " choice_count

if ! [[ "$choice_count" =~ ^[0-9]+$ ]]; then
    echo "Invalid number."
    rm -f "$SCENE_FILE"
    exit 1
fi

if [ "$choice_count" -le 0 ]; then
    echo "A non-ending scene must have at least 1 choice."
    rm -f "$SCENE_FILE"
    exit 1
fi

for ((i=1; i<=choice_count; i++)); do
    add_choice_line "$i" || {
        echo "Failed to add choice. Removing incomplete scene."
        rm -f "$SCENE_FILE"
        exit 1
    }
done

echo
echo "Scene created successfully: $SCENE_FILE"
