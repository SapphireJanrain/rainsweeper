# Rainsweeper #
Abstract minesweeper library. Also with some frontends.

## Frontends ##
### CLI ###
CLI frontend can be run by running the cli.rb script. Supports square and octagonal fields.

You can use an in-game command on the command-line by prefixing it with --, examples given after the command list.

General Commands:
Most commands also have one letter or synonym equivalents to make it easier to remember.

* **help**: Print this help message
* **new**: Start a new game
* **exit**: Exit game
* **diff** DIFFICULTY: Set the difficulty to beginner, intermediate, or expert
* **dim** COLS ROWS: Change the dimensions of the map. Must start a new game after
* **mines** MINES: Change the mines on the map. Must start a new game after
* **square**: Change the board to be square (8 neighboring cells)
* **oct**: Change the board to be octagonal (4 neighboring cells)

Coordinate commands (for X enter column letter, for Y enter the number):

*  XY: Uncover cell
*  !XY: Flag cell (you cannot uncover a cell while it's flagged)
*  ?XY: Question cell (you can uncover this cell but it looks distinct)
*  .XY: Unmark cell

To start a game with a different size map: `./cli.rb --dim 25 20 --new`

To start a game in octagonal mode: `./cli.rb --oct`

### Tkinter ###
Frontend made with GUI elements in Tkinter. It's a little slow but it works. Supports only square fields.

        --help                       Print this help
    -m, --mines MINES                Number of mines (default: 30)
    -w, --width WIDTH                Width of field (default: 20)
    -h, --height HEIGHT              Height of field (default: 20)

### General notes ###
All extra frontends should go in the base directory of the repository.

A game-library based frontend like with Gosu would be nice! This way it could easily support more complex boards.

## Library ##
The **boards** directory contains the alternative board formats (whereas square is the default, and defined in _board.rb_)

_scores.rb_ is the library that controls the scoring system and should generally not need to be upgraded. If the format changes, though, please increase the file format version number and use the system as indicated in the comments.

_exception.rb_ is just for shared exception types.

_board.rb_ and _cell.rb_ are the core game logic, referring to the whole board and its constituent cells, respectively.

_timer.rb_ deals with timing in real-time frontends, whereas _board.rb_ provides support for polling-based time only (used by _cli.rb_)
