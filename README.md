# Choice-Based Game Engine in Bash

This project is a terminal-based branching story engine built with Bash shell scripts for WSL/Linux. It lets you play story games, manage saves, track stats, and author new scenes with helper tools.

## Documentation

Full project documentation is available in [docs/PROJECT_DOCUMENTATION.md](docs/PROJECT_DOCUMENTATION.md).

## Quick Overview

- File-driven story engine
- Multiple games supported from the `games/` folder
- Branching choices with requirements and effects
- Player stats: health, gold, reputation, inventory
- Save/load slots per user
- Leaderboard and ending rewards
- Game studio tools for creating, editing, validating, and listing games

## Folder Structure

```text
Terminal-Game-Engine/
├── engine/
│   ├── auth.sh
│   └── main.sh
├── games/
│   └── The Cursed Kingdom/
├── logs/
├── database/
├── tools/
│   ├── add_scene.sh
│   ├── create_game.sh
│   ├── delete_scene.sh
│   ├── edit_scene.sh
│   ├── list_games.sh
│   ├── story_studio.sh
│   └── validate_game.sh
└── docs/
	├── PROJECT_DOCUMENTATION.md
	└── images/
```
