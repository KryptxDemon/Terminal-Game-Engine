#!/bin/bash
# Master Menu
while true; do
    # Clear the screen
    clear
    
    echo "================================================="
    echo "            📖 STORY GAME STUDIO 📖            "
    echo "================================================="
    echo "  1. ✨ Create a New Game"
    echo "  2. 📂 List Available Games"
    echo "  3. ➕ Add a New Scene"
    echo "  4. 📝 Edit an Existing Scene"
    echo "  5. ❌ Delete a Scene"
    echo "  6. 🔍 Validate Game"
    echo "  7. 🚪 Quit Studio"
    echo "================================================="
    
    # user input
    read -p "Select an option (1-7): " choice
    echo ""

    case "$choice" in
        1)
            if [ -f "create_game.sh" ]; then
                bash create_game.sh
            else
                echo "Error: create_game.sh not found in this folder!"
            fi
            ;;
        2)
            if [ -f "list_games.sh" ]; then
                bash list_games.sh
            else
                echo "Error: list_games.sh not found!"
            fi
            ;;
        3)
            if [ -f "add_scene.sh" ]; then
                bash add_scene.sh
            else
                echo "Error: add_scene.sh not found!"
            fi
            ;;
        4)
            if [ -f "edit_scene.sh" ]; then
                bash edit_scene.sh
            else
                echo "Error: edit_scene.sh not found!"
            fi
            ;;
        5)
            if [ -f "delete_scene.sh" ]; then
                bash delete_scene.sh
            else
                echo "Error: delete_scene.sh not found!"
            fi
            ;;
        6)
            if [ -f "validate_game.sh" ]; then
                bash validate_game.sh
            else
                echo "Error: validate_game.sh not found!"
            fi
            ;;
        7)
            echo "Exiting Story Game Studio. Goodbye!"
            break
            ;;
        *)
            echo "Invalid option! Please type a number between 1 and 7."
            ;;
    esac

    echo ""

    read -p "Press [Enter] to return to the Main Menu..."
done
