# BG Helper

BG Helper is a lightweight Turtle WoW addon for quick Arathi Basin callouts.
It provides a small movable window for announcing incoming enemies or marking
a base as safe without having to type each message manually.

## Features

- Quick callouts for 1–5 incoming enemies
- `ALOT` callout for larger groups
- `SAFE` callout for secured bases
- Automatic detection of the nearest Arathi Basin base
- Movable window with saved positioning
- Optional battleground join announcement

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

1. Select `1`–`5`, `ALOT`, or `SAFE`.
2. Click a base to send the callout to battleground chat.
3. Use `CALL` to announce the base nearest to your current position.

Drag the window with the left mouse button to reposition it. Its position is
saved between sessions.

## Slash commands

| Command | Description |
| --- | --- |
| `/bgh` or `/bgh toggle` | Toggle the helper window |
| `/bgh show` | Show the helper window |
| `/bgh hide` | Hide the helper window |
| `/bgh announce` | Toggle the battleground join announcement |
| `/bgh announce on` | Enable the join announcement |
| `/bgh announce off` | Disable the join announcement completely |
| `/bgh debug` | Show zone and map-position information |

The join-announcement preference is saved between sessions. It is enabled by
default and sends at most once per battleground visit.

## Repository

Updates are available at
[github.com/stephanancher/BGHelper](https://github.com/stephanancher/BGHelper).
