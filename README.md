# SplatLab
3D First Person Shooting game with custom ray-casting engine developed in MatLab. Inherits mechanics from Nintendo Splatoon  
Developed as Software Design Project for Engineering 1181 at The Ohio State University

## Controls
* W/A/S/D - movement
* Arrows left/right - rotation
* Space - spray paint on walls in front of player (in radius of 20 blocks)
* ,/. - 90-degree rotation
* Arrows up/down - change field of view

## Gameplay
* Game map is generated randomly in the start of each game and is displayed in the left top corner of the screen. 4 enemies are spawned randomly in the map. Player's initial score is 100.
* Each time player moves or sprays paint, all enemies move as well and color 80% of walls around them in radius of 5 blocks with yellow.
* If a player approaches a yellow wall in radius of 4 blocks, score decreases by one for every yellow wall in this radius per move or paint spray.
* If an enemy approaches a red wall in radius of 4 blocks, they die and player's score increases by 25.
* Player wins if they defeat all enemies while keeping score over 0.
* Player looses if score falls bellow or is equal to 0.
* After the end of the game, player can restart the game by pressing space.
## Licensing
Feel free to use code from this project partialy or in its entierty in any projects, but you must clearly reference "SplatLab by Alex Gulko (https://l.gulko.net/splatlab)" in code comments and anywhere in the GUI
