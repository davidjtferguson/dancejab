pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- dancejab
-- footsies based fighting game

test=""

--avatar
function createav(x,y,name,flipped)
 local av={
  --constants, play around with
 
  --how long each action lasts
  -- in frames at 60fps
  -- note animations will need to be updated
  -- if screwing around with these
  dashframes=7,
  jabframes=7,
  jablagframes=10,
  connectlagframes=19,
  hitpauseframes=7,
  hitrecoilframes=10,
  
  --movement limits
  -- in pixels/frame
  xacc=0.4,
  xmaxvel=.7,
  xdashmaxvel=1.8,
  
  --xvel is multiplied by this
  -- each frame there's no input
  -- and not dashing
  xdecellrate=.7,
  
  --xvel is multiplied by this
  -- on character collision
  -- so 1 for no effect,
  -- -1 to reverse current vel
  xcollisionmult=-1,
  
  --av size
  width=16,
  height=16,

  -- x,y local to av x,y
  hurtbox={
   x=5,
   y=6,
   width=5,
   height=10,
  },

  pushbox={
   x=2,
   y=3,
   width=12,
   height=10,
  },

  --jab hitbox sizes in pixels
  jabwidth=6,
  jabheight=8,
  
  --create animations for this av
  animcountdown=createanim({66,44,224},{30,30,30},true),
  animidle=createanim({224,66,226,228,230,232,64,234,236,238},{5,2,5,5,5,5,2,5,5,5}),
  animwalkforward=createanim({128,130,132,134},5),
  animwalkback=createanim({136,138,140,142},5),
  animdashforward=createanim({37,96,5},{3,2,2},false),
  animdashback=createanim({39,98,7},{3,2,2},false),
  animjab=createanim({72,74,76},{3,6,1},false),
  animringout=createanim({192,194},6,false),
  animjablag=createanim({78,44,100},{3,3,5},false),
  animconnectlag=createanim({102,74,46,78},{9,3,5,3},false),
  animhitstun=createanim({34,108,110},{3,3,10},false),
  animlostround=createanim({108,110},{6,1},false),
  animlostmatch=createanim({160,162,164,166},{6,3,10,10}),
  animvictory=createanim({168,170,172,174},6),
  animclank=createanim(106),
  animuptaunt=createanim(68),
  animdowntaunt=createanim(64),

  hitpoints=maxhitpoints,
 
  --vars, don't edit
  x=x,
  xvel=0,
  y=y,
  yvel=0,
  flipped=flipped,
  state="none",
  statetimer=0,
  name=name,
 }
 av.anim=av.animidle

 if modes[mode]=="1 hit ko" then
  av.hitpoints=1
 end

 add(avs,av)
 return av
end

function createhitbox(w,h,av)
 local box={
  x=av.x,
  y=av.y+8,
  width=w,
  height=h,
  av=av,
  pno=av.no,
  active=true,

  --fist animations
  animthrow=createanim({120,104},{3,5},false),
  animconnect=createanim({121,120,104},{9,2,7},false),
 }
 box.anim=box.animthrow
 add(hitboxes,box)
 return box
end

function _init()
 --duped in draw,
 -- just for first frame...	
 palt(0,false)
 palt(11,true)

 --constants
 --wins for a set
 firstto=3

 hitknockback=1.5

 --hitpoints in a round
 maxhitpoints=3
 gravity=0.15

 modes={"normal","sumo","1 hit ko","slippy shoes"}
 mode=1

 -- menu controls
 optionselected=0

 --init stage select
 stages={}
 ssid=1
 sstage=nil

 createstage("normal",0,0,24,96,88,96)
 createstage("small",128,0,43,96,70,96)
 createstage("ghost",256,0,24,48,88,96)
 createstage("tredmill out",384,0,24,96,88,96)
 createstage("tredmill in",512,0,24,96,88,96)
 createstage("ice",640,0,24,96,88,96)

 sstage=stages[ssid]

 resetmatch()
 
 music(20)
 currentupdate=updatestart
 currentdraw=drawstart

 menuitem(1, "exit to menu", exittomenu)
end

function exittomenu()
 resetmatch()
 music(20)
 currentupdate=updatemenu
 currentdraw=drawmenu

 p1.anim=p1.animidle
 p2.anim=p2.animidle
end

function resetmatch()
 resetround()
 
 --vars
 p1.score=0
 p2.score=0

 initcountdown()
 currentupdate=updatecountdown
 currentdraw=drawcountdown
end

function resetround()
 if p1 then
  scorep1=p1.score
  scorep2=p2.score
 end
 
 avs={}
 hitboxes={}

 p1=createav(sstage.p1x,sstage.p1y,"red")
 p1.no=0
 p1.score=scorep1
 
 p2=createav(sstage.p2x,sstage.p2y,"blue",true)
 p2.no=1
 p2.score=scorep2

 --remember opponent avatar
 p1.oav=p2
 p2.oav=p1
end

function initcountdown()
 music(1)
 p1.anim=p1.animcountdown
 p2.anim=p2.animcountdown

 ct=0
 ctvel=0
 xcorner=72
 countdownno=3
end

function _update60()
 currentupdate()
end

function updatestart()
 if btnp()!=0 then
  p1.anim=p1.animidle
  p2.anim=p2.animidle
  currentupdate=updatemenu
  currentdraw=drawmenu
 end
end

function updatemenu()
 updateanim(p1.anim)
 updateanim(p2.anim)

 if btnp(⬇️) then
  sfx(5)
  optionselected+=1

  if optionselected>1 then
   optionselected=0
  end
 end
 
 if btnp(⬆️) then
  sfx(5)
  optionselected-=1

  if optionselected<0 then
   optionselected=1
  end
 end

 --option 0 is stage select
 if optionselected==0 and (btnp(➡️) or btnp(⬅️)) then
  sfx(4)
  if btnp(⬅️) then
   ssid-=1
   if ssid==0 then
    ssid=#stages
   end
  elseif btnp(➡️) then
   ssid+=1
   if ssid>#stages then
    ssid=1
   end
  end

  loadstage()
 end

 --option 1 is mode
 if optionselected==1 and (btnp(➡️) or btnp(⬅️)) then
  sfx(4)

  if btnp(➡️) then
   mode+=1

   if mode>#modes then
    mode=1
   end
  elseif btnp(⬅️) then
   mode-=1

   if mode==0 then
    mode=#modes
   end
  end

  --before I was setting maxhitpoints to 1
  -- but this is cooler because you can see
  -- you're low on health from the menu
  if modes[mode]=="1 hit ko" then
   p1.hitpoints=1
   p2.hitpoints=1
  else
   p1.hitpoints=maxhitpoints
   p2.hitpoints=maxhitpoints
  end
 end
 
 if btnp(❎) or btnp(🅾️) then
  initcountdown()
  currentupdate=updatecountdown
  currentdraw=drawcountdown
 end
end

function loadstage()
 sstage=stages[ssid]
 p1.x=sstage.p1x
 p1.y=sstage.p1y
 p2.x=sstage.p2x
 p2.y=sstage.p2y
end

function updatecountdown() 
 updateanim(p1.anim)
 updateanim(p2.anim)

 if countdownno==3 and ctvel==0 then
  sfx(2)
 end

 ctvel+=0.35 
 ct+=ctvel

 if ct>=128 then
  ct=0
  ctvel=0
  xcorner+=8
  countdownno-=1
  sfx(2,3)
 end

 if countdownno==0 then
  --start fight
  sfx(3,3)
  currentupdate=updategame
  currentdraw=drawgame
 end
end

function updategame()
  updatepes()

  --inputs
  for av in all(avs) do
   updateav(av)
  end
  
  for box in all(hitboxes) do
   updatehitbox(box)
  end
  
  if aabbcollision(
     globalbox(p1,p1.pushbox),
     globalbox(p2,p2.pushbox))
  then
   sfx(11)

   --if -1
   -- flips velocity, so walking
   -- is strong against dashing
   -- at gaining space.
   p1.xvel*=p1.xcollisionmult
   p2.xvel*=p2.xcollisionmult
   
   --bounce off eachother
   p1.xvel-=0.5
   p2.xvel+=0.5
  end
 end

function detectinputs(av)
 --dash triggered
 if btnp(❎,av.no) then
  sfx(8)
  av.state="dash"
  av.statetimer=av.dashframes

  --dash direction held or facing
  if btn(⬅️,av.no) then
   --dash to the left
   av.xvel=-av.xdashmaxvel
  elseif btn(➡️,av.no) and
         btnp(❎,av.no) then
   --dash to the right
   av.xvel=av.xdashmaxvel
  elseif av.flipped then
   --dash to the left
   av.xvel=-av.xdashmaxvel
  else
   --dash to the right
   av.xvel=av.xdashmaxvel
  end

  --kick up dust
  -- (done after as needs xvel set)
  initpedash(av)
 end
 
 --jab
 if btnp(🅾️,av.no) then
  sfx(9+flr(rnd(2)))
  av.state="jab"
  av.anim=av.animjab
  av.statetimer=av.jabframes
  av.fist=createhitbox(av.jabwidth,av.jabheight,av)
 end
end

function updateav(av)
 if av.statetimer>0 then
  av.statetimer-=1
 end

 local icy = checkavflagarea(globalbox(av,av.hurtbox),3) or modes[mode]=="slippy shoes"

 --on ground?
 if checkavflagarea(
    globalbox(av,av.hurtbox),0) then
  av.yvel=0

  --tredmill tiles
  if av.state!="won" and av.oav.state!="won" then
   if checkavflagarea(
     globalbox(av,av.hurtbox),1) then
    av.x-=0.25
   end
   
   if checkavflagarea(
     globalbox(av,av.hurtbox),2) then
    av.x+=0.25
   end
  end
 else
  --on first ringout detection
  if av.state!="ringout" then
   av.hitpoints=0

   if av.fist then
    del(hitboxes,av.fist)
   end

   --prevent double death
   if av.state!="dead" then
    sfx(15)
    av.anim=av.animringout
    updatescore(av)
    av.statetimer=90
   end
   
   av.state="ringout"
  end
  
  --prevent memory wrap on ringout
  if av.y>1000 then
   av.yvel=0
  end
 end
 
 hitboxcollision(av)
 
 --can only act in some states
 if av.state=="none" or
    av.state=="dash" then
  detectinputs(av)
 end
 
 if av.state=="none" then
  --walking
  if facingforward(av) then
   av.anim=av.animwalkforward
  else
   av.anim=av.animwalkback
  end

  if btn(⬅️,av.no) then
   av.xvel-=av.xacc
  elseif btn(➡️,av.no) then
   av.xvel+=av.xacc
  else
   if not icy then
    av.xvel*=av.xdecellrate
   end
   
   if btn(⬆️,av.no) then
    av.anim=av.animuptaunt
   elseif btn(⬇️,av.no) then
    av.anim=av.animdowntaunt
   else
    av.anim=av.animidle
   end
  end
  
  if av.xvel>av.xmaxvel then
   av.xvel=av.xmaxvel
  end
  
  if av.xvel<(-av.xmaxvel) then
   av.xvel=-av.xmaxvel
  end
 elseif av.state=="dash" then
  if facingforward(av) then
   av.anim=av.animdashforward
  else
   av.anim=av.animdashback
  end
 elseif av.state=="jab" then
  if av.statetimer==0 then
   av.anim=av.animjablag
   av.state="jablag"
   av.statetimer=av.jablagframes
  end
 elseif av.state=="jablag" then
   if not icy then
    av.xvel=0
   end
 elseif av.state=="connectlag" then
   av.xvel=0
 elseif av.state=="hitpause" then
  av.xvel=0
  if av.statetimer==0 then
   av.state="hitrecoil"
   av.statetimer=av.hitrecoilframes
  end
 elseif av.state=="hitrecoil" then
  takeknockback(av)
 elseif av.state=="won" then
  av.xvel=0

  if av.statetimer==0 and av.score!=firstto then
   resetround()
  end

  --if we were playing the throw punch anim
  -- wait till it finishes
  if av.anim.looping or av.anim.finished then
   av.anim=av.animvictory
  end
 
 elseif av.state=="dead" then
  if av.statetimer==80 then
   takeknockback(av)
  end
  av.xvel*=0.9
 elseif av.state=="ringout" then
  --make sure we overrite others,
  -- e.g. lost anim
  av.anim=av.animringout
  av.yvel+=gravity
  av.xvel*=0.9
 end

 if av.statetimer==0 and (av.state!="won" and av.oav.state!="won") then
  av.state="none"
 end

  --check for winner
  -- (after round end pause)
  -- and hard reset
  if av.statetimer==0 and av.score==firstto then
   if btnp(🅾️) or btnp(🅾️,1) then
    resetmatch()
   end
   
   if btnp(❎) or btnp(❎,1) then
    exittomenu()
   end
  end

 updateanim(av.anim)

 av.x+=av.xvel
 av.y+=av.yvel
end

function facingforward(av)
 if (not av.flipped and
    av.xvel>0) or
    (av.flipped and
    av.xvel<0) then 
  return true
 else
  return false
 end
end

function takeknockback(av)
 if av.flipped then
  av.xvel=hitknockback
 else
  av.xvel=-hitknockback
 end
end

function hitboxcollision(av)
 for box in all(hitboxes) do
  if box.pno!=av.no then

   if aabbcollision(globalbox(av,av.hurtbox),box) and box.active then
    --other avatar pauses
    av.oav.state="connectlag"
    av.oav.statetimer=av.oav.connectlagframes
    av.oav.anim=av.oav.animconnectlag
    av.oav.xvel=0

    --been punched!
    if modes[mode]!="sumo" then
     av.hitpoints-=1
    end

    --sparks
    initpehit(box.x,box.y)

    av.state="hitpause"
    av.statetimer=av.hitpauseframes
    av.anim=av.animhitstun

    if av.hitpoints==0 then
     sfx(14)
     av.anim=av.animlostround
     updatescore(av)
     av.state="dead"
     av.statetimer=90
    else
     sfx(12)
    end

    box.anim=box.animconnect
    box.active=false
   end
  end
 end
end

--pass in av that just died
function updatescore(av)
 av.oav.score+=1
 
 if av.oav.score==firstto then
  music(17)
  av.anim=av.animlostmatch
 end
 av.oav.state="won"
 av.oav.statetimer=90
end

function updatehitbox(box)
 updateanim(box.anim)

 if not box.active then
  if box.anim.finished then
   del(hitboxes,box)
   return
  end
 end

 --track av pos
 if not box.av.flipped then
  box.x=box.av.x+box.av.width
 else
  box.x=box.av.x-box.width-1
 end
 
 --remove once jab is over
 if box.av.state=="jablag" then
  del(hitboxes,box)
 end
 
 for otherbox in all(hitboxes) do
  if aabbcollision(box,otherbox) and
     box.pno!=otherbox.pno and
     box.active and otherbox.active then
   --hitboxes colided,
   -- seperate avs
   -- (should be generic...)
   
   p1.anim=p1.animclank
   p2.anim=p2.animclank
   p1.xvel=-1
   p2.xvel=1
   
   --todo:should have some sparks or something
   box.active=false
   box.anim=box.animconnect
   otherbox.active=false
   otherbox.anim=otherbox.animconnect
  end
 end 
end

function _draw()
 cls(1)
 currentdraw()
 print(test,0,0,4)
end

function drawstart()
 decompress_spsh(title, true)
end

function drawmenu()
 drawgame()

 local option0="stage"
 local option0length=#option0
 local option1="mode"
 local option1length=#option1

 if optionselected==0 then
  option0=addarrows(option0)
  option0length=#option0+2
 elseif optionselected==1 then
  option1=addarrows(option1)
  option1length=#option1+2
 end

 outline(option0,(64-option0length*2),12,10,8)
 print(sstage.name,(64-#sstage.name*2),20,10,8)

 outline(option1,(64-option1length*2),30,10,8)
 print(modes[mode],(64-#modes[mode]*2),38,10,8)
end

function addarrows(s)
 return "⬅️ "..s.." ➡️"
end

function drawcountdown()
 drawgame()

 --because the sprites don't fill the 8x8s,
 -- need offsets
 local offset=8
 if (countdownno==1) offset=0

 sspr(xcorner,16,8,8,
  ct/2,ct/2,
  (128-ct)+offset,128-ct)
end

function drawgame()
 --think this drops us to 30fps?
 --drawbackground()
 map(sstage.camerax/8,sstage.cameray/8,
  0,0,
  16,16)
 
 drawav(p1)

 drawwithp2colours(drawav)
 
 --draw player1 hitboxes again
 -- on top of p2
 drawavhitboxes(p1)

 --game info
 --p1 health
 rectfill(5,5,24,8,13)
 if p1.hitpoints>0 then
  rectfill(5,5,4+(20*(p1.hitpoints/maxhitpoints)),8,8)
 end
 spr(18,3,3,3,1,true)

 --p2 health
 rectfill(103,5,122,8,13)
 if p2.hitpoints>0 then
  rectfill(103+20-20*(p2.hitpoints/maxhitpoints),5,122,8,12)
 end
 spr(18,101,3,3,1)

 --explain why health isn't going down
 if modes[mode]=="sumo" then
  print("sumo",7,5,7)
  print("sumo",106,5,7)
 end

 --lights showing score
 local maxgames=firstto*2-1

 for i=1,maxgames do
  local lightspr=26
  if i<=p1.score then
   lightspr=10
  end

  if i>(maxgames-p2.score) then
   lightspr=11
  end

  spr(lightspr,i*7+(57-(maxgames/2)*7),1)
 end

 --draw fight sprite for first
 -- -ct frames of fight
 -- set in updatecountdown
 if countdownno==0 and ct<30 then
  ct+=1
  sspr(96,0,32,16,
   32,48,
   64,32)
 end

 if p1.score==firstto or p2.score==firstto then
 	local col1,col2=10,8
	 local winner=""
	 
	 if p1.score==firstto then
	  winner="red wins!"
	 elseif p2.score==firstto then
	  winner="blue wins!"
	  col1,col2=13,12
	 end

  outline(winner,(64-#winner*2),30,col1,col2)

  if p1.statetimer==0 and p2.statetimer==0 then
   outline("🅾️ replay",46,56,col1,col2)
   outline("❎ menu",50,74,col1,col2)
  end
 end

 drawpes()

 --debug info
 --drawlocalbox(p1,p1.pushbox,5)
 --drawlocalbox(p1,p1.hurtbox,9)

 -- for box in all(hitboxes) do
 --  rectfill(box.x,box.y,
 --   box.x+box.width,
 --   box.y+box.height,3)
 -- end
end

function drawav(av)
 --add a little shake if being hit
 -- shouldn't be every frame!
 local randx=0
 local randy=0
 local shakerange=3

 if av.state=="hitpause" then
  randx=rnd(shakerange)-(shakerange/2)
  randy=rnd(shakerange)-(shakerange/2)
 end

 spr(av.anim.sprite,av.x+randx,av.y+randy,2,2,av.flipped)

 drawavhitboxes(av)
end

function drawwithp2colours(drawing)
 pal(8,12)
 pal(2,13)
 pal(12,8)
 pal(1,2)
 
 drawing(p2)

 pal()
 palt(0,false)
 palt(11,true)
end

--adapted form
-- https://twitter.com/lexaloffle/status/1149043190218891264
move=0
movevel=0
moveadd=0.001

function drawbackground()
 movevel+=moveadd
 move+=movevel
 
 if abs(movevel)>0.1 then
  moveadd*=-1
 end

	for z=32,1,-1 do
	 for x=-32,32 do
	  y=cos(x/16+z/32+move/2)*50-80-move*50   
	  sx,r,c=64+x*64/z,8/z,circfill
	  c(sx,64+y/z,r,12+(x+z*2)%4)
	  c(sx,64+-y/z,r,5)
	 end
	end
end

function drawavhitboxes(av)
 for box in all(hitboxes) do
  if box.av == av then

   --p2 fist is visually off by a pixel
   -- for some reason??
   local boxx = box.x
   if av == p2 then
    boxx-=1
   end
  spr(box.anim.sprite,boxx,box.y,1,1,av.flipped)
  end
 end
end

-->8
 --collisions

--convert box from av local
-- to global coords
function globalbox(av,box)
 return {
  x=av.x+box.x,
  y=av.y+box.y,
  width=box.width,
  height=box.height,
 }
end

function drawlocalbox(av,box,col)
 local lbox=globalbox(av,box)
 rectfill(lbox.x,
  lbox.y,
  lbox.x+lbox.width,
  lbox.y+lbox.height,col)
end

--only in x axis
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

function checkavflagarea(av,f)
 --check against the map we're drawing to the screen
 return checkflagarea(av.x+sstage.camerax,av.y+sstage.cameray,av.width,av.height,f)
end

function checkflagarea(x,y,w,h,flag)
 return
  checkflag(x/8,y/8,flag) or
  checkflag((x+w)/8,y/8,flag) or
  checkflag(x/8,(y+h)/8,flag) or
  checkflag((x+w)/8,(y+h)/8,flag)
end

function checkflag(x,y,flag)
 local s=mget(x,y)
 return fget(s,flag)
end

-->8
--animations

--can pass in singular sprite and speed
-- or sprites and one speed
function createanim(sprites,speeds,looping)
 local loop=true
 if looping==false then
  loop=false
 end

 local s=sprites
 if type(sprites)=="table" then
  s=sprites[1]
 end

 local t={
  --animation specifics
  speeds=speeds,
  sprites=sprites,
  looping=loop,

  --variables
  sprite=s,
  along=1,
  counter=0,
  t=time(),
  finished=false,
 }
 return t
end

--copes with single sprite
-- and single speed
function updateanim(a)
 if type(a.sprites)=="table" then

  --if some small amount of time
  -- has passed since last update,
  -- assume anim was interupted
  -- so restart anim
  -- note:may go weird after 9 hours...
  if time()-a.t > 1/30 then
   a.counter=0
   a.along=1
  end

  a.t = time()

  a.counter+=1

  --cope with no speed,
  -- a consistent number speed
  -- or a table of different speeds
  local speed=a.speeds or 5

  if type(a.speeds)=="table" then
    speed=a.speeds[a.along]
  end

  if a.counter>speed then
    a.counter=0

    a.along+=1
    if a.along>#a.sprites then

     --restart or
     -- stay on last frame
     if a.looping then
      a.along=1
     else
      a.finished=true
      a.along=#a.sprites
     end
    end
  end
  
  a.sprite=a.sprites[a.along]
 end
end

-->8
-- stages

function createstage(n,cx,cy,p1x,p1y,p2x,p2y)
 s={
  name=n,
  camerax=cx,
  cameray=cy,
  p1x=p1x,
  p1y=p1y,
  p2x=p2x,
  p2y=p2y
 }
 add(stages,s)
end

function outline(s,x,y,c1,c2)
 for i=0,2 do
  for j=0,2 do
   print(s,x+i,y+j,c1)
  end
 end
 print(s,x+1,y+1,c2)
end

title=
"1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f19091f1f1f1f12051f1f180f011f1f1f1c071f1f180583091f1f1f1408120218041f1a028b041f1e0c140911c20215081f19028c031f1b0f0813c61001150410021f1a018d031f180c830610cd021402c210011f1a018e031b03170385028412cfc110011401c310021f19018e04180a11028fcfc5021301c4021f190186118603150e100189112281cfc2051302c310011f190184211285001001150481028204892481cf11051501c310011f1901842113840310088804832381221082cc11051801c310011f1901842114840d88028324801021108301c01004c31004100bc310051f1501842115830511058e238a08c401110dc310071f130184211584021381038e22008910051001c401100fc710031f1201842115840187028d220188041302c306c307ca041f018421158401880183038522028412041401c304c903cb031f018421158f8503852210018811011401c303ca03cc031e028321158600238903852111028810011401c302c510c403c4d2c5021e0284168525880485210011038610011401c31100c3d310c203c3d410c3021f0184211485231184108204870b81021401c41000c3d310c302c3d312c2021f018421148521138410820110018a0810031401c411c210d112c302c3d213c2011f10018421138620120011870110018f80061501c411c210d112c401c3d213c2011f100184211386201100118801100183018a10031701c411c313c501c4d112c3011f10018421128813890110078a100210031301c411c412c610c4d111c4011f100184211288118b0110078811021109c41101cfc210c7011f10018421108f8405100211048510041109c41101c81002c001ca021f100184218f80028104170e1201cb1103c61007c7031f110184208800870281011c0a1401cb1005140ac2071f11018e008510071f1b02cb071105130b1f13018d0213091f1b02c904110717061f17018c0f1f1d0111c5100513041f1f18018a0b1f1f130e1f1f1f130189051f1f1a0b1f1f1f160189041f1f1f1f1f1f1e0186051f1f1f1f1f1f1f100185041f1f1f1f2e1f1f130b14db1f1f1a2f2c1f1a0813dfd21f1f172f2f1f170613dfd41f1f132b182f1f160118dfd41f1f112d8b15281f1fd4c6dc1f1c2a8f8413261f1dd3cbdd1f17268f8c11271f1bd2cfc0da1f15258f8f8011261f19d2cfc4d81f14248f8f8311251f18d2cfc8d51f12248f8f87241f17d2cfcbd41f1123108f8f88231f17d2cfccd31f10248f8f8a231f16d2cfccd31f10238f8f8b241f15d2cfcdd91922108f8f8c231f14d3cfceda1623108e698f83231f14d3cfcedb15238f6f6a83221f14d2cfcfc065d415228f816f6884221f14d2cfcfc065d414238f816f6884231f13d2cfcfc066d314238f816f6884231f13d2c3dfd1ca67d210268f826f678510221f13dfdac867d3278f816f678510221f12dfddc667d3288f816f668510221f11dfdfd0c467d4278f816f668510221eddccdac267d4278f826f6585231cdccfc1d9c167d42111228f8f8f231bd7cfcad768d425108f8f8f221bd6cfcdd668d482248f8f89e182221bd4cfcfd767d482268de88be682221ad4cfcfc1d667d486258aefea832219d4cfcfc3d666d3892587efeb832219d4cfcfc4d665d38b2486e123efe222822319d4cfcfc5d565d38e2285e124efe122822319d3cfcfc7d563d38f812184e125ee24822318d4c160cfcfc3d6078f830084e125ec24832318d4c160cfcfc3d614228f8be026e925832318d3c163cfcfc1d5122b8f86e124e825832418d3c16bcfc9d5102f208f84e123e824e0832319d3c16f69cbd4102f248f8121e022e823e0842319d2c26f69cb8020d12f278f8120efe184221ad2c26f69cb2f2c8f81efe084231ad2c26f68cc2b89278f81ee84241ad2c26f67cd288e268f8021ec84231bd2c26f67cc278f82258f21ec83241bd2c46f65cc248f86258e21ea291cd2c46f65cb248f89248d2714281dd3ca6eca238f8c238720832f261dd3cfcfc4238f8c24862f291fd3c2e3cfcc22608f8e23872f251f13d2c2e4cfca238f8f10228825842381231f13d3c1e5c9e7c660228f8f81238f89221f13d3c121efe5c6238f8f81238f8a221f12d3c122efe4c5d0238f8f82228f8a231f12d3c022efe5c4d0238f8f83218f8b241f10d3c123ee24c4d0238f8f83218f8b241f11d3c122ed25c4d0238f8d2183218f8c231f11d3c222ea27c4d0238f8c2283218f8c241f12d3c023e727c610238f8c2284218f8b251f11d3c122e725c810238f8b2384228f8b60231f12d3c0ea23e1d2c510238f8a2484228f8863241f11d3c1efd2c510238f8a23856020618f81607f72601bd510eed4c310248f8824846120618f8173d011d07010d075d010d07019daecd7c011238f8824836220628d611072d0107110781070107019d3c110d3c7e5d711248f862484622163836a7213d010d111d01170127018d3c6d0cdd711248f8524846210216f627111d07111701071107010701070107018d3c610ced611258f83258264226f6270d010d071d01070d011d01171d010d07018d3cfc311c2d412268f81248067226f627f7417d4cfc810d313278e25806721106f627f7417d3cfcc1060c32d85266a211061116e776052607716d4cfcc10c5102f286922146b1061775082507716d360cfcfc52f2668201f157010775082507716d263cfcfc62f2006c2011f187460528252607415d264cfc412ce2a051f1f147450927262507415d267cfc8d1c801cc011f1f147450927262507414d26acfc6d1cfc91f1f1471605292726252607114d26dcfc1d3cfc71f1f167150a278e2507114d26f60ced5cfc31f1f187150a278e2507114d26f65c9d5cfc11f1f1a7150a278e2507114d36f6ed5ce1f1f1d716052b272d252607114d66f6bd5cb1f1f1f107450b272d2507415d5106f6ad401c81f1f1f127450b272d2507416d5146f65d41003c11f1f1f16746052c252607417d4166f63d410011f1f1f1a7750c250771f1a6cd41f1f1f1d7750c250771f1f18d31f1f1f1d77605260771f1f18d11f1f1f1f607f726011"

hex2dec={["0"]=0,["1"]=1,["2"]=2,["3"]=3,["4"]=4,["5"]=5,["6"]=6,["7"]=7,["8"]=8,["9"]=9,["a"]=10,["b"]=11,["c"]=12,["d"]=13,["e"]=14,["f"]=15}

--taken from https://www.lexaloffle.com/bbs/?pid=40008
-- thanks to TRASEVOL_DOG!
function decompress_spsh(str,toscreen)
 local hline
 if toscreen then
  hline=function(cur,l,c)
    local x1,y1=cur%128,flr(cur/128)
    cur+=l
    local x2,y2=cur%128,flr(cur/128)
    if y1==y2 then
     rectfill(x1,y1,x2,y1,c)
    else
     rectfill(x1,y1,127,y1,c)
     rectfill(0,y2,x2,y2,c)
    end
   end
 else
  hline=function(cur,l,c)
    for i=cur,cur+l-1 do
     sset(i%128,i/128,c)
    end
   end
 end
 
 local cur=0
 local k=#str
 for lin=1,k,2 do
  local c=hex2dec[sub(str,lin,lin)]
  local l=hex2dec[sub(str,lin+1,lin+1)]+1
  
  hline(cur,l,c)
  cur+=l
 end
end


-->8
--particle effects

effects={}

function createeffect(update)
 e={
  update=update,
  particles={}
 }
 add(effects,e)
 return e
end

function updatepes()
 for e in all(effects) do
  e.update(e)
 end
end

function drawpes()
 for e in all(effects) do
  for p in all(e.particles) do
   circfill(p.x,p.y,p.r,p.col)
  end
 end
end

function createparticle(x,y,xvel,yvel,r,col,lifespan)
 p={
  x=x,
  y=y,
  xvel=xvel,
  yvel=yvel,
  r=r,
  col=col,
  lifespan=lifespan
 }
 return p
end

function initpedash(av)
 local e=createeffect(updatepestraight)

 local cols={5,6,7}
 if av.name=="red" then
  add(cols,8)
 else
  add(cols,12)
 end

 --out of front foot or back foot?
 local footpos=0
 if av.xvel>0 then
  footpos=av.width
 end

 for i=0,4 do
  local p=createparticle(
   av.x+footpos,av.y+av.height,
   -sgn(av.xvel),
   rnd(0.5)-0.35,
   rnd(2),cols[ceil(rnd(#cols))],
   rnd(12)+5)
  add(e.particles,p)
 end
end

function initpehit(x,y)
 local e=createeffect(updatepestraight)
 
 local cols={7,8,12}
 
 for i=0,20 do
  local p=createparticle(
   x,y,
   rnd(2)-1,
   rnd(6)-3,
   rnd(3),cols[ceil(rnd(#cols))],
   rnd(30)+5)
  add(e.particles,p)
 end
end

function updatepestraight(e)
 for p in all(e.particles) do
  p.x+=p.xvel
  p.y+=p.yvel
  
  p.lifespan-=1
  if p.lifespan<=0 then
   --fade out
   if p.r>=1 then
    p.r-=1
    p.lifespan=3+rnd(4)
   else
    del(e.particles,p)
   end
  end
 end

 if #e.particles==0 then
  del(effects,e)
 end
end

__gfx__
00000000d6666666cc7ccbbbd66666666666666dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4994bbbb4994bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000002dddddd667cccbbb2dddd6d66d6dddd2bbbbb888888888bbbbb888888888bbbbbbbbbbbbb4a88a4bb4acca4bbbbbbbbbbbbbbbbbbbbbbbbbbbbb5000
007007002d2666d676cccbbb27766c7667866772bbbb28887877782bbb28888878782bbbbbbbbbbbb988e79bb9cc679bbbbbbb000bbbbbbbbbbbbbbbbbbb5670
000770002d2dd6d6cccccbbb2cccccc778888882bbbb88888888878bbb88888888878bbbbbbbbbbbb9887e9bb9cc769b0000000670bbbbb000bb000bbbbb0770
000770002d2dd6d6cccccbbb2cccccc228888882bbbb888888888882bb888888888882bbbbbbbbbbb988889bb9cccc9b06777707700000006700670000000770
007007002d2222d6cccccbbb22222c2662822222bbb2828288888828b2828288888828bbbbbbbbbbb988889bb9cccc9b06767700006777770700775777770670
000000002dddddd6cccccbbb25ddd2d66d2ddd52bbb8882228888228b8882228888228bbbbbbbbbbb4a88a4bb4acca4b06755006707777770700770777770670
000000002222222dccccbbbb2222222dd2222222bbb8882222222228b8882222222228bbbbbbbbbbbb4994bbbb4994bb07777007707700006700770067000670
5ddddddd77777777bbbbbbbbbbbbbbbbbbbbbbbbbbbc7c8211ee1122b2882111221122bbbbbbbbbbbb4994bbbbbbbbbb077670077077006707777705770b5770
2555555d1d777777b51111000000000000001bbbbbccc7c8eeeee88bbb882c77cee88bbbbbbbbbbbb4adda4bbbbbbbbb077000077077007707777700770bb00b
255ddd5d171667d6b1bbbbbbbbbbbbbbbbbb65bbbbcccc7c8eee888bbb28cccc7c888bbbbbbbbbbbb9dd679bbbbbbbbb0770bb076077777707007700770bbbbb
25255d5d1d1dd6d6b1bbbbbbbbbbbbbbbbbb761bbbcccccc828b82bbbbbbcccccc82bbbbbbbbbbbbb9dd769bbbbbbbbb0670bb055067777707007700770b5000
25255d5d1d1dd6d6b567bbbbbbbbbbbbbbbbbb1bbbcccc1c888bbbbbbbbbcccc1c8bbbbbbbbbbbbbb9dddd9bbbbbbbbb0770bbbbbb05500007007700770b0670
2522255d1d1111d6bb56bbbbbbbbbbbbbbbbbb1bbb6cc1cc88bbbbbbbbbb6cc1cc8bbbbbbbbbbbbbb9dddd9bbbbbbbbb0000bbbbbbbbbbb005bb5000670b0660
2555555d1dddddd6bbb5100000000000011111dbbbb66c8888bbbbbbbbbbb66c188bbbbbbbbbbbbbb4adda4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000b5005
222222251111111dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbebbbbbbbbbbbebbbebbbbbbbbbbbbbbb4994bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
2222f22257777777bbbbb888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbb000bbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
2ffffff217777777bbbb88888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb067770bbb07770bbbb0670bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
2ffffff2157ddd7dbbb888888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0777770b0677770bb06770bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
fffffff215157d5dbbb8888888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb005670b0770770bbb0770bbbbbbbbbbbbbbbbbbbbbbbb88888888bb
2fffffff15155d5dbbb8888888888888bbbbbbbbbbbbb8888888888bbb28888888888bbbb066770bb007770bbb0770bbbbbb888888888bbbbbbbb2888888782b
fffffff21511155dbbb8888888888888bbbbbbbbbbbb888887877782bb888887777888bbb005670bb06750bbbb0770bbbbb28888878782bbbbbb88888888878b
2ffffff21555555dbbb8888118888118bbbbbbbbbbb8888888888878b88888888887888b0677770b0677770bbb0770bbbbb88888888878bbbbbb888888888882
2222f22211111115bbb8888511881158bbbbbbbbbbb8888888888888b88828888882888b0777770b0777770bbb0670bbbbb888888888882bbbb2888888222888
dddddd1dd6ddddddbbb8888851ee1588bbbbbbbbbbb8282888888882b88222888822288b000000bb0000000bbb0000bbbb2828288888828bbbb2888882211888
d11111111d66661dcccccc888eeee88bcccccbbbccccccccc2222222b88211111111188bbbbbbbbbbbbbbbbbbbbbbbbbbbc7c2228888228bbbb2888888221eeb
d6dddd1dd611116dccc67c88eeee888bccc67cbbcc67777ccc111111b88ccccccccccc8bbbbbbbbbbbbbbbbbbbbbbbbbbccc7c211221128bbbbb28828222226c
d6d11d1dd61dd16dcccc6c88888888bbcc76ccbbcccccccccceeee88b8cc777777cccccbbbbbbbbbbbbbbbbbbbbbbbbbbcccc7c1eee1228bbbbbb888888886cc
d6d61d1dd616d16dcccc1c8888bbbbbbccccccbbcccccccccceee888b8ccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbcccccceeeee88bbbbbb2888888886cc
d6dddd1dd611116dcccc1c8888bbbbbb1cccccbbcccccccccc28b82bbbccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbcccc1c22ee888bbbbb88888888816dc
6d66661dd16666d6cccc1b8888bbbbbb1ccccdbbccccccccc28bbbbbbbbcccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbb6cc1cc888b82bbbbb28888888bbbb6d
d6dddddddddddd1dbbbbbbebbbebbbbbbcccdbbbbbbebbebbbbbbbbbbbbbbbbbbebbbbebbbbbbbbbbbbbbbbbbbbbbbbbbb66cbbbbebbbbbbbebbbbbbbebbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888878bbbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2888888888888bbbbb28888878782bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbb888888888bb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8828288888828bbbbb88888888878bbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbb2888888782bbbbb28888878782b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8882228888228bbbb2888888888882bbbbbb28888888bbbbbbb8888888782bbbbb88888888878bbbbb88888888878b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbc7c2212221228bbbb8828288888828bbbbb2888787772bbbbb888888888788bbbb888888888882bbb2888888888882
bb28888888888bbbbbb28888888888bbbccc7c812ee1228bbbb8882228888228bbbb288888888888bbb2888888822882bbb2888888222888bbb8828288888828
b2888888888888bbbc7c88888888888bbcccc7ceeeee888bbbb8882111221128bbbb888888888888bbb2888882212888bbb2888882211888bbb8882228888228
288c7c888888888bccc7c88888888888bcccccc8eee888bbbbc7c82212ee1228bbccccccccccccccbbb288888822128dbbb2888888221eebbbb2882111221118
28ccc7c88888288bcccc7c8888888288bcccc1c828888bbbbccc7c88eeeee88bbbcccc666666677cbbbb28828222226cbbbb28828222226cbbbc6777776666cc
28cccc7c8882288bcccccc8288882288b6cc1cc2888bbbbbbcccc7c88eee882bbccccccccccccc6cbbbbb888888886ccbbbbb888888886ccbbbccccccccccccc
28cccccc8211188bcccc1c8112211188bb66cb88888bbbbbbcccccc2828b82bbbcccccccccccccccbbbb2888888886ccbbbb2888888886ccbbbccccccccccccc
286ccc1c8e22888b6cc1cc82eee22888bbbbbb88888bbbbbbcccc1c8888bbbbbccccccccccccccccbbb88888888816dcbbb88888888816dcbbbccccccccccccc
288661cc8e8888bbb66c8882eee8888bbbbbbb88888bbbbbb6cc1cc8888bbbbbccccccccccccccccbb28888888bbbb6dbb28888888bbbb6dbbb6cccccccccccb
b288888888828bbbbbb88888888828bbbbbbbbebbbebbbbbbb66bbebbbebbbbbbebbbbbbbbebbbbbbebbbbbbbebbbbbbbebbbbbbbebbbbbbbbbbbccccccc6bbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc67cbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbbbbbbbbbbbbbbbb
bbbbb888888888bbbb28888878782bbbbbbb888888888bbbbbbbbbbbbbbbbbbbcc76ccbbbbbbbbbbbbbb888888888bbbbb88888888878bbbbbbb88888888bbbb
bbbb28887877782bbb88888888878bbbbbb28888878782bbbbbbbbbbbbbbbbbbccccccbbbbbbbbbbbbb28888888782bbb2888888888882bbbbb28888877882bb
bbbb88888888878bbb888888888882bbbbb88888888878bbbbbbbbbbbbbbbbbb1cccccbbbbbbbbbbbbb88888888778bbb8828288888828bbbbb88888888878bb
bbbb888888888882b2828288888828bbbbb888888888882bbbbbbbb88888888b1ccccdbbbbbbbbbbbb288c7c8878882bb8882228888228bbbb2888888888882b
bbb2828288888828b8882228888228bbbb2828288888828bbbbbbb8888888788bcccdbbbbbbbbbbbbb88ccc7c888828bb8888212222128bbbb8828888888888b
bbb8882228888228b8882222222228bbbbc7c2228888228bbbbbb88888888878bbbbbbbbbbbbbbbbbb88cccc7c88288bbc7c8881ee1222bbbb8882288888828b
ccccccc222222228b88888ccccccccbbbccc7c111221128bbbbb288888882287ccccccdb7777776bbb28cccccc22128bccc7c88eeee88bbbbc7c88228888228b
c677777c11ee1122b28888c67777cccbbcccc7c1eee1e82bbbbb288888222287ccc7777c77777777bb28cccc1ce1e88bcccc7ceeee882bbbccc7c1811221188b
cccccccceeeee88bbb2888cccccccccbbcccccc2eeee88bbbbbb288888811177cc7677cc77777777bb286cc1ccee88bbcccccc888828bbbbcccc7c8222e2882b
cccccccc8eee888bbbbb28cccccccccbbcccc1c82ee888bbbbbb828828222277cccccccc77777777bbb2866c12e882bbcccc1c8888bbbbbbcccccc882ee888bb
cccccccc828b82bbbbbbb8cccccccccbb6cc1cc888b82bbbbb888888888822771cccccccd7777777bbbb222288b28bbb6cc1cc8888bbbbbbcccc1c2288b28bbb
cccccccc88bbbbbbbbbbbb8ccccccccbbb66c88888bbbbbbb888888888bbbbbb1cccccdbd777776bbbbbb88888bbbbbbb66cbb8888bbbbbb6cc1cc8888bbbbbb
bbbbebbbebbbbbbbbbbbbbebbbebbbbbbbbbebbbbbebbbbbebbbbbbbbbebbbbbbccccdbbb77776bbbbbbebbbbbebbbbbbbbbbbebbbebbbbbb66cbebbbbebbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbb
bbbb28888878782bbbbbb288888882bbbbbbb288888882bbbbbb28888878782bbbb28888878782bbbbbb288888882bbbbbbb288888882bbbbbb28888878782bb
bbbb88888888878bbbbb28888878782bbbbb28888878782bbbbb88888888878bbbb88888888878bbbbb28888878782bbbbb28888878782bbbbb88888888878bb
bbb2888888888882bbbb88888888878bbbbb88888888878bbbb2888888888882bb2882888888882bbbb88888888878bbbbb88888888878bbbb2882888888882b
bbb8888288888828bbb2888888888882bbb2888888888882bbb8888288888828bb8822288888828bbb2882888888882bbb2882888888882bbb8822288888828b
bbb8888228888228bbb8888288888828bbb8888288888828bbb8888228888228bb8822228888228bbb8822288888828bbb8822288888828bbb8822228888228b
bc7c888211121128bc7c888228888228bbb8888228888228bbb8888211121128bbc7c2112211228bbbc7c2228888228bbb8822228888228bbb8822112211228b
ccc7c288e1ee1228ccc7c88211121128bc7c888211121128bc7c8888e1ee1228bccc7c122e12228bbccc7c112211228bbbc7c2112211228bbbc7c2122e12228b
cccc7c888eeee28bcccc7c8821ee1228ccc7c88821ee1228ccc7c2888eeee28bbcccc7ceeeee88bbbcccc7c22e12228bbccc7c122e12228bbccc7c8eeeee88bb
cccccc2888ee288bcccccc888eeee28bcccc7c888eeee28bcccc7c2888ee288bbcccccc8eee882bbbcccccceeeee88bbbcccc7ceeeee88bbbcccc7c8eee882bb
cccc1c22828888bbcccc1c2888ee288bcccccc2888ee288bcccccc22828888bbbcccc1c828b88bbbbcccc1c8eee882bbbcccccc8eee882bbbcccccc828b88bbb
6cc1ccb88882bbbb6cc1cc22828888bbcccc1c22828888bbcccc1cb88882bbbbb6cc1cc888bbbbbbb6cc1cc828b88bbbbcccc1c828b88bbbbcccc1c888bbbbbb
b66cbbb88888bbbbb66cbbb88888bbbb6cc1ccb88888bbbb6cc1ccb88888bbbbbb66cb8888bbbbbbbb66cb8888bbbbbbb6cc1cc888bbbbbbb6cc1cc888bbbbbb
bbbbbbbebbbebbbbbbbbbbbebbbbebbbb66bbbbebbbbebbbb66bbbebbbebbbbbbbbbbbebbebbbbbbbbbbbbebbbebbbbbbb66cbebbbebbbbbbb66cbbbebbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbb
bbbb28888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbbb28888878782bbbbbb888888888bbb
bbb2888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbb88888888878bbbbb28888878782bb
bbb88888888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888878bbbb2888888888882bbbb88888888878bb
bcc7c288888888bbbbbbb2888888bbbbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbbb888888888bbbb2888888888882bbb8828288888828bbb2888888888882b
cccc7c288888282bbbcccc88877882bbbbbbb88888888bbbbbbb28888877882bbbbb28888878782bbb8828288888828bbb8882218881228bbb8828288888828b
cccc7c212222188bccc67cc8888788bbbbbb28888877882bbbbb88888888878bbbbb88888888878bbb8882111811128bbbc7c2121212128bbb8882218881228b
cccccc821221288bbccc7cc88888882bbbbb88888888878bbbb2888888888882bbb2888888888882bb8882222222228bbccc7c222ee2228bbbc7c8221212128b
6cc1cc88ee22888bbccccc7c8888888bbbb2888888888882bbb8828888888888bbc7c28288888828bb8888222ee2228bbcccc7ceeeee88bbbccc7c822ee2228b
b61cc288eee2888bbbcccc7c8888828bbbb8828888888888bbc7c82288888828bccc7c2228888228bbc7c88eeeee88bbbcccccc8eee888bbbcccc7ceeeee88bb
bbb288888ee888bbbbcccccc8888228bbbb8882288888828bccc7c8228888228bcccc7c212222128bccc7c88eee888bbbcccc1c828b82bbbbcccccc8eee888bb
bbbb288288bb8bbbbbcccccc2222288bbcccc7c228888228bcccc7c811221188bcccccc221ee1228bcccc7c828b82bbbb6cc1cc888bbbbbbbcccc1c828b82bbb
bbbbb88888bbbbbbbbcccccc22e2882bbccccc7811221188bcccccc8222e2882bcccc1c8eeeee88bbcccccc888bbbbbbbb66c88888bbbbbbb6cc1cc888bbbbbb
bbbbb88888bbbbbbbbcccccc2ee888bb6ccccccc222e2882bcccc1c882ee888bb6cc1cc88eee888bbcccc1c888bbbbbbbbbbbebbbbebbbbbbb66ce8888bbbbbb
bbbbb88888bbbbbbbbcccccc88b28bbb6ccccc1c82ee888bb6cc1cc2288b28bbbb66cb82828b82bbb6cc1cc888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbb
bbbbbebbbebbbbbbbbcccccc88bbbbbbb6ccc1cc288b28bbbb66cb28888bbbbbbbbbbb28888bbbbbbb66cbebbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbb288888882bb
bbbb88888888bbbbbbbb88888888bbbbbbbb288888888bbbbbbb288888888bbbbbbbb888888888bbbbb88888888bbbbbbbbb28888878782bbbbb28888878782b
bbb28888877882bbbbb28888877882bbbbb28888887782bbbbb28888887782bbbbbb28888878782bbb28888877882bbbbbbb88888888878bbbbb88888888878b
bbb88888888878bbbbb88888888878bbbbb88888888878bbbbb88888888878bbbbbb88888888878bbb88888888878bbbbbb2888888888882bbb2888888888882
bb2888888888882bbc7c88888888882bbb2888888888882bbb2888888888882bbbb2888888888882b2888888888882bbbbb8828288888828bbb8828288888828
bc7c28888888888bccc7c2888888888bbb8888888888888bbb8888888888888bbbb8828288888828b8828888888888bbbbb8882228888228bbb8882228888228
ccc7c2288888828bcccc7c288888828bbb88c7c28888288bbb8888c7c888288bbbb8c7c228888228b8882288888828bbbbc7c88111221128bbbc7c2111221128
cccc7c228888228bcccccc228888228bbb2ccc7c2222128bbb888ccc7c22118bbbbccc7c11221128bc7c8228888228bbbccc7c8212ee1228bbccc7c212ee1228
cccccc811221188bcccc1c822222288bbb2cccc7cee1e88bbb888cccc7c2188bbbbcccc7ceee1222ccc7c111221188bbbcccc7c8eeeee88bbbcccc7ceeeee88b
cccc1c8222e2882b6cc1cc8222e2882bbb2cccccceee88bbbb288cccccce88bbbbbcccccceeee88bcccc7c222e2882bbbcccccc88eee882bbbcccccc8eee882b
6cc1cc882ee888bbb66cb2882ee888bbbbbcccc1c2e882bbbbb28cccc1c882bbbbbcccc1ceee888bcccccc82ee888bbbbcccc1c8828b82bbbbcccc1c828b82bb
b66cb22288b28bbbbbbbb82288b28bbbbbb6cc1cc8b28bbbbbbb26cc1cc28bbbbbb6cc1cc2bb82bbcccc1c288b28bbbbb6cc1cc8888bbbbbbb6cc1cc888bbbbb
bbbbbee888ebbbbbbbbbbee888ebbbbbbbbb66c228bbbbbbbbbb2266c22bbbbbbbbb66c888bbbbbb6cc1cc888bbbbbbbbb66cb88888bbbbbbbb66c88888bbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbebbbbbbbbbebbbbbebbbbbbbbbbebbbbebbbbbb66cbebbbebbbbbbbbbbbbebbbebbbbbbbbbbbebbbebbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bb
bbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782b
bbbb28888878782bbbbbbbbbbbbbbbbbbbbbb288888882bbbbb88888888878bbbbb28888878782bbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbb88888888878b
bbbb88888888878bbbbbb288888882bbbbbb28888878782bbb2888888888882bbbb88888888878bbbbb288888882bbbbbbb28888878782bbbbb2888888888882
bbb2888888888882bbbb28888878782bbbbb88888888878bbb8828288888828bbb2888888888882bbb28888878782bbbbbb88888888878bbbbb8828288888828
bbc7c28288888828bbb288888888878bbbb2888888888882bb8882228888228bbb8888288888828bbb28888888878bbbbb2888888888882bbbbc7c2228888228
bccc7c2228888228bc7c888888888882bbb8828288888828bb8882111221128bbb8882228888228bb2888888888882bbbb882c7c8888828bbbccc7c211221128
bcccc7c111221128ccc7c82888888828bc7c882228888228bb2888212ee1228bbb8882111221128bb288c7c8888828bbbb88ccc7c888228bbbcccc7c12ee1228
bcccccc212ee1228cccc7c8228888228ccc7c22111221128bbc7c88eeeee88bbbb2c7c212ee1228bb28ccc7c888228bbbb88cccc7c21128bbbcccccc8eeee88b
bcccc1c8eeeee88bcccccc8111221128cccc7c8212ee1228bccc7c88eee882bbbbccc7c2eeee88bbb28cccc7c21128bbbb88cccccc21228bbbcccc1c88ee882b
b6cc1cc8eeee882bcccc1c8212221228cccccc88eeeee88bbcccc7c828882bbbbbcccc7ceee882bbb28cccccce1228bbbb28cccc1cee88bbbb6cc1cc888b82bb
bb66cb88228b82bb6cc1cc88eeeee88bcccc1c288eee882bbcccccc8888bbbbbbbcccccc22882bbbb28cccc1cee88bbbbbb86cc1cce882bbbbb66c88888bbbbb
bbbbbb88888bbbbbb66cb8888eee882b6cc1cc82828b82bbbcccc1c8888bbbbbbbcccc1c888bbbbbbb86cc1cce882bbbbbbb266c22282bbbbbbbbb88888bbbbb
bbbbbb88888bbbbbbbbbbb22828b82bbb66cbb88888bbbbbb6cc1cc8888bbbbbbb6cc1cc888bbbbbbbbb66c88882bbbbbbbbbb88228bbbbbbbbbbb88888bbbbb
bbbbbbebbbebbbbbbbbbbbebbbbebbbbbbbbbbebbbbebbbbbb66cbebbbebbbbbbbb66cebbbebbbbbbbbbbebbbbebbbbbbbbbbebbbbebbbbbbbbbbbebbbebbbbb
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111110000000000111111111111111111111111111111111111111111111111111111111111111111100000011111111111111111111111111111111111
11111100000000000000000011111111111111111111111111111111111111111111111111111111111110000000011111111111111111111111111111111111
11111100000088880000000000111111111111111111111111111111111111111111111111111110000000001110001111111110000011111111111111111111
1111111000888888888888000001111111111111111111111111111111000000000000011111000000000011ccc0001111110000000001111111111111111111
111111100088888888888880000111111111111111111111111111100000000000000000000000001111ccccccc1001111110000010001111111111111111111
111111110088888888888888000011111111111111111111111110000000000000888800000001cccccccccccccc00011111000ccc1001111111111111111111
11111111008888888888888880000111111111111000011111111000088888800088888111cccccccccccccccccc1001111100cccc1000111111111111111111
11111111008888888888888880000011111111100000000000110008888888888888888cccccccccccccccccccccc000111100ccccc000111111111111111111
11111111008888888118888888000011111100000000000000010088888888881122288ccccccccccccccccccc0000001111000cccc100111111111111111111
11111111008888822111888888010011111100000880008880000088888888882222288cccccccccccccccc1100000011111100cccc100111111111111111111
11111111008888822111188888000010000000008888888880000088882222882221888ccccccccccccc1100000011111111100cccc100111111111111111111
1111111100888882211111888880000000000000088888888800088882222281221888800c100000cccc1000001000000000000cccc100000011111111111111
11111111008888822111111888800000011000000888888888888888222288888888888000000000ccccc001100000000000000cccc100000000111111111111
11111111008888822111111888880001111880000888888888888888222088888888881000000100ccccc0010000000000000000cccccccc1000011111111111
111111110088888221111118888800888888880008888888888888822200888888888000001111000cccc0000000cccc00000000ccccccccccc0000011111111
111111110088888221111118888800888888888008888000088888822200088888111000001111100cccc00000cccccccccc0000cccccccccccc000011111111
111111110088888221111118888888888888888888888000088888822210088888888811001111100cccc0000ccccccccccc0000ccccccccccccc00001111111
111111110008888221111118888888022228888888888000088888822110008888888881001111100cccc000cccccc1ccccc0000cccccdddcccccc0001111111
111111110008888811111118888882222228888888880000088888822011000088888881001111100cccc110ccccdddd1ccc0000ccccddddd1cccc0001111111
111111111008888822111118888882222118888818880000088888888000000000000880001111100ccccc10ccccdddd1cccc000ccccdddd111ccc0001111111
111111111008888822111118888882211118888818880010088888888888000000000100001111100ccccc11ccc1dd111cccc000ccccddd1111ccc0011111111
111111111008888822111188888882111011888888880010088888888888888888000000011111100ccccc11ccc1dd111ccccc00ccccddd1111ccc0011111111
111111111008888822111188888882110118888888880010088880088888888888100001111111100ccccc11cccc1111cccccc00cccccdd111cccc0011111111
111111111008888822111888888888111188888888880010000000088888888888100010000111100ccccc11ccccc111ccccccc1cccccdd11ccccc0011111111
111111111008888822111888888888118888888888880010000000088888888811000110000000000ccccc1100ccccccccccccccccccc1cccccccc0011111111
111111111008888822188888888888888888888800000010001100000888888100000110000000000ccccc1100ccccccccc1000c00ccccccccccc00011111111
1111111110088888228888888888888888800088000001111111100000000000000011100cccccccccccc110000ccccccc100000000cccccccc0000111111111
1111111110088888288888888808888888800088001111111111111000000000001111100cccccccccccc10000001111100000000000ccc00000000111111111
1111111110088888888888888808888881000000001111111111111111111111111111000cccccccccccc0000000011000000111100000000000011111111111
1111111110088888888888888000111100000000001111111111111111111111111111000cccccccccc000001100000000111111110000000111111111111111
11111111100888888888888800000000000000001111111111111111111111111111110011cccccc100000011110000011111111111111111111111111111111
11111111100888888888880000000000001111111111111111111111111111111111110000000000000001111111111111111111111111111111111111111111
11111111100888888888800000011111111111111111111111111111111111111111110000000000001111111111111111111111111111111111111111111111
11111111100888888888800000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111100888888800000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111100888888000001111111111111111111111111111111111111111111111111111111111111111222222222222222111111111111111111111111111
11111111100000000000011111dddddddddddd111111111111111111111111111111111111111111122222222222222222222222222222111111111111111111
1111111110000000001111ddddddddddddddddddd111111111111111111111111111111111111111122222222222222222222222222222222111111111111111
11111111100000001111ddddddddddddddddddddd111111111111111111111111111111111111222222222222111111111222222222222222211111111111111
11111111100111111111ddddddddddddddddddddd111111111111111111111111111111111122222222222222888888888888111111222222222111111111111
11111111111111111111dddddcccccccddddddddddddd11111111111111111111111111111222222222228888888888888888888881111222222211111111111
1111111111111111111ddddccccccccccccdddddddddddddd1111111111111111111111112222222888888888888888888888888888881122222222111111111
1111111111111111111dddcccccccccccccccccddddddddddd111111111111111111111122222288888888888888888888888888888888811222222211111111
111111111111111111dddcccccccccccccccccccccddddddddd11111111111111111111122222888888888888888888888888888888888888112222221111111
111111111111111111dddcccccccccccccccccccccccccdddddd1111111111111111111222228888888888888888888888888888888888888888222221111111
11111111111111111dddccccccccccccccccccccccccccccddddd111111111111111111222218888888888888888888888888888888888888888822221111111
11111111111111111dddcccccccccccccccccccccccccccccdddd111111111111111112222288888888888888888888888888888888888888888882222111111
11111111111111111dddcccccccccccccccccccccccccccccdddd111111111111111112222888888888888888888888888888888888888888888882222211111
11111111111111111dddccccccccccccccccccccccccccccccdddddddddd11111111112221888888888888888888888888888888888888888888888222211111
1111111111111111ddddcccccccccccccccccccccccccccccccddddddddddd111111122221888888888888888666666666688888888888888888888222211111
1111111111111111ddddcccccccccccccccccccccccccccccccdddddddddddd11111122228888888888888888666666666666666666666666666888822211111
1111111111111111dddccccccccccccccccccccccccccccccccc666666ddddd11111122288888888888888888866666666666666666666666668888822211111
1111111111111111dddccccccccccccccccccccccccccccccccc666666ddddd11111222288888888888888888866666666666666666666666668888822221111
1111111111111111dddccccccccccccccccccccccccccccccccc6666666dddd11111222288888888888888888866666666666666666666666668888822221111
1111111111111111dddccccddddddddddddddddddccccccccccc66666666ddd12222222888888888888888888866666666666666666666666688888812221111
1111111111111111dddddddddddddddddddddddddddccccccccc66666666dddd2222222288888888888888888866666666666666666666666688888812221111
111111111111111ddddddddddddddddddddddddddddddccccccc66666666dddd2222222228888888888888888886666666666666666666666688888812221111
11111111111111dddddddddddddddddddddddddddddddddccccc66666666ddddd222222228888888888888888886666666666666666666666688888812221111
11111111111ddddddddddddddcccccccccccccdddddddddddccc66666666ddddd222222228888888888888888888666666666666666666666688888822221111
111111111dddddddddddddccccccccccccccccccddddddddddcc66666666ddddd221122288888888888888888888888888888888888888888888888822221111
11111111ddddddddcccccccccccccccccccccccccccdddddddd666666666ddddd222222188888888888888888888888888888888888888888888888822211111
1111111dddddddccccccccccccccccccccccccccccccddddddd666666666ddddd88822222888888888888888888888888888888888888888888ee88822211111
1111111dddddccccccccccccccccccccccccccccccccdddddddd66666666ddddd888222222288888888888888eeeeeeeee888888888888eeeeeee88822211111
111111dddddccccccccccccccccccccccccccccccccccddddddd66666666ddddd888888822222288888888888eeeeeeeeeeeeeeeeeeeeeeeeeee888822211111
11111dddddccccccccccccccccccccccccccccccccccccddddddd6666666dddd888888888822222288888888eeeeeeeeeeeeeeeeeeeeeeeeeeee888822211111
11111dddddcccccccccccccccccccccccccccccccccccccddddddd666666dddd888888888888222228888888ee2222eeeeeeeeeeeeeeeeeee222888222211111
11111dddddccccccccccccccccccccccccccccccccccccccdddddd666666dddd888888888888888222888888ee22222eeeeeeeeeeeeeeeeee222888222211111
11111ddddccccccccccccccccccccccccccccccccccccccccdddddd6666dddd8888888888888888882288888ee222222eeeeeeeeeeeeeee22222888222211111
1111dddddcc6ccccccccccccccccccccccccccccccccccccddddddd0000000088888888888888888888088888ee222222eeeeeeeeeeeee222228888222211111
1111dddddcc6ccccccccccccccccccccccccccccccccccccddddddd111112228888888888888888888888888888e2222222eeeeeeeeee2222228888222211111
1111ddddcc6666ccccccccccccccccccccccccccccccccccdddddd11122222222222288888888888888888888888ee22222eeeeeeeee22222288882222211111
1111ddddcc666666666666ccccccccccccccccccccccccccdddddd122222222222222222888888888888888888888ee2222eeeeeeeee22222e88882222111111
1111ddddcc66666666666666666666666666ccccccccccccddddd122222222222222222222288888888888888888822e222eeeeeeeee2222e888882222111111
1111dddccc66666666666666666666666666cccccccccccc82dd2222222222222222222222228888888888888888882eeeeeeeeeeeeeeeeee888882221111111
1111dddccc66666666666666666666666666cccccccccccc22222222222222222222222222222888888888888888888eeeeeeeeeeeeeeeee8888822221111111
1111dddccc6666666666666666666666666ccccccccccccc222222222222888888888822222222888888888888888888eeeeeeeeeeeeeee88888222221111111
1111dddccc666666666666666666666666cccccccccccccc22222222288888888888888822222228888888888888888822eeeeeeeeeeeee88888222211111111
1111dddccc666666666666666666666666ccccccccccccc222222228888888888888888888222222888888888888888822eeeeeeeeeeeee88882222211111111
1111dddccccc6666666666666666666666ccccccccccccc222228888888888888888888888822222288888888888888822eeeeeeeeeee2222222222111111111
1111dddccccc6666666666666666666666cccccccccccc2222288888888888888888888888888222228888888888888822222222111112222222221111111111
1111ddddccccccccccc666666666666666ccccccccccc22228888888888888888888888888888822228888888828888222222222222222222222221111111111
1111ddddccccccccccccccccccccccccccccccccccccc22228888888888888888888888888888822222888888822222222222222222222222222111111111111
1111ddddccceeeeccccccccccccccccccccccccccccc222688888888888888888888888888888882222888888882222222222222222222222111111111111111
11111dddccceeeeeccccccccccccccccccccccccccc2222888888888888888888888888888888881222888888888222222888882222882222111111111111111
11111ddddcceeeeeecccccccccceeeeeeeeccccccc62228888888888888888888888888888888888222288888888888888888888888888222111111111111111
11111ddddcc22eeeeeeeeeeeeeeeeeeeeeeccccccc22228888888888888888888888888888888888222288888888888888888888888888822211111111111111
11111ddddcc222eeeeeeeeeeeeeeeeeeeeeccccccd22228888888888888888888888888888888888822288888888888888888888888888822221111111111111
111111ddddc222eeeeeeeeeeeeeeeeeeeeeecccccd22228888888888888888888888888888888888882288888888888888888888888888882222211111111111
111111ddddcc2222eeeeeeeeeeeeeee22222cccccd22228888888888888888888888888888888888882288888888888888888888888888882222211111111111
1111111ddddcc222eeeeeeeeeeeeee222222cccccd22228888888888888888888888888888882288882288888888888888888888888888888222211111111111
1111111ddddccc222eeeeeeeeeee22222222cccccd22228888888888888888888888888888822288882288888888888888888888888888888222221111111111
111111111ddddc2222eeeeeeee22222222ccccccc122228888888888888888888888888888822288888228888888888888888888888888888222222111111111
111111111ddddcc222eeeeeeee222222ccccccccc122228888888888888888888888888888222288888222888888888888888888888888888862222111111111
1111111111ddddceeeeeeeeeee2222eedddcccccc122228888888888888888888888888882222288888222888888888888888888888888866662222211111111
1111111111ddddcceeeeeeeeeeeeeeeedddcccccc122228888888888888888888888888882222888888626688888888888888888867777777777777777777611
1111111111dddddd1eeeeeeeeeeeeeeedddddcccc12222288888888888888888888888882222288888662668888888888888888887777d11d71d777777d1d711
11111111dddddddddddeeeeeeeeeeeeeddddddddc1122228888888888888888888888888222228888666266688888888888888661777d1771777777777171711
11111111ddddcc1ddddcccccccceeeeeedddddddd11222228888888888888888888888822222888886662266668888666666666667771111d1dd11d117111711
1111111ddddcccccccdccccccccccccccdddddddd11222228888888888888888888888222228888866612266666666666666666667711d771171771717171711
1111111ddddccccccc1cccccccccccccccddddddd11222222888888888888888888882222228886666622266666666666666666667d1d77d17d11d1177d1d711
1111111ddddcccccccccccccccccccc11cccddddd111222222288888888888888888822222866666666222666666666666666666677777777777777777777711
111111dddddccccccccccccccccccccccccc1dddd111122222222888888888888888222222866666666221666666666666666666677777777777777777777711
111111ddddccccccccccccccccccccccccccccc16cccc22222222222222888888222222266666666666221661166666666666666677777777655567777777711
11111dddddccccccccccccccccccccccccccccc1cccccc1222222222222222222222222266666666662221111166666666666616677777777588857777777711
11111dddd6cccccccccccccccccccccccccccccccccccccc22222222222222222222222666666666211111111111111111111117177777777588857777777711
11111ddd6666ccccccccccccccccccccccccccccccccccccccc222222222222222220000000ccc00111111111111111111111111177777655588855567777711
1111ddd66666ccccccccccccccccccccc111ccccccccccccccc22222222222000000111111111111111111111111111111111111177777599977766657777711
1111ddd66666666cccccccccccccccccccccccccddccccccccc00ccccccccccccc00111111111111111111111111111111111111177777599977766657777711
111ddd66666666666cccccccccccccccccccccccddcccccccccccccccccccccccccc111111111111111111111111111111111111177655599977766655567711
111ddd66666666666666ccccccccccccccccccddddcccccccccccccccccccccccc111111111111111111111111111111111111111775aaa777777777eee57711
111ddd66666666666666666cccccccccccccccddddddcccccccccccccccccccc11111111111111111111111111111111111111111775aaa777777777eee57711
111ddd6666666666666666666666ccccccccccddddddcccccccccccccccccc1111111111111111111111111111111111111111111775aaa777777777eee57711
111dddd6666666666666666666666666666666ddddddccccccccccccccc1111111111111111111111111111111111111111111111776555bbb777ddd55567711
111ddddddd6666666666666666666666666666ddddddcccccccccccc1111111111111111111111111111111111111111111111111777775bbb777ddd57777711
1111dddddd1666666666666666666666666666ddddd00ccccccccc111111111111111111111111111111111111111111111111111777775bbb777ddd57777711
11111dddddd111116666666666666666666666ddddd10000cc1111111111111111111111111111111111111111111111111111111777776555ccc55567777711
111111ddddd111111166666666666666666666ddddd10011111111111111111111111111111111111111111111111111111111111777777775ccc57777777711
11111111111111111111111116666666666666ddddd11111111111111111111111111111111111111111111111111111111111111777777775ccc57777777711
111111111111111111111111111111111111111dddd1111111111111111111111111111111111111111111111111111111111111177777777655567777777711
111111111111111111111111111111111111111dd111111111111111111111111111111111111111111111111111111111111111167777777777777777777611

__gff__
0001000503000000000000000000000001090000000000000000000000000000010900000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000001100110011001100110011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000011001100110011001100110000000000000100110011001100100000000000001100110011001100110011000000000040404040401100303030303000000000303030303011004040404040000000021112111211121112111211100000000000000000000000000000000000000000000000000000000000000000000
0000100110011001100110011001000000000000011001100110011000000000000000000000000000000000000000000000011001100110011001100110000000000110011001100110011001100000000001100110011001100110011000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011100140e0501a050000000e0501a0500000010050100501c0501c050110501a05000000110501a0500000013050130501005010050000000000000000000000000000000000000000000000000000000000000
010e002030625306250c0530c05330625306250c0530c0530c0533064500000000003062500000306253062530625306250c0530c05330625306250c0530c0530c05330645000000000030625000003062530625
0107000029742297101d7001d70020000200002000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000035770357723577035760357503574035730357202f7002f7002f0002c0002c7002f7002f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000187611c7411f0312d02102402024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200001b7611f74122031300212830024300203001b30017300123000d300073000130001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000030620306151b6031b6031b603106031010310003076030700307103000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500201f624000001a6001a6251d600000001f600000001d62500000000001f624000000000000000000001f624000001a6001a6251d600000001f600000001d62500000000001f62400000000000000000000
01040000286410c00115651166510d641100331462311013106130c0130b613000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000396550a053000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900002d6550a0530a0130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000096550a7251673516715396000a000396000a000396000a000396000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000035670296701b6631b6631b65310643101430c643076330362300613006130000000613006130000000003000030000400000000000000000000000000000000000000000000000000000000000000000
010a0000396550a053002000060000200006000020000600002000060000200006000020000600002000060000200006000020000600002000060000200006000020000600002000060000300006000050000600
010b0000396550a033396350a023396150a613396150a613396150a613396150a6130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000035751310552b76326055227502805024763200451b743220451d7431b035167331b03518733160351372311020137200f0230a715070130a715070130571505013007150000300000000000000000000
010d00001f7521f0321f7221f0121300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000700007000050001b0201d7311d0421f761
01070000246451860018600186000c0000c0000c0000c0000c0730c0000c00027200246001860018600186000c0733f200246000c0000c0000c0003f2002720024655186001860018600186000c6000000000000
01070000246651864518625186150c0730c0130c0000c0000c0730c0130c00027200246651863518625186150c0733f200246000c0000c0730c0003f2002720024665186451863518625186150c600000001f700
010d00000c0630c000000000c60024645186250c6150c0000c0000c0000c0630c0000c0000c0000c0630c00024645186250c0630c00000000000000c0430c0430c0530c0000c0430000024655186250c61500000
010d00000c0633f215272152721524645186253f2150c0003f2003f2150c0630f21527215272150c0630c00024645186250c6150c0633f2150c0630c0430c0430c0533f2150c0433f21524655186250c6150c615
010d00200c0730c000000000c60024655186450c6250c0003f200272000c0730c0003f200272000c0733f21524665186550c0233f22524665186550c0230c0433f225272150c0433f21524655186450c6250c615
010d00200c0633f215272152721524645186253f2150c0003f2003f2150c0630f21527215272150c0630c00024645186250c6150c0633f2150c0630c0430c0430c0533f2150c0433f21524655186250c6150c615
010d00200c0630c000000000c60024645186250c6150c0000c0000c0000c0630c0000c0000c0000c0630c0000c0000c0000c0630000000000000000c0430c0430c0530c0000c0430000024655186250c61500000
010d0020277001a0001c0001d0001f0001f0001f0001f0001f000210002100023000230002100021000230002300007000070000700007700070000700007000077000700007000050001b0201d7311d0421f761
010d000000000000000000000000000000000000000000000c0110c0110c0230743505235074450724513455134450000000000000000000000000000000000007000074000c0130742505225074250723513435
010d00201f7421f7521f7421f03226755260152675526012247652405124742247322275522011227522271121765210512174221732227542201122752227112176421052227452203124744240112675126051
010d00001f7421f7521f7421f032267552601526755260122476524051247422473222755220112275222711217652105121742217322275422011227522271121764210521f7421f0321d7551d0111f7621f052
010d000026762260602674126045267512606126755260512475524051247422403224725240112475524051227552205122742220322305024751247552405121755210511f7451f0311d7251d0141f7641f052
010d00001f7521f0321f7221f01213000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002270022030247512405226761
010d00002605026740260302672226042267122604226712260412674126111267412604126041260412604129041290412904129211260412604126041260412404124741260412604126041260412404124741
010d00002405024042180322402024755247102475524711247002404524021247102474524012240452701127051270401b56027015270522703027722270122775227020330102776227022270122675426052
010d000026050267421a03226720267252671026055267102700126745260201a714260552601026052267112905129742290321d710267552674026032267122405018712260522670026032260122405524711
010d000024060247522403224720247553001224755240112476424055240312402424765240112405224712220622205522730220222475024014247552401222060160121f0451f7311d0651d0221f7511f762
010d00000e063094540925115455266450941509455154450e063094540925115455266450941509455154450e0630945409251154552664509415094551544507055074550c0630745505245074550725513455
010d00000c0630745407251134552464507415074551344507055074550c06307455246450741507255134220c0630745407251134552464507615072551344507055074550c0630745505275054550725513422
010d00200c0430c0000c0430c0000c6450c6230c0430c0000c0000c0000c0430c0000c6450c6230c0430c0000c0000c0000c0430000000000000000c0430c0430c0430c0000c043000000c6450c6250c61500000
010d00200c0630745407251134552464507415074551344507055074550c06307455246450741507255134220c0630745407251134552464507615072551344507055074550c0630745505275054550265502422
010d0000070630245407063022510245502401024550e445020550245507063024551f64502415022550e4220806303454032510f4552064503601032550f4450305503455080630345505275054550745407251
010d00000c0630a4540a25116455276450a4150a455164450a0550a4550f0630a455276450a4150a255164220c0630a4540a25116455276450a6150a255164450a0550a4550f0630a45508275084550a25516422
010d00000e0630945409251154552664509415094551544509055094550e06309455266450941509255154220e0630945409251154552664509615092551544509055094550e0630945507275074550465504422
010d00000c0630745407251134552464507415074551344507055074550c06307455246450741507255134220c0630745407251134552464507615072551344507055074550c0630745505275054550265502422
010d00001f7521f0321f7221f0120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000c0130742505225074250723513435
010d00001f7001f7001f7001f000267002600026700260002470024000247002470022700220002270022700217002100021700217002270022000227002270021700210001f7001f0001d7551d0111f7621f052
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200c0630c000000000c0730c0000c06324645186250c6120c0000c0630c0000c0000c0000c0330c0630c0630c00024600186002464518625186120c0430c0530c0000c0730000024645186250c61200000
010c00200c0630c000000000c0000c0730c0000c0631860024645186250c073246150c0730c0000c0730c0000c0000c00024600246002460018600246000c0002464518625096150461204611006110000000000
010c0000185501852018510185111b0501b010200502001018550185201b0501b010200502001025040250102501025012250122501220030200101854018521185201851118512185111b0351b0102003220012
010c0000185501852018510185111b0501b0101f0501f01018550185201b0501b0101f0511f042185421851518510185121851218512200002000018500185001850018500185001b0001b0111b0221f0421f012
010c00202074020730207202071020710207102071020710207402072020710207102071020710227402271022710227102274022720227102271020740207102071020710207402071020710207102070020700
010c00001f7401f7301f7251f7101f7101f7151f7101f7101f7401f7201f7151f7101d7411d7251f7401f7101f7101f7101f7451f7201f7451f7151d7411d7301d7201d7101d7251d7121d7121d7121f7021f700
010f00001a5501a5301a5201a51000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001305013050130501305013050130501305013050130501305013050130501305013050130501305013050130501305013050130501305013050130500000000000000000000000000000000000000000
010c0020130730707337015370152b6331f623370151307307073130732b63313073370152b633070732b6211307337000370002b600130731307337000130731307307073370003700013073070733701537015
010f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400180705307020071120705307120130102b6351f612070421301507140130141303307053071120705307120130112b6351f612070350714007020070100000000000000000000000000000000000000000
011400180a0530a020161120a0530a1200a0102e635226120a0420a0150a1400a0140503311053111120505305120110112963529612050350514011020050100500000000000000000000000000000000000000
__music__
00 52595644
00 12191144
01 17231844
01 17231b44
00 17251a44
00 17261c44
00 24231044
01 17231b44
00 17251a44
00 17261c44
00 24231d44
00 16272044
00 15281f44
00 24272044
00 16222144
02 132b2a44
00 78764344
01 2e2f3144
02 2e303244
00 64635d44
01 37364344
02 38364344
00 64676044
00 56626144
02 536b6a44
00 41424344
01 6e6f7144
02 6e707244
01 77764344
02 78764344

