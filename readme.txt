========================================
      GMOD 13 COMPATIBILITY LAYER
========================================
An experimental creation by CosmicStar98
Made with love and autism <3


This is a really early iteration of something i hope is progressively
improved upon.

In its current state, this WILL NOT magically allow for all gmod 13 addons to
work right out of the box, but should help with a plethora of things. I intend to continue working
on this project and hope others collaborate to make this better for everyone! (⌐■_■)

========================================

HOW TO INSTALL: ---> do NOT put inside addons folder!! <---
place in garrysmod/ folder.

should be like this:
garrysmod/lua/
autorun/!!!sh_load.lua
autorun/init.lua
ext/
libs/

Q: why not addons folder?
A: this needs to load before all addons
inside addon folder, this plays roulette with the game's internal load order.
when inside /addons/ it either loads too early or too late, causing many errors.

========================================

TODO LIST: (in order of priority high/low)
- lua headers
- make a module base
- net lib
- file lib
- http lib
- bass lib