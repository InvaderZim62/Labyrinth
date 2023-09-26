# Labyrinth

Labyrinth is a marble board game.  I replicated the board from the actual toy box with knobs.
I loved to play this when I was a kid.

Tip the iPhone to move the marble through the maze, without falling through the holes.  Try to
get to the finish in the fastest time.

![Labyrinth](https://github.com/InvaderZim62/Labyrinth/assets/34785252/77b711b0-527d-43ca-829d-192b13a079af)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
![Labyrinth](https://github.com/InvaderZim62/Labyrinth/assets/34785252/c5aff1b2-7bd9-4605-a28b-e19a9a8edbb9)

## Board With Holes

I created the board scene with black trail and holes using [Blender](https://www.blender.org/).
This mesh node is purely for aethetics.  It is not given a physics body, since the holes are not
recognized by the physics engine.  Instead, I create "boardNode" and attached panels, board edges,
and bars with *kinematic* physics bodies to constrain the marble.

To create the panels, I use an algorithm to fit rectangular boxes between "holes", moving from top
left to bottom right, until the entire board is covered.  Normally, the panels are clear, but this
is what it looks like if I use different colors.
