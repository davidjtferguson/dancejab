looks like this

`function createanim(sprites,speeds,looping)`

but you don't have to pass all the arguments in.

Pass in a table of sprites like `{50, 52}` if you want multiple sprites, or just pass in a number if you just want one sprite until a new animation is sprite

Pass in a table of speeds if you want each sprite to play for a different lenght of time e.g. `{5, 10}`. Pass in a number if all sprites should play for the same length of time.

Pass in false for looping if you want the animation to sit on the last frame before being interupted. If you don't pass in looping, it defaults to true.

So, for e.g. to play the punching animation which has 3 sprites and have a different number of frames for each and does not loop you could do the following:

`av.anim=createanim({72,74,76},{3,1,3},false)`

To trigger the idle animation with even frames and looping you could pass in

`av.anim=createanim({64,66,68,70}, 6)`

Or to just hang on one frame until interupted you could pass in

`av.anim=createanim(96)`

HOWEVER note that there (currently) isn't a mechanic for the animation system to tell what's currently playing.
So if you call the same `createanim` each frame it's gonna re-make the animation each frame and stick on the first sprite.
So when you want an animation it has to be on a trigger that's only hit once. If you try and use it and you're just getting one sprite this will probs be the problem.
I might fix this later, it'd make life easier to fix it. Just makin you aware.