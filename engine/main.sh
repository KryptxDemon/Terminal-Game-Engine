#!/bin/bash

BASE_GAMES_DIR="games"
LOG_FILE="logs/game.log"
SAVE_DIR="saves"

# Selected game info
GAME_DIR=""
CONFIG_FILE=""
GAME_NAME=""
START_SCENE=""

# Player state
CURRENT_SCENE=""
HEALTH=100
GOLD=0
REPUTATION=0
INVENTORY=""
CURRENT_SAVE_SLOT=""

# Colors
if command -v tput >/dev/null 2>&1; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    RESET=$(tput sgr0)
else
    BOLD=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    RESET=""
fi

log_event() {
    local message="$1"
    mkdir -p logs
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

print_header() {
    clear
    echo "${BOLD}${CYAN}==============================${RESET}"
    echo "${BOLD}${CYAN}        $1${RESET}"
    echo "${BOLD}${CYAN}==============================${RESET}"
    echo
}

pause_screen() {
    read -p "Press Enter to continue..."
}

has_item() {
    local item="$1"
    [[ ",$INVENTORY," == *",$item,"* ]]
}

add_item() {
    local item="$1"

    if has_item "$item"; then
        return
    fi

    if [ -z "$INVENTORY" ]; then
        INVENTORY="$item"
    else
        INVENTORY="$INVENTORY,$item"
    fi

    log_event "Item added: $item"
}

remove_item() {
    local item="$1"

    if ! has_item "$item"; then
        return
    fi

    local new_inventory=""
    IFS=',' read -ra items <<< "$INVENTORY"

    for existing_item in "${items[@]}"; do
        if [ "$existing_item" != "$item" ] && [ -n "$existing_item" ]; then
            if [ -z "$new_inventory" ]; then
                new_inventory="$existing_item"
            else
                new_inventory="$new_inventory,$existing_item"
            fi
        fi
    done

    INVENTORY="$new_inventory"
    log_event "Item removed: $item"
}

apply_effects() {
    local effects="$1"
    [ -z "$effects" ] && return

    IFS=',' read -ra effect_array <<< "$effects"

    for effect in "${effect_array[@]}"; do
        if [[ "$effect" == health:* ]]; then
            value="${effect#health:}"
            HEALTH=$((HEALTH + value))
            log_event "Health changed by $value. New health: $HEALTH"

        elif [[ "$effect" == gold:* ]]; then
            value="${effect#gold:}"
            GOLD=$((GOLD + value))
            log_event "Gold changed by $value. New gold: $GOLD"

        elif [[ "$effect" == reputation:* ]]; then
            value="${effect#reputation:}"
            REPUTATION=$((REPUTATION + value))
            log_event "Reputation changed by $value. New reputation: $REPUTATION"

        elif [[ "$effect" == item:+* ]]; then
            item="${effect#item:+}"
            add_item "$item"

        elif [[ "$effect" == item:-* ]]; then
            item="${effect#item:-}"
            remove_item "$item"

        elif [[ "$effect" == random_treasure:* ]]; then
            max_value="${effect#random_treasure:}"
            if [[ "$max_value" =~ ^[0-9]+$ ]] && [ "$max_value" -gt 0 ]; then
                treasure=$((RANDOM % max_value + 1))
                GOLD=$((GOLD + treasure))
                echo
                echo "${YELLOW}You found random treasure: +$treasure gold!${RESET}"
                log_event "Random treasure awarded: +$treasure gold"
            fi
        fi
    done
}

requirement_met() {
    local requirement="$1"
    [ -z "$requirement" ] && return 0

    if [[ "$requirement" == requires:item:* ]]; then
        needed_item="${requirement#requires:item:}"
        has_item "$needed_item"
        return $?
    fi

    if [[ "$requirement" == requires:gold:* ]]; then
        needed_gold="${requirement#requires:gold:}"
        [[ "$needed_gold" =~ ^-?[0-9]+$ ]] || return 1
        [ "$GOLD" -ge "$needed_gold" ]
        return $?
    fi

    if [[ "$requirement" == requires:health:* ]]; then
        needed_health="${requirement#requires:health:}"
        [[ "$needed_health" =~ ^-?[0-9]+$ ]] || return 1
        [ "$HEALTH" -ge "$needed_health" ]
        return $?
    fi

    if [[ "$requirement" == requires:reputation:* ]]; then
        needed_rep="${requirement#requires:reputation:}"
        [[ "$needed_rep" =~ ^-?[0-9]+$ ]] || return 1
        [ "$REPUTATION" -ge "$needed_rep" ]
        return $?
    fi

    return 0
}

choose_game() {
    mapfile -t game_dirs < <(find "$BASE_GAMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

    if [ "${#game_dirs[@]}" -eq 0 ]; then
        echo "${RED}No games found in $BASE_GAMES_DIR${RESET}"
        exit 1
    fi

    while true; do
        print_header "SELECT A GAME"

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
            echo "${RED}Invalid input.${RESET}"
            pause_screen
            continue
        fi

        if [ "$game_choice" -lt 1 ] || [ "$game_choice" -gt "${#game_dirs[@]}" ]; then
            echo "${RED}Invalid game selection.${RESET}"
            pause_screen
            continue
        fi

        index=$((game_choice - 1))
        GAME_DIR="${game_dirs[$index]}"
        CONFIG_FILE="$GAME_DIR/config.txt"

        if [ ! -f "$CONFIG_FILE" ]; then
            echo "${RED}Selected game has no config.txt${RESET}"
            pause_screen
            continue
        fi

        GAME_NAME=$(grep '^GAME_NAME=' "$CONFIG_FILE" | cut -d'=' -f2-)
        START_SCENE=$(grep '^START_SCENE=' "$CONFIG_FILE" | cut -d'=' -f2-)

        if [ -z "$START_SCENE" ]; then
            echo "${RED}Selected game config is invalid.${RESET}"
            pause_screen
            continue
        fi

        log_event "Game selected: $GAME_DIR"
        break
    done
}

choose_save_slot() {
    mkdir -p "$SAVE_DIR"

    while true; do
        print_header "SAVE SLOTS"
        echo "1. slot1"
        echo "2. slot2"
        echo "3. slot3"
        echo
        read -p "Choose a save slot: " slot_choice

        case "$slot_choice" in
            1) CURRENT_SAVE_SLOT="slot1" ; break ;;
            2) CURRENT_SAVE_SLOT="slot2" ; break ;;
            3) CURRENT_SAVE_SLOT="slot3" ; break ;;
            *)
                echo "${RED}Invalid slot.${RESET}"
                pause_screen
                ;;
        esac
    done
}

save_game() {
    choose_save_slot

    mkdir -p "$SAVE_DIR"
    local save_file="$SAVE_DIR/${CURRENT_SAVE_SLOT}.txt"

    if [ -f "$save_file" ]; then
        cp "$save_file" "$save_file.bak_$(date '+%Y%m%d_%H%M%S')"
        log_event "Backup created before overwrite: $save_file"
    fi

    {
        echo "GAME_DIR=$GAME_DIR"
        echo "CURRENT_SCENE=$CURRENT_SCENE"
        echo "HEALTH=$HEALTH"
        echo "GOLD=$GOLD"
        echo "REPUTATION=$REPUTATION"
        echo "INVENTORY=$INVENTORY"
    } > "$save_file"

    log_event "Game saved to $CURRENT_SAVE_SLOT at scene: $CURRENT_SCENE for game: $GAME_DIR"
    echo
    echo "${GREEN}Game saved successfully in $CURRENT_SAVE_SLOT.${RESET}"
    echo
    pause_screen
}

load_game() {
    mkdir -p "$SAVE_DIR"

    while true; do
        print_header "LOAD GAME"
        for slot in slot1 slot2 slot3; do
            save_file="$SAVE_DIR/${slot}.txt"
            if [ -f "$save_file" ]; then
                slot_game=$(grep '^GAME_DIR=' "$save_file" | cut -d'=' -f2-)
                slot_scene=$(grep '^CURRENT_SCENE=' "$save_file" | cut -d'=' -f2-)
                echo "$slot - Saved | Game: ${slot_game:-Unknown} | Scene: ${slot_scene:-Unknown}"
            else
                echo "$slot - Empty"
            fi
        done
        echo
        read -p "Enter slot name to load (slot1/slot2/slot3) or M for menu: " slot_name

        if [[ "$slot_name" == "M" || "$slot_name" == "m" ]]; then
            return 1
        fi

        case "$slot_name" in
            slot1|slot2|slot3) ;;
            *)
                echo "${RED}Invalid slot name.${RESET}"
                pause_screen
                continue
                ;;
        esac

        local save_file="$SAVE_DIR/${slot_name}.txt"

        if [ ! -f "$save_file" ]; then
            echo
            echo "${RED}No save file found in $slot_name.${RESET}"
            echo
            pause_screen
            return 1
        fi

        CURRENT_SAVE_SLOT="$slot_name"
        GAME_DIR=$(grep '^GAME_DIR=' "$save_file" | cut -d'=' -f2-)
        CURRENT_SCENE=$(grep '^CURRENT_SCENE=' "$save_file" | cut -d'=' -f2-)
        HEALTH=$(grep '^HEALTH=' "$save_file" | cut -d'=' -f2-)
        GOLD=$(grep '^GOLD=' "$save_file" | cut -d'=' -f2-)
        REPUTATION=$(grep '^REPUTATION=' "$save_file" | cut -d'=' -f2-)
        INVENTORY=$(grep '^INVENTORY=' "$save_file" | cut -d'=' -f2-)

        if [ -z "$GAME_DIR" ] || [ -z "$CURRENT_SCENE" ]; then
            echo
            echo "${RED}Save file is corrupted.${RESET}"
            log_event "ERROR: Save file corrupted in $slot_name"
            pause_screen
            return 1
        fi

        CONFIG_FILE="$GAME_DIR/config.txt"

        if [ ! -f "$CONFIG_FILE" ]; then
            echo
            echo "${RED}Saved game directory is missing.${RESET}"
            log_event "ERROR: Saved game config missing: $CONFIG_FILE"
            pause_screen
            return 1
        fi

        GAME_NAME=$(grep '^GAME_NAME=' "$CONFIG_FILE" | cut -d'=' -f2-)
        START_SCENE=$(grep '^START_SCENE=' "$CONFIG_FILE" | cut -d'=' -f2-)

        log_event "Game loaded from $slot_name. Game: $GAME_DIR | Scene: $CURRENT_SCENE"
        return 0
    done
}

start_new_game() {
    CURRENT_SCENE="$START_SCENE"
    HEALTH=100
    GOLD=0
    REPUTATION=0
    INVENTORY=""
    CURRENT_SAVE_SLOT=""
    log_event "New game started for: $GAME_DIR"
}

show_main_menu() {
    while true; do
        print_header "CHOICE GAME ENGINE"
        echo "Selected Game: ${GAME_NAME:-None}"
        echo
        echo "1. Select Game"
        echo "2. Start New Game"
        echo "3. Load Game"
        echo "4. Exit"
        echo

        read -p "Enter your choice: " menu_choice

        case "$menu_choice" in
            1)
                choose_game
                ;;
            2)
                if [ -z "$GAME_DIR" ]; then
                    echo
                    echo "${YELLOW}Please select a game first.${RESET}"
                    pause_screen
                else
                    start_new_game
                    break
                fi
                ;;
            3)
                if load_game; then
                    break
                fi
                ;;
            4)
                echo "Goodbye."
                exit 0
                ;;
            *)
                echo
                echo "${RED}Invalid choice.${RESET}"
                pause_screen
                ;;
        esac
    done
}

mkdir -p logs
mkdir -p "$SAVE_DIR"

log_event "Engine launched."

while true; do
    show_main_menu

    while true; do
        SCENE_FILE="$GAME_DIR/scenes/$CURRENT_SCENE.txt"

        if [ ! -f "$SCENE_FILE" ]; then
            echo "${RED}Error: scene file not found: $SCENE_FILE${RESET}"
            log_event "ERROR: Missing scene file: $SCENE_FILE"
            exit 1
        fi

        SCENE_ID=$(grep '^ID=' "$SCENE_FILE" | cut -d'=' -f2-)
        SCENE_TEXT=$(grep '^TEXT=' "$SCENE_FILE" | cut -d'=' -f2-)
        END_FLAG=$(grep '^END=' "$SCENE_FILE" | cut -d'=' -f2-)

        print_header "$GAME_NAME"
        echo "${BOLD}Health:${RESET} $HEALTH | ${BOLD}Gold:${RESET} $GOLD | ${BOLD}Reputation:${RESET} $REPUTATION"
        echo "${BOLD}Inventory:${RESET} ${INVENTORY:-Empty}"
        echo
        echo "${MAGENTA}Scene:${RESET} $SCENE_ID"
        echo
        echo "$SCENE_TEXT"
        echo

        log_event "Loaded scene: $SCENE_ID"

        if [ "$HEALTH" -le 0 ]; then
            echo "${RED}You have no health left. Game over.${RESET}"
            log_event "Player died due to zero or negative health."
            echo
            exit 0
        fi

        if [ "$END_FLAG" = "1" ]; then
            echo "${GREEN}===== THE END =====${RESET}"
            echo
            log_event "Reached ending: $SCENE_ID"
            echo "1. Return to Main Menu"
            echo "2. Exit"
            echo

            read -p "Enter your choice: " end_choice
            case "$end_choice" in
                1) break ;;
                *) log_event "Game ended by user."; exit 0 ;;
            esac
        fi

        unset choice_texts
        unset choice_targets
        unset choice_effects
        unset choice_requirements

        declare -a choice_texts
        declare -a choice_targets
        declare -a choice_effects
        declare -a choice_requirements

        choice_count=0

        while IFS= read -r line; do
            if [[ "$line" == CHOICE* ]]; then
                choice_data="${line#*=}"
                IFS='|' read -r choice_text choice_target extra1 extra2 <<< "$choice_data"

                requirement=""
                effects=""

                for extra in "$extra1" "$extra2"; do
                    if [[ "$extra" == requires:* ]]; then
                        requirement="$extra"
                    elif [ -n "$extra" ]; then
                        effects="$extra"
                    fi
                done

                if requirement_met "$requirement"; then
                    choice_texts[$choice_count]="$choice_text"
                    choice_targets[$choice_count]="$choice_target"
                    choice_effects[$choice_count]="$effects"
                    choice_requirements[$choice_count]="$requirement"
                    ((choice_count++))
                fi
            fi
        done < "$SCENE_FILE"

        if [ "$choice_count" -eq 0 ]; then
            echo "${RED}Error: no available choices found in scene $SCENE_ID${RESET}"
            log_event "ERROR: No available choices found in scene $SCENE_ID"
            exit 1
        fi

        echo "${BOLD}Choices:${RESET}"
        for ((i=0; i<choice_count; i++)); do
            echo "$((i+1)). ${choice_texts[$i]}"
        done
        echo
        echo "S. Save Game"
        echo "M. Main Menu"
        echo

        while true; do
            read -p "Enter your choice: " user_choice

            if [[ "$user_choice" == "S" || "$user_choice" == "s" ]]; then
                save_game
                break
            fi

            if [[ "$user_choice" == "M" || "$user_choice" == "m" ]]; then
                log_event "Returned to main menu from scene: $SCENE_ID"
                break 2
            fi

            if ! [[ "$user_choice" =~ ^[0-9]+$ ]]; then
                echo "${RED}Invalid input. Please enter a number, S, or M.${RESET}"
                log_event "Invalid input entered: $user_choice"
                continue
            fi

            if [ "$user_choice" -lt 1 ] || [ "$user_choice" -gt "$choice_count" ]; then
                echo "${RED}Invalid choice. Please choose a valid option.${RESET}"
                log_event "Out-of-range choice entered: $user_choice in scene $SCENE_ID"
                continue
            fi

            next_index=$((user_choice - 1))
            selected_text="${choice_texts[$next_index]}"
            next_scene="${choice_targets[$next_index]}"
            selected_effects="${choice_effects[$next_index]}"

            log_event "Player selected option $user_choice: $selected_text"
            apply_effects "$selected_effects"
            log_event "Scene transition: $SCENE_ID -> $next_scene"

            CURRENT_SCENE="$next_scene"
            break
        done
    done
done
