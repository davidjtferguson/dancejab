pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- jab prototype
-- footsies based fighting game

test=""

--avatar
function createav(x,flipped)
 local av={
  --constants, play around with
 
  --how long each action lasts
  -- in frames at 60fps
  rollframes=9,
  jabframes=6,
  jablagframes=30,
  
  --movement limits
  -- in pixels/frame
  xacc=0.15,
  xmaxvel=1.3,
  xrollmaxvel=2,
  
  --xvel is multiplied by this
  -- each frame there's no input
  -- and not rolling
  xdecellrate=0.7,
  
  --hitbox sizes in pixels
  -- (won't effect visual)
  width=8,
  height=16,
  jabwidth=8,
  jabheight=4,
  
  --vars, don't edit
  x=x,
  xvel=0,
  state="none",
  statetimer=0,
  y=96,
  s=2,
  flipped=flipped,
 }
 add(avs,av)
 return av
end

function createhitbox(w,h,av)
 local box={
  x=av.x,
  y=av.y,
  width=w,
  height=h,
  av=av,
  pno=av.no,
 }
 add(hitboxes,box)
 return box
end

function _init()
 reset()
end

function reset()
 avs={}
 hitboxes={}

 p1=createav(24)
 p1.no=0
 
 p2=createav(96,true)
 p2.no=1
end

function _update60()
 --inputs
 for av in all(avs) do
  updateav(av)
 end
 
 for box in all(hitboxes) do
  updatehitbox(box)
 end
 
 --collision
 if aabbcollision(p1,p2) then
  --bounce off eachother
  p1.xvel=-0.5
  p2.xvel=0.5
 end
end

function updateav(av)
 if av.statetimer>0 then
  av.statetimer-=1
 end
 
 for box in all(hitboxes) do
  if box.pno!=av.no then
   if aabbcollision(av,box) then
    --reset game
    test="player "..(1+av.no).." lost!"
    reset()
   end
  end
 end

 --can't act out of jab
 if av.state=="none" or
    av.state=="roll" then
  detectinputs(av)
 end
 
 if av.state=="none" then
  av.s=2
  
  if btn(⬅️,av.no) then
   av.xvel-=av.xacc
  elseif btn(➡️,av.no) then
   av.xvel+=av.xacc
  else
   av.xvel*=av.xdecellrate
  end
  
  if av.xvel>av.xmaxvel then
   av.xvel=av.xmaxvel
  end
  
  if av.xvel<-av.xmaxvel then
   av.xvel=-av.xmaxvel
  end
 elseif av.state=="roll" then
  av.s=3
 elseif av.state=="jab" then
  av.s=6
  
  if av.statetimer==0 then
   av.state="jablag"
   av.statetimer=av.jablagframes
  end
 elseif av.state=="jablag" then
  av.s=5
  av.xvel=0
 end
 
 if av.statetimer==0 then
  av.state="none"
 end
 
 --prevent leaving the screen
 if av.x<0 then
  av.x=0
  av.xvel=0
 end
 
 if av.x+av.width>128 then
  av.x=128-av.width
  av.xvel=0
 end
 
 av.x+=av.xvel
end

function detectinputs(av)
 -- roll triggered
 if btnp(❎,av.no) then
  av.state="roll"
  av.statetimer=av.rollframes

  -- roll direction held or facing
  if btn(⬅️,av.no) then
   --roll to the left
   av.xvel=-av.xrollmaxvel
  elseif btn(➡️,av.no) and
         btnp(❎,av.no) then
   --roll to the right
   av.xvel=av.xrollmaxvel
  elseif av.flipped then
   --roll to the left
   av.xvel=-av.xrollmaxvel
  else
   --roll to the right
   av.xvel=av.xrollmaxvel
  end
 end
 
 --jab
 if btnp(🅾️,av.no) then
  av.state="jab"
  av.statetimer=av.jabframes
  createhitbox(av.jabwidth,av.jabheight,av)
 end
end

function updatehitbox(box)
 if not box.av.flipped then
  box.x=box.av.x+8
  box.y=box.av.y+8
 else
  box.x=box.av.x-8
  box.y=box.av.y+8
 end
 
 --remove once jab is over
 if box.av.state=="jablag" then
  del(hitboxes,box)
 end
end

function _draw()
 cls(1)
 
 map(0,0,0,0,16,16)
 
 spr(p1.s,p1.x,p1.y,1,2,p1.flipped)
 spr(p2.s,p2.x,p2.y,1,2,p2.flipped)

 for box in all(hitboxes) do
  spr(23,box.x,box.y,1,1,box.av.flipped)
 end

 print(test,0,0)
end

--only tested in x axis
function aabbcollision(a,b)
 if
    --a.y>b.y+b.height or
    --a.y+a.height<b.y or
    a.x>b.x+b.width or
    a.x+a.width<b.x then
  return false
 end
 
 return true
end
__gfx__
00000000bbbbbbbb00aaaa0000bbbb00000000000022220000aa8a80000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb0aaaa8a00bbbb8b000000000022228200aaaa8a0000000000000000000000000000000000000000000000000000000000000000000000000
00700700bbbbbbbb0aaaaaa00bbbbbb000000000022222200aaa8a80000000000000000000000000000000000000000000000000000000000000000000000000
00077000bbbbbbbb00aaddd000bbddd0000000000022ddd000aaddd0000000000000000000000000000000000000000000000000000000000000000000000000
00077000bbbbbbbb000aa000000bb0000000000000022000000aa000000000000000000000000000000000000000000000000000000000000000000000000000
00700700bbbbbbbb000aa000000bb0000000000000022000000aa000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb00aaaa0000bbbb00000000000022220000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb0aaaaaa00bbbbbb000000000022222200aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000
33333333ccccccccaaaaaaaabbbbbbbb0000000022222222aaaaaaa8888888800000000000000000000000000000000000000000000000000000000000000000
33333333ccccccccaaaaaaa9bbbbbbbb0000000022222292aaaaaaa8888888880000000000000000000000000000000000000000000000000000000000000000
33333333ccccccccaaaa999abbbbbbbb0000000022229922aaaa9888888888800000000000000000000000000000000000000000000000000000000000000000
33333333ccccccccaaaaaaaabbbbbbbb0000000022222222aaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000
33333333ccccccccaaaaaaa0bbbbbbb00000000022222220aaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000
33333333cccccccc0aaaaa000bbbbb0000000000022222000aaaaa00000000000000000000000000000000000000000000000000000000000000000000000000
33333333cccccccc0a00a0000b00b00000000000020020000a00a000000000000000000000000000000000000000000000000000000000000000000000000000
33333333cccccccc09a09a0009a09a000000000009a09a0009a09a00000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111cccccccc11111111
11111111cccccccc11111111cccccccc111111aaaacccccc11111111cccccccc11111111caaaaccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111aaaa8accccc11111111cccccccc11111111a8aaaacc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111aaaaaaccccc11111111cccccccc11111111aaaaaacc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc111111aadddccccc11111111cccccccc11111111dddaaccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc1111111aaccccccc11111111cccccccc11111111ccaacccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc1111111aaccccccc11111111cccccccc11111111ccaacccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc111111aaaacccccc11111111cccccccc11111111caaaaccc11111111cccccccc11111111cccccccc11111111cccccccc
11111111cccccccc11111111cccccccc11111aaaaaaccccc11111111cccccccc11111111aaaaaacc11111111cccccccc11111111cccccccc11111111cccccccc
cccccccc11111111cccccccc11111111ccccaaaaaaaa1111cccccccc11111111cccccccaaaaaaaa1cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111ccccaaaaaaa91111cccccccc11111111ccccccc9aaaaaaa1cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111ccccaaaa999a1111cccccccc11111111ccccccca999aaaa1cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111ccccaaaaaaaa1111cccccccc11111111cccccccaaaaaaaa1cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111ccccaaaaaaa11111cccccccc11111111ccccccccaaaaaaa1cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccaaaaa111111cccccccc11111111cccccccc1aaaaa11cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111cccccacca1111111cccccccc11111111cccccccc11a11a11cccccccc11111111cccccccc11111111cccccccc11111111
cccccccc11111111cccccccc11111111ccccc9ac9a111111cccccccc11111111cccccccc1a91a911cccccccc11111111cccccccc11111111cccccccc11111111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110011001100110011001100110011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1001100110011001100110011001100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
