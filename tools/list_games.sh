#!/bin/bash

BASE_GAMES_DIR="../games"

echo "=============================="
echo "        AVAILABLE GAMES"
echo "=============================="
echo

found=0

for game_dir in "$BASE_GAMES_DIR"/*; do
    [ -d "$game_dir" ] || continue
    found=1

    config_file="$game_dir/config.txt"
    folder_name=$(basename "$game_dir")

    if [ -f "$config_file" ]; then
        game_name=$(grep '^GAME_NAME=' "$config_file" | cut -d'=' -f2-)
        start_scene=$(grep '^START_SCENE=' "$config_file" | cut -d'=' -f2-)
    else
        game_name="(Missing config)"
        start_scene="N/A"
    fi

    scene_dir="$game_dir/scenes"
    scene_count=$(find "$scene_dir" -type f -name "*.txt" 2>/dev/null | wc -l)

    status="OK"
    if [ ! -f "$config_file" ]; then
        status="BROKEN: missing config"
    elif [ -z "$game_name" ] || [ -z "$start_scene" ]; then
        status="BROKEN: incomplete config"
    elif [ ! -f "$scene_dir/$start_scene.txt" ]; then
        status="BROKEN: missing start scene"
    fi

    echo "Folder Name : $folder_name"
    echo "Game Name   : $game_name"
    echo "Start Scene : $start_scene"
    echo "Scene Count : $scene_count"
    echo "Status      : $status"
    echo
done

if [ "$found" -eq 0 ]; then
    echo "No games found."
fi
