#!/bin/bash

BASE_GAMES_DIR="games"

error_count=0
warning_count=0

choose_game() {
    mapfile -t game_dirs < <(find "$BASE_GAMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

    if [ "${#game_dirs[@]}" -eq 0 ]; then
        echo "No games found."
        exit 1
    fi

    echo "=============================="
    echo "       VALIDATE GAME"
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

is_integer() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

validate_effects() {
    local scene_name="$1"
    local effects="$2"

    [ -z "$effects" ] && return

    IFS=',' read -ra effect_array <<< "$effects"

    for effect in "${effect_array[@]}"; do
        if [[ "$effect" == health:* ]]; then
            value="${effect#health:}"
            if ! is_integer "$value"; then
                echo "ERROR: $scene_name has invalid health effect: $effect"
                ((error_count++))
            fi

        elif [[ "$effect" == gold:* ]]; then
            value="${effect#gold:}"
            if ! is_integer "$value"; then
                echo "ERROR: $scene_name has invalid gold effect: $effect"
                ((error_count++))
            fi

        elif [[ "$effect" == reputation:* ]]; then
            value="${effect#reputation:}"
            if ! is_integer "$value"; then
                echo "ERROR: $scene_name has invalid reputation effect: $effect"
                ((error_count++))
            fi

        elif [[ "$effect" == item:+* ]]; then
            item_name="${effect#item:+}"
            if [ -z "$item_name" ]; then
                echo "ERROR: $scene_name has invalid item add effect: $effect"
                ((error_count++))
            fi

        elif [[ "$effect" == item:-* ]]; then
            item_name="${effect#item:-}"
            if [ -z "$item_name" ]; then
                echo "ERROR: $scene_name has invalid item remove effect: $effect"
                ((error_count++))
            fi

        elif [[ "$effect" == random_treasure:* ]]; then
            max_value="${effect#random_treasure:}"
            if ! [[ "$max_value" =~ ^[0-9]+$ ]] || [ "$max_value" -le 0 ]; then
                echo "ERROR: $scene_name has invalid random_treasure effect: $effect"
                ((error_count++))
            fi

        else
            echo "WARNING: $scene_name has unknown effect format: $effect"
            ((warning_count++))
        fi
    done
}

validate_requirement() {
    local scene_name="$1"
    local requirement="$2"

    [ -z "$requirement" ] && return

    if [[ "$requirement" == requires:item:* ]]; then
        item_name="${requirement#requires:item:}"
        if [ -z "$item_name" ]; then
            echo "ERROR: $scene_name has invalid item requirement: $requirement"
            ((error_count++))
        fi
        return
    fi

    if [[ "$requirement" == requires:gold:* ]]; then
        value="${requirement#requires:gold:}"
        if ! is_integer "$value"; then
            echo "ERROR: $scene_name has invalid gold requirement: $requirement"
            ((error_count++))
        fi
        return
    fi

    if [[ "$requirement" == requires:health:* ]]; then
        value="${requirement#requires:health:}"
        if ! is_integer "$value"; then
            echo "ERROR: $scene_name has invalid health requirement: $requirement"
            ((error_count++))
        fi
        return
    fi

    if [[ "$requirement" == requires:reputation:* ]]; then
        value="${requirement#requires:reputation:}"
        if ! is_integer "$value"; then
            echo "ERROR: $scene_name has invalid reputation requirement: $requirement"
            ((error_count++))
        fi
        return
    fi

    echo "WARNING: $scene_name has unknown requirement format: $requirement"
    ((warning_count++))
}

check_config() {
    CONFIG_FILE="$GAME_DIR/config.txt"
    SCENES_DIR="$GAME_DIR/scenes"

    echo
    echo "Checking game: $GAME_DIR"
    echo

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ERROR: Missing config.txt"
        ((error_count++))
        return
    else
        echo "OK: config.txt found"
    fi

    GAME_NAME=$(grep '^GAME_NAME=' "$CONFIG_FILE" | cut -d'=' -f2-)
    START_SCENE=$(grep '^START_SCENE=' "$CONFIG_FILE" | cut -d'=' -f2-)

    if [ -z "$GAME_NAME" ]; then
        echo "ERROR: GAME_NAME missing in config.txt"
        ((error_count++))
    else
        echo "OK: GAME_NAME = $GAME_NAME"
    fi

    if [ -z "$START_SCENE" ]; then
        echo "ERROR: START_SCENE missing in config.txt"
        ((error_count++))
    else
        echo "OK: START_SCENE = $START_SCENE"
    fi

    if [ -n "$START_SCENE" ] && [ ! -f "$SCENES_DIR/$START_SCENE.txt" ]; then
        echo "ERROR: Start scene file missing: $SCENES_DIR/$START_SCENE.txt"
        ((error_count++))
    elif [ -n "$START_SCENE" ]; then
        echo "OK: Start scene file exists"
    fi
}

check_scenes() {
    SCENES_DIR="$GAME_DIR/scenes"

    echo
    echo "Checking scene files..."
    echo

    if [ ! -d "$SCENES_DIR" ]; then
        echo "ERROR: scenes directory missing"
        ((error_count++))
        return
    fi

    found_any=0

    for scene_file in "$SCENES_DIR"/*.txt; do
        [ -e "$scene_file" ] || continue
        found_any=1

        scene_name=$(basename "$scene_file")
        scene_id=$(grep '^ID=' "$scene_file" | cut -d'=' -f2-)
        scene_text=$(grep '^TEXT=' "$scene_file" | cut -d'=' -f2-)
        end_flag=$(grep '^END=' "$scene_file" | cut -d'=' -f2-)

        if [ -z "$scene_id" ]; then
            echo "ERROR: $scene_name has no ID"
            ((error_count++))
        else
            echo "OK: $scene_name has ID=$scene_id"
        fi

        if [ -z "$scene_text" ]; then
            echo "ERROR: $scene_name has no TEXT"
            ((error_count++))
        else
            echo "OK: $scene_name has TEXT"
        fi

        choice_found=0

        while IFS= read -r line; do
            if [[ "$line" == CHOICE* ]]; then
                choice_found=1
                choice_data="${line#*=}"
                IFS='|' read -r choice_text target_scene extra1 extra2 <<< "$choice_data"

                if [ -z "$choice_text" ]; then
                    echo "ERROR: $scene_name has empty choice text"
                    ((error_count++))
                fi

                if [ -z "$target_scene" ]; then
                    echo "ERROR: $scene_name has missing target scene"
                    ((error_count++))
                elif [ ! -f "$SCENES_DIR/$target_scene.txt" ]; then
                    echo "ERROR: $scene_name points to missing target: $target_scene.txt"
                    ((error_count++))
                else
                    echo "OK: $scene_name choice target exists -> $target_scene.txt"
                fi

                effects=""
                requirement=""

                for extra in "$extra1" "$extra2"; do
                    if [[ "$extra" == requires:* ]]; then
                        requirement="$extra"
                    elif [ -n "$extra" ]; then
                        effects="$extra"
                    fi
                done

                validate_effects "$scene_name" "$effects"
                validate_requirement "$scene_name" "$requirement"
            fi
        done < "$scene_file"

        if [ "$end_flag" = "1" ]; then
            echo "OK: $scene_name is an ending scene"
        elif [ "$choice_found" -eq 0 ]; then
            echo "ERROR: $scene_name is not an ending and has no choices"
            ((error_count++))
        fi

        echo
    done

    if [ "$found_any" -eq 0 ]; then
        echo "ERROR: No scene files found."
        ((error_count++))
    fi
}

check_unreachable_scenes() {
    SCENES_DIR="$GAME_DIR/scenes"

    echo "Checking for possibly unreachable scenes..."
    echo

    declare -A referenced
    referenced["$START_SCENE"]=1

    for scene_file in "$SCENES_DIR"/*.txt; do
        [ -e "$scene_file" ] || continue

        while IFS= read -r line; do
            if [[ "$line" == CHOICE* ]]; then
                choice_data="${line#*=}"
                IFS='|' read -r choice_text target_scene extra1 extra2 <<< "$choice_data"
                if [ -n "$target_scene" ]; then
                    referenced["$target_scene"]=1
                fi
            fi
        done < "$scene_file"
    done

    for scene_file in "$SCENES_DIR"/*.txt; do
        [ -e "$scene_file" ] || continue
        scene_id=$(grep '^ID=' "$scene_file" | cut -d'=' -f2-)
        scene_name=$(basename "$scene_file")

        if [ -n "$scene_id" ] && [ -z "${referenced[$scene_id]}" ]; then
            echo "WARNING: $scene_name may be unreachable from the start scene"
            ((warning_count++))
        fi
    done

    echo
}

choose_game
check_config
check_scenes
check_unreachable_scenes

if [ "$error_count" -eq 0 ]; then
    echo "Validation successful. No errors found."
else
    echo "Validation finished with $error_count error(s)."
fi

if [ "$warning_count" -gt 0 ]; then
    echo "Validation also reported $warning_count warning(s)."
fi
