# BG Helper

BG Helper is a lightweight Turtle WoW addon for quick Arathi Basin callouts.
It provides a small movable window for announcing incoming enemies or marking
a base as safe without having to type each message manually.

## Features

- Quick callouts for 1–5 incoming enemies
- `ALOT` callout for larger groups
- `SAFE` callout for secured bases
- Automatic detection of the nearest Arathi Basin base
- Alliance-blue and Horde-red capture bars with a live seconds countdown
- Clickable timer bars that announce the remaining time in battleground chat
- Automatic timer removal when a base is defended, captured, or marked `SAFE`
- Random battleground welcome featuring a raid member and the addon link
- Three-second anti-spam cooldown after every callout
- Movable window with saved positioning

## Installation

1. Download this repository using **Code → Download ZIP**.
2. Extract the archive.
3. Rename the extracted folder to `BGHelper`.
4. Place it in:

   ```text
   World of Warcraft/Interface/AddOns/BGHelper
   ```

5. Restart the game or reload the UI.

The folder should contain `BGHelper.lua` and `BGHelper.toc` directly, without
an additional nested folder.

## Usage

The helper appears automatically in Arathi Basin.
After joining, it sends one random funny welcome once the raid roster is ready.

1. Select `1`–`5` or `ALOT`.
2. Use `CALL` to announce enemies at the nearest base.
3. Press `SAFE` to immediately announce that the nearest base is secure.

Drag the window with the left mouse button to reposition it. Its position is
saved between sessions.

## Slash commands

| Command | Description |
| --- | --- |
| `/bgh` or `/bgh toggle` | Toggle the helper window |
| `/bgh show` | Show the helper window |
| `/bgh hide` | Hide the helper window |
| `/bgh test` | Show sample Alliance and Horde capture timers |
| `/bgh test off` | Remove all test timers |
| `/bgh debug` | Show zone and map-position information |

## Repository

Updates are available at
[github.com/OctoAddons/BGHelper](https://github.com/OctoAddons/BGHelper).
