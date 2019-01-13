# jab
fighting game prototype. dashing and jabbing only.

Made with Pico 8.

Two player game - either hook up two controllers or look up Pico 8's keyboard mapping for the second controller on the keyboard.

Left and right to move left and right.

O to jab and X to dash.

Design ideas (everything in brackets is extra, not implemented currently):

movement:
1. acceleration left and right.
2. Roll - cancels all momentum to a fast dash back or forward. (ducks under standing jab?)
3. Jab - small punch infront of body. Carries current momentum. Laggy enough to expect to get hit on wiff. (If jab when rolling low, if jab when standing high?)
(4. Crouch - if we try out the jab heights thing there should be a crouch so you can stand your ground if someone tries to roll jab you. Can't move when crouched and takes a handful of frames to get up)
Reset to neutral if either player is hit by a jab. (would be a cool effect for hit player to be hit back into starting position then for the camera to move to re-cenre both players)
first to three wins.

Small space to play with so trying to control the centre is imperitive. Draws people into the centre to push conflict. Each player wants to keep enough space behind them so that they can dash back if needed. (Could slowly bring in edges of screen for timeout mechanic)

(Roll can't be cancelled for the first 'beat' Gonna go with like 15 frames to start with. Needs to have some disadvantage to discourage constant use and see some value in walking.)