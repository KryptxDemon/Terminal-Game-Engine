# Choice-Based Game Engine in Bash

## Project Overview
This project is a terminal-based choice-driven game engine developed using Bash shell scripting in WSL.  
It allows users to play branching story games and also create their own games using external scene files and helper tools.

## Features
- File-driven game engine
- Multiple games supported
- Branching story paths
- Multiple endings
- Save and load system
- Logging system
- Player stats: health, gold, reputation
- Inventory system
- Conditional choices based on required items
- Game creation tool
- Scene creation tool
- Game validation tool
- Game listing tool

## Folder Structure
```text
choice_engine/
├── engine/
│   └── main.sh
├── games/
│   ├── demo_game/
│   └── ...
├── logs/
├── saves/
├── tools/
│   ├── create_game.sh
│   ├── add_scene.sh
│   ├── validate_game.sh
│   └── list_games.sh
└── README.md
