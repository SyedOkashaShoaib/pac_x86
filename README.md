# pac-x86

A Pac-Man-inspired arcade game written entirely in x86 MASM assembly, running in the Windows console. The player navigates a maze, collects coins, and avoids three ghosts — all rendered and controlled at the register level with no high-level language abstractions.

---

## Table of Contents

- [Overview](#overview)
- [Dependencies](#dependencies)
- [Building and Running](#building-and-running)
- [Gameplay](#gameplay)
- [Architecture](#architecture)
- [Win32 API Usage](#win32-api-usage)

---

## Overview

pac-x86 is a single-file x86 assembly project built with the Irvine32 library. The entire game — including the game loop, ghost movement, collision detection, coin collection, and console rendering — is implemented in MASM assembly using direct Win32 API calls and register manipulation.

The game features a custom maze, three ghosts with distinct patrol behaviors, a 60-second countdown timer, a live score display, and three distinct end conditions.

---

## Dependencies

- **Microsoft Macro Assembler (MASM)** — included with Visual Studio
- **Irvine32 Library** — provides I/O and console utilities for x86 assembly
  - `irvine32.inc`
  - `macros.inc`
  - `kernel32.lib`
  - `user32.lib`
- **Windows OS** — the game uses Win32 console APIs and is Windows-only
- **CapsLock must be ON** — keyboard input is read via `GetKeyState` using uppercase scan codes; the game will prompt you if CapsLock is off

---

## Building and Running

1. Open the project in **Visual Studio** with MASM support enabled.
2. Ensure the Irvine32 library is correctly linked in your project settings.
3. Assemble and link `main.asm`.
4. Run the resulting executable in a Windows console.
5. Enable CapsLock before playing.

---

## Gameplay

| Key | Action |
|-----|--------|
| W | Move Up |
| S | Move Down |
| A | Move Left |
| D | Move Right |
| X | Quit |

**Objective:** Collect all coins placed throughout the maze before the 60-second timer expires and without being caught by a ghost.

**Win condition:** All coins collected.

**Loss conditions:**
- Collision with any ghost
- Timer exceeds 60 seconds

---

## Architecture

The game is structured as a continuous main loop that handles input, advances ghost positions, checks collision and win conditions, and redraws the screen on each tick.

The maze is constructed from hardcoded wall segments drawn once at startup. Wall coordinates are stored in a flat byte array and consulted on every player move to validate that the destination tile is not occupied.

Coins are similarly tracked in a coordinate array. On each player move, the game checks whether the player's position overlaps any active coin entry and marks collected coins accordingly. A redraw pass runs every tick to restore coins that may have been visually overwritten by ghost movement.

Each ghost follows a scripted patrol path defined as a sequence of directional steps. When a ghost completes its pattern, the step sequence resets and the patrol repeats. The three ghosts operate independently with different routes and starting positions.

Collision detection compares the player's console coordinates against each ghost's position on every game loop iteration. Any overlap sets a collision flag that terminates the game.

---

## Win32 API Usage

| API Call | Purpose |
|---|---|
| `GetStdHandle` | Obtain handle to the console output buffer |
| `SetConsoleCursorInfo` | Hide the cursor to reduce visual noise |
| `SetConsoleTextAttribute` | Set foreground color for walls, coins, and UI text |
| `GetTickCount` | Read system uptime in milliseconds for the game timer |
| `GetKeyState` | Check CapsLock state and read player input |
