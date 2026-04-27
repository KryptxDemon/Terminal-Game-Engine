SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DB_DIR="$PROJECT_ROOT/database"
USERS_DB="$DB_DIR/users.db"
SAVES_DB="$DB_DIR/saves"

CURRENT_USER=""

ensure_db() {
    mkdir -p "$DB_DIR"
    mkdir -p "$SAVES_DB"
    touch "$USERS_DB"
}

register_user() {
    ensure_db

    clear
    echo "===== REGISTER ====="
    echo

    read -p "Username: " username

    if grep -q "^$username:" "$USERS_DB"; then
        echo "User already exists."
        read -p "Press Enter..."
        return
    fi

    read -s -p "Password: " password
    echo
    read -s -p "Confirm Password: " confirm
    echo

    if [ "$password" != "$confirm" ]; then
        echo "Passwords do not match."
        read -p "Press Enter..."
        return
    fi

    echo "$username:$password" >> "$USERS_DB"
    mkdir -p "$SAVES_DB/$username"

    echo "User created successfully."
    read -p "Press Enter..."
}

login_user() {
    ensure_db

    clear
    echo "===== LOGIN ====="
    echo

    read -p "Username: " username
    read -s -p "Password: " password
    echo

    record=$(grep "^$username:" "$USERS_DB")

    if [ -z "$record" ]; then
        echo "User not found."
        read -p "Press Enter..."
        return 1
    fi

    saved_pass=$(echo "$record" | cut -d':' -f2)

    if [ "$password" != "$saved_pass" ]; then
        echo "Wrong password."
        read -p "Press Enter..."
        return 1
    fi

    CURRENT_USER="$username"
    echo "Welcome $CURRENT_USER"
    sleep 1
    return 0
}

auth_menu() {
    while true; do
        clear
        echo "===== USER LOGIN ====="
        echo
        echo "1. Login"
        echo "2. Register"
        echo "3. Exit"
        echo

        read -p "Choose: " choice

        case "$choice" in
            1)
                login_user && break
                ;;
            2)
                register_user
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid choice"
                sleep 1
                ;;
        esac
    done
}
