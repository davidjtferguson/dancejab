pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- dancejab
-- footsies based fighting game

test=""

--avatar
function createav(x,y,name,flipped)
  --constants, play around with
 local hurtboxwidth=8

 local av={ 
  --how long each action lasts
  -- in frames at 60fps
  -- note animations will need to be updated
  -- if screwing around with these
  dashframes=7,
  jabframes=7,
  jablagframes=14,
  connectlagframes=19,

  hitpauseframes=7,
  hitrecoilframes=10,

  clankstunframes=12,
  clankrecoilframes=6,
  clankbreatherframes=16,
  
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

  --edit with local hurtboxwidth
  -- at the top of this func
  hurtbox={
   x=8-(hurtboxwidth/2),
   y=6,
   width=hurtboxwidth,
   height=10,
  },

  pushbox={
   x=2,
   y=3,
   width=12,
   height=10,
  },

  groundbox={
   x=5,
   y=6,
   width=6,
   height=10,
  },

  --jab hitbox sizes in pixels
  jabwidth=6,
  jabheight=8,
  
  --create animations for this av
  animcountdown=createanim({64,234,236,64,226,228},{3,4,16,3,4,16}),
  animidle=createanim({66,226,228,230,232,64,234,236,238,224},{2,5,5,5,5,2,5,5,5,5}),
  animwalkforward=createanim({128,130,132,134},5),
  animwalkback=createanim({136,138,140,142},5),
  animdashforward=createanim({05,66,37},{3,6,6},false),
  animdashback=createanim({39,98,7},{3,3,6,},false),
  animjab=createanim({72,74,76},{3,6,1},false),
  animringout=createanim({192,194},6,false),
  animjablag=createanim({78,236,234,64,228},{2,3,3,3,3},false),
  animconnectlag=createanim({102,74,46,78},{9,3,5,3},false),
  animhitstun=createanim({34,108,110},{3,3,10},false),
  animlostround=createanim({108,110},{6,1},false),
  animlostmatch=createanim({160,162,164,166},{6,3,10,10}),
  animwonmatchpause=createanim({64,234,236,64,226,228,64,234,236,234},{3,4,13,2,3,5,2,3,5,3},false),
  animvictory=createanim({66,168,170,172,174},{3,6,6,6,6}),
  animclankstun=createanim(76),
  animclankrecoil=createanim({78,64,234,236,66},{3,4,5,8,3},false),
  animuptaunt=createanim({66,168,170,172,174,66,168,170,172,174,66},{3,3,2,7,5,3,3,2,7,5,2},false),
  animdowntaunt=createanim({64,234,236,64,226,228,64,234,236,234},{3,4,13,2,3,5,2,3,5,3},false),
  animstoponother=createanim({234,64,236,200},{5,4,9,5}),
  animpreroundpause=createanim({64,234,236,64,226,228},{3,4,16,3,4,16}),
		animchangecolor=createanim({72,74},{3,5},false),

  hitpoints=maxhitpoints,
 
  --vars, don't edit
  x=x,
  xvel=0,
  prevxvel=0,
  y=y,
  yvel=0,
  flipped=flipped,
  state="none",
  statetimer=0,
  name=name,
  jabdown=false,
  dashdown=false,
  updown=false,
  downdown=false,
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
  animclank=createanim({121,120,104},{3,5,1},false),
 }
 box.anim=box.animthrow
 add(hitboxes,box)
 return box
end

function _init()
 --constants
 --wins for a set
 firstto=3

 hitknockback=1.5

 --hitpoints in a round
 maxhitpoints=3
 gravity=0.15

 modes={"normal","sumo","1 hit ko","slippy shoes"}
 mode=1

 --menu controls
 optionselected=0

 --round restart settings
 -- frames from when a player dies till the first sfx is played and the transition starts
 roundoverstartpause=60

 -- frames till the players actually respawn (black circle should be covering the screen at this moment)
 roundoverrespawn=15

 -- frames after respawn before movement is allowed to give black circle time to leave the screen.
 -- go sfx will be played when this is over
 roundoverendpause=12

 -- black circle's x velocity
 transitionspeed=12

 --init stage select
 stages={}
 ssid=1
 sstage=nil

 createstage("normal",0,0,24,96,88,96)
 createstage("smaller",128,128,32,96,80,96)
 createstage("smallist",128,0,40,96,72,96)
 --createstage("smallest",256,128,44,64,68,64) -- for double ring out testing
 createstage("walls",768,0,24,96,88,96)
 createstage("ghost",256,0,24,48,88,96)
 createstage("tredmill out",384,0,24,96,88,96)
 createstage("tredmill in",512,0,24,96,88,96)
 createstage("ice",640,0,24,96,88,96)
 createstage("podiums",0,128,48,96,72,96) --TODO: centre?... probs more work than it's worth.
 createstage("the pit",896,0,24,96,88,96)

 sstage=stages[ssid]

 --colors to toggle through
 -- primary,
 -- secondary,
 -- eye color,
 -- skin tone,
 -- secondary for the opponent's fist,
 -- background orbs,
 -- win text centre,
 -- win text outline,
 -- light color when getting a point,
 -- light highlight 1 and 2,
 altcolors={
  { --red (p1 default)
   p=8,
   s=2,
   eyes=1,
   st=4,
   sfist=2,
   bg=2,
   wtc=8,
   wto=10,
   point=8,
   lh1=15,
   lh2=14,
  },
  { --blue (p2 default)
   p=12,
   s=13,
   eyes=2,
   st=14,
   sfist=1,
   bg=1,
   wtc=12,
   wto=7,
   point=12,
   lh1=7,
   lh2=6,
  },
  { --pink
   p=14,
   s=2,
   eyes=1,
   st=4,
   sfist=2,
   bg=2,
   wtc=14,
   wto=7,
   point=14,
   lh1=7,
   lh2=15,
  },
  { --green
   p=11,
   s=3,
   s=3,
   eyes=2,
   st=14,
   sfist=3,
   bg=3,
   wtc=3,
   wto=7,
   point=3,
   lh1=7,
   lh2=11,
  },
  { --yellow
   p=10,
   s=9,
   eyes=2,
   st=4,
   sfist=9,
   bg=9,
   wtc=9,
   wto=7,
   point=10,
   lh1=7,
   lh2=15,
  },
  { --voilet
   p=13,
   s=1,
   eyes=0,
   st=14,
   sfist=1,
   bg=1,
   wtc=13,
   wto=7,
   point=1,
   lh1=7,
   lh2=6,
  },
  { --black and white
   p=6,
   s=5,
   eyes=1,
   st=4,
   sfist=5,
   bg=5,
   wtc=0,
   wto=7,
   point=5,
   lh1=7,
   lh2=6,
  },
  { --orange
   p=9,
   s=4,
   eyes=2,
   st=14,
   sfist=4,
   bg=4,
   wtc=9,
   wto=7,
   point=9,
   lh1=7,
   lh2=10,
  },
 }

 resetmatch()
 
 currentmusic=20
 musicon=true

 mmusic(currentmusic)
 currentupdate=updatestart
 currentdraw=drawstart

 menuitem(1, "exit to menu", exittomenu)
 menuitem(2, "toggle music", togglemusic)
end

function exittomenu()
 resetmatch()
 mmusic(20)
 currentupdate=updatemenu
 currentdraw=drawmenu

 p1.anim=p1.animidle
 p2.anim=p2.animidle
end

function togglemusic()
 musicon=not musicon
 mmusic(currentmusic)
end

--mutable music
function mmusic(no)
 currentmusic=no

 if musicon then
  music(currentmusic)
 else
  music(-1)
 end
end

function resetmatch()
 resetround()

 --vars
 p1.score=0
 p2.score=0

 effects={}

 initcountdown()
 currentupdate=updatecountdown
 currentdraw=drawcountdown
end

function resetround()
 local p1score=0
 local p2score=0
 
 local p1colsindex=1
 local p2colsindex=2
 local p1cols=altcolors[p1colsindex]
 local p2cols=altcolors[p2colsindex]

 if p1 then
  scorep1=p1.score
  scorep2=p2.score

  p1colsindex=p1.colsindex
  p2colsindex=p2.colsindex

  p1cols=p1.cols
  p2cols=p2.cols
 end
 
 avs={}
 hitboxes={}

 p1=createav(sstage.p1x,sstage.p1y,"player 1")
 p1.no=0
 p1.score=scorep1
 p1.colsindex=p1colsindex
 p1.cols=p1cols
 
 p2=createav(sstage.p2x,sstage.p2y,"player 2",true)
 p2.no=1
 p2.score=scorep2
 p2.colsindex=p2colsindex
 p2.cols=p2cols

 --remember opponent avatar
 p1.oav=p2
 p2.oav=p1

 roundinprogress=true
end

function _update60()
 currentupdate()
end

function initcountdown()
 mmusic(1)
 p1.anim=p1.animcountdown
 p2.anim=p2.animcountdown

 ct=0
 ctvel=0
 xcorner=72
 countdownno=3
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

function updatestart()
 if pxbtnp(❎) or pxbtnp(🅾️) then
  sfx(62)
  p1.anim=p1.animidle
  p2.anim=p2.animidle
  currentupdate=updatemenu
  currentdraw=drawmenu
 end
end

function updatemenu()
 updateanim(p1.anim)
 updateanim(p2.anim)

 for box in all(hitboxes) do
  updatehitbox(box)
 end

 if pxbtnp(⬇️) then
  sfx(5)
  optionselected+=1

  if optionselected>1 then
   optionselected=0
  end
 end
 
 if pxbtnp(⬆️) then
  sfx(5)
  optionselected-=1

  if optionselected<0 then
   optionselected=1
  end
 end

 --option 0 is stage select
 if optionselected==0 and (pxbtnp(➡️) or pxbtnp(⬅️)) then
  sfx(4)
  if pxbtnp(⬅️) then
   ssid-=1
   if ssid==0 then
    ssid=#stages
   end
  elseif pxbtnp(➡️) then
   ssid+=1
   if ssid>#stages then
    ssid=1
   end
  end

  loadstage()
 end

 --option 1 is mode
 if optionselected==1 and (pxbtnp(➡️) or pxbtnp(⬅️)) then
  sfx(4)

  if pxbtnp(➡️) then
   mode+=1

   if mode>#modes then
    mode=1
   end
  elseif pxbtnp(⬅️) then
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
 
 colstoggle(p1)
 colstoggle(p2)

 if pxbtnp(🅾️) then
  hitboxes={}
  initcountdown()
  currentupdate=updatecountdown
  currentdraw=drawcountdown
 end
end

function colstoggle(av)
 --loop through colors with x
 if btnp(❎,av.no) then
  sfx(61)

  av.anim=av.animchangecolor
  resetanim(av.anim)

  if av.fist then
   del(hitboxes,av.fist)
  end   

  av.fist=createhitbox(av.jabwidth,av.jabheight,av)

  av.colsindex+=1

  if av.colsindex>#altcolors then
   av.colsindex=1
  end
  av.cols=altcolors[av.colsindex]
 end

 if av.anim.finished then
  resetanim(av.anim)
  av.anim=av.animidle
 end
end

--either player btnp
function pxbtnp(b)
 return btnp(b) or btnp(b,1)
end

function loadstage()
 sstage=stages[ssid]
 p1.x=sstage.p1x
 p1.y=sstage.p1y
 p2.x=sstage.p2x
 p2.y=sstage.p2y
end

function updategame()
  updatepes()

  for av in all(avs) do
   updateav(av)
  end

  for box in all(hitboxes) do
   updatehitbox(box)
  end
 end

function detectinputs(av)
 --dash triggered
 if btn(🅾️,av.no) and not av.dashdown then
  av.dashdown=true
  sfx(8)
  av.state="dash"
  av.statetimer=av.dashframes

  --dash direction held or facing
  if btn(⬅️,av.no) then
   --dash to the left
   av.xvel=-av.xdashmaxvel
  elseif btn(➡️,av.no) and
         btnp(🅾️,av.no) then
   --dash to the right
   av.xvel=av.xdashmaxvel
  elseif av.flipped then
   --dash to the left
   av.xvel=-av.xdashmaxvel
  else
   --dash to the right
   av.xvel=av.xdashmaxvel
  end
  
  resetanim(av.anim)

  --kick up dust
  -- (done after as needs xvel set)
  initpedash(av,2,4)
 end

 if not btn(🅾️,av.no) then
  av.dashdown=false
 end
 
 --jab
 if btn(❎,av.no) and not av.jabdown then
  av.jabdown=true
  sfx(9+flr(rnd(2)))
  av.state="jab"
  av.anim=av.animjab
  av.statetimer=av.jabframes
  av.fist=createhitbox(av.jabwidth,av.jabheight,av)
 end

 if not btn(❎,av.no) then
  av.jabdown=false
 end
end

function updateav(av)
 if av.statetimer>0 then
  av.statetimer-=1
 end

 --wait... and I dead?
 -- trying to stamp out issues with both avs taking damage on the same frame
 -- as something else happening, so their death is interupted by
 -- another state
 -- pretty buggy, but prevents a softlock...?
 if av.hitpoints==0 and av.state!="dead" and av.state!="ringout" and av.state!="respawning" then
  av.anim=av.animlostround
  av.state="dead"
  av.statetimer=75

  if av.fist then
   del(hitboxes,av.fist)
  end
 end

 local icy = checkavflagarea(globalbox(av,av.groundbox),3) or modes[mode]=="slippy shoes"

 --on ground?
 if checkavflagarea(
    globalbox(av,av.groundbox),0) and av.state!="ringout" then
  av.yvel=0

  --tredmill tiles
  if roundinprogress and
     not collidingwithotherav(av) then
   if checkavflagarea(
      globalbox(av,av.groundbox),1) then
    av.x-=0.25
   end
   
   if checkavflagarea(
     globalbox(av,av.groundbox),2) then
    av.x+=0.25
   end
  end
 else
  --on first ringout detection
  if av.state!="ringout" and av.state!="respawning" then
   av.hitpoints=0

   if av.fist then
    del(hitboxes,av.fist)
   end

   if av.oav.fist then
    av.oav.fist.active=false
   end

   --prevent double death
   if av.state!="dead" then
    sfx(15)
    av.anim=av.animringout
    updatescore(av)
    av.statetimer=90
   end
   
   roundinprogress=false
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

 av.prevxvel=av.xvel

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

    if abs(av.xvel)<0.25 then
     av.xvel=0
    end
   end

   if btn(⬆️,av.no) and not av.updown then
    av.updown=true
    sfx(58)
    av.state="taunt"

    --reset in state
    av.statetimer=1

    av.anim=av.animuptaunt
   elseif btn(⬇️,av.no) and not av.downdown then
    av.downdown=true
    sfx(59)
    av.state="taunt"

    --reset in state
    av.statetimer=1

    av.anim=av.animdowntaunt
   else
    av.anim=av.animidle
   end

   if not btn(⬆️,av.no) then
    av.updown=false
   end

   if not btn(⬇️,av.no) then
    av.downdown=false
   end
  end

  if collidingwithotherav(av) then
   av.anim=av.animstoponother
  end

  capvelocity(av)
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
  
  capvelocity(av)
 elseif av.state=="jablag" then
   if not icy then
    av.xvel=0
   end
 elseif av.state=="connectlag" then
  av.xvel=0
 elseif av.state=="taunt" then
  av.xvel=0

  --stay here till anim finished
  av.statetimer=1
  if av.anim.finished then
   av.state="none"
  end
 elseif av.state=="hitpause" then
  av.xvel=0
  if av.statetimer==0 then
   av.state="hitrecoil"
   av.statetimer=av.hitrecoilframes
  end
 elseif av.state=="hitrecoil" then
  takeknockback(av)
 elseif av.state=="clankstun" then
  av.xvel=0
  av.anim=av.animclankstun
  if av.statetimer==0 then
   av.state="clankrecoil"
   av.statetimer=av.clankrecoilframes
   av.anim=av.animclankrecoil
  end
 elseif av.state=="clankrecoil" then
  takeknockback(av)

  if av.statetimer==0 then
   av.state="clankbreather"
   av.statetimer=av.clankbreatherframes
  end
 elseif av.state=="clankbreather" then
  av.xvel*=0.75
 elseif av.state=="wonround" then
  av.xvel=0

  --if we were playing the throw punch anim
  -- wait till it finishes
  if av.anim.looping or av.anim.finished then
   av.anim=av.animvictory
  end
 
  if av.statetimer==0 then
   triggerrespawn(av)
  end

 elseif av.state=="respawning" then
  
  if av.statetimer==0 then
   av.state="preroundpause"

   resetround()

   p1.state="preroundpause"
   p1.statetimer=roundoverendpause
   p2.state="preroundpause"
   p2.statetimer=roundoverendpause
  end
 elseif av.state=="preroundpause" then
  av.anim=av.animpreroundpause

  if av.statetimer==0 then
   sfx(3)
  end
 elseif av.state=="wonmatchpause" then
  if av.statetimer==0 then
   av.state="wonmatch"
   av.statetimer=90
   mmusic(17)
  end

  --prevent ringing out during pause
  av.xvel=0

  --only apply to dead, not ringout
  if av.statetimer>=85 and av.oav=="dead" then
   takeknockback(av.oav)
  end

  if av.anim.looping or av.anim.finished then
   av.anim=av.animwonmatchpause
  end

 elseif av.state=="wonmatch" then
  --if we were playing the throw punch anim
  -- wait till it finishes
  if av.anim.looping or av.anim.finished then
   av.anim=av.animvictory
   initpeflame(64,7,av.cols)
  end

  av.oav.anim=av.animlostmatch
  av.oav.xvel=0

  --navigation inputs
  if pxbtnp(🅾️) then
   resetmatch()
  end
  
  if pxbtnp(❎) then
   exittomenu()
  end

 elseif av.state=="dead" then
  if av.statetimer>=80 then
   takeknockback(av)
  end
  av.xvel*=0.9

  if abs(av.xvel)<0.25 then
   av.xvel=0
  end

  --handle double death respawn trigger
  if av.statetimer==0 and av.oav.hitpoints==0 and (av.oav.state=="dead" or av.oav.state=="ringout") then
   triggerrespawn(av)
  end
 elseif av.state=="ringout" then
  --make sure we overrite others,
  -- e.g. lost anim
  av.anim=av.animringout
  av.xvel*=0.9
  
  av.yvel+=gravity

  --handle double death respawn trigger
  if av.statetimer==0 and av.oav.hitpoints==0 and (av.oav.state=="dead" or av.oav.state=="ringout") then
   triggerrespawn(av)
  end
 end

 --reset state, or the round
 -- except for wonmatch, which has the menu up on screen.
 if av.statetimer==0 and
    (av.state!="wonmatch" and av.oav.state!="wonmatch") then
  av.state="none"
 end

 updateanim(av.anim)

 --stop on walls
 local nextxposbox=globalbox(av,av.groundbox)
 nextxposbox.x+=av.xvel
 nextxposbox.y-=2

 if checkavflagarea(nextxposbox,0) then
  av.xvel=0
 end

 --collide with eachother
 if collidingwithotherav(av) then
  --dashing into someone makes you bounce off
  -- so walking is strong against dashing
  if av.state=="dash" then
   sfx(11)
   av.xvel*=av.xcollisionmult

   local x,y=p1.x+p1.width,p1.y+5
   if av==p2 then
    x,y=p2.x,p2.y+5
   end

   initpehit(x,y,1,10,4,7,{7,av.cols.p,av.oav.cols.p})
  else
   av.xvel=0
  end
 end

 --if we've still started accelerating,
 -- feet particles
 if (av.prevxvel>=0 and av.xvel<0) or
    (av.prevxvel<=0 and av.xvel>0) then
  initpedash(av,0,1)
 end

 av.x+=av.xvel
 av.y+=av.yvel
end

function triggerrespawn(av)
   sfx(2)
   av.state="respawning"

   initpetransition()

   av.statetimer=roundoverrespawn
end

function collidingwithotherav(av)
 local nextxposbox=globalbox(av,av.pushbox)
 nextxposbox.x+=av.xvel

 return aabbcollision(
    nextxposbox,
    globalbox(av.oav,av.oav.pushbox))
end

function capvelocity(av)
  if av.xvel>av.xmaxvel then
   av.xvel=av.xmaxvel
  end
  
  if av.xvel<(-av.xmaxvel) then
   av.xvel=-av.xmaxvel
  end
end

function facingforward(av)
 if (not av.flipped and
    av.xvel>=0) or
    (av.flipped and
    av.xvel<=0) then 
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
    initpehit(box.x,box.y,3,20,5,30,{7,av.cols.p,av.oav.cols.p})

    av.state="hitpause"
    av.statetimer=av.hitpauseframes
    av.anim=av.animhitstun

    if av.hitpoints==0 then
     sfx(14)
     av.anim=av.animlostround
     updatescore(av)
     av.state="dead"
     av.statetimer=90
     roundinprogress=false
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
 
 --if we both died on the same frame, need to not award points
 -- yeah, it'd be nice if they both got the point, and then
 -- if you both reached first to there was some kind of stand off
 -- but that's a lot more expensive
 if av.oav.hitpoints==0 then
  av.score-=1
  av.oav.score-=1
 end

 av.oav.state="wonround"
 if av.oav.score==firstto then
  music(-1)
  av.oav.state="wonmatchpause"
 end

 av.oav.statetimer=roundoverstartpause
end

function updatehitbox(box)
 updateanim(box.anim)

 --remove once jab is over
 if box.anim.finished and box.av.state!="jab" then
  del(hitboxes,box)
  return
 end

 --track av pos
 if not box.av.flipped then
  box.x=box.av.x+box.av.width
 else
  box.x=box.av.x-box.width-1
 end

 for otherbox in all(hitboxes) do
  if aabbcollision(box,otherbox) and
     box.pno!=otherbox.pno and
     box.active and otherbox.active then
   --clank!
   sfx(60)

   p1.state="clankstun"
   p1.statetimer=p1.clankstunframes
   p2.state="clankstun"
   p2.statetimer=p2.clankstunframes

   box.active=false
   box.anim=box.animclank
   otherbox.active=false
   otherbox.anim=otherbox.animclank

   --sparks!
   initpehit(box.x,box.y,4,30,5,15,{7})
  end
 end 
end

function _draw()
 cls()
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

 outline(option0,(64-option0length*2),16,10,8)
 print(sstage.name,(64-#sstage.name*2),24,10,8)

 outline(option1,(64-option1length*2),34,10,8)
 print(modes[mode],(64-#modes[mode]*2),42,10,8)
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

 sspr(xcorner,16,8,9,
  ct/2,ct/2,
  (128-ct)+offset,128-ct)
end

stagetimer=0
stagetoggletime=15

function drawgame()
 if p1.state=="wonmatchpause" or p2.state=="wonmatchpause" then
  --cut to white chars on black background
  cls(0)

  for i=0,15 do
   pal(i,7)
  end

  drawav(p1)
  drawav(p2)

  resetpal()

  --renders each frame twice for one update
  -- effectively making a slowmo effect
  flip()
 else
  drawbackground()

  --draw tredmill arrows as flashing
  stagetimer+=1

  if stagetimer>=stagetoggletime then
   pal(12,p1.cols.p)
   pal(8,p2.cols.p)
  else
   pal(12,p1.cols.s)
   pal(8,p2.cols.s)
  end

  if stagetimer >=(stagetoggletime*2) then
   stagetimer=0
  end

  map(sstage.camerax/8,sstage.cameray/8,
   0,0,
   16,16)

  resetpal()

  drawwithavcolors(p1,drawav)
  drawwithavcolors(p2,drawav)
  
  --draw player1 hitboxes again
  -- on top of p2
  drawwithavcolors(p1,drawavhitboxes)

  --draw particle effects ontop of
  -- players but behind ui
  drawpes()

  drawui()

  --draw fight sprite for first
  -- -ct frames of fight
  -- set in updatecountdown
  if countdownno==0 and ct<30 then
   ct+=1

   local shake=0

   if ct<20 then
    shake=(30/ct)
   end

   sspr(96,0,32,16,
    32+(rnd(shake)-shake/2),48+(rnd(shake)-shake/2),
    64,32)
  end

  if p1.state=="wonmatch" or p2.state=="wonmatch" then
  
  local col1,col2=p1.cols.wto,p1.cols.wtc
  local winner=""

  if p1.state=="wonmatch" then
   winner=p1.name.." wins!"
  else
   winner=p2.name.." wins!"
   col1,col2=p2.cols.wto,p2.cols.wtc
  end

  outline(winner,(64-#winner*2),30,col1,col2)

  outline("🅾️ replay",46,56,col1,col2)
  outline("❎ menu",50,74,col1,col2)
  end
 
  --did we both die on the same frame?
  if p1.hitpoints==0 and p2.hitpoints==0 then
   local dko="double ko!"
   outline(dko,(64-#dko*2),34,10,8)
  end
 end

 --debug info
-- drawlocalbox(p1,p1.pushbox,5)
-- drawlocalbox(p1,p1.hurtbox,9)
 
-- drawlocalbox(p2,p2.pushbox,5)
-- drawlocalbox(p2,p2.hurtbox,9)

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

 if av.state=="hitpause" or av.state=="clankstun" then
  randx=rnd(shakerange)-(shakerange/2)
  randy=rnd(shakerange)-(shakerange/2)
 end

 spr(av.anim.sprite,av.x+randx,av.y+randy,2,2,av.flipped)

 drawavhitboxes(av,randx,randy)
end

function drawwithavcolors(av,drawing)
 pal(8,av.cols.p)
 pal(2,av.cols.s)
 pal(14,av.cols.st)
 pal(3,av.cols.eyes)

 pal(12,av.oav.cols.p)
 pal(1,av.oav.cols.sfist)

 drawing(av)

 resetpal()
end

function resetpal()
 pal()
 palt(0,false)
 palt(11,true)
end

function drawui()
 --p1 health
 rectfill(5,5,24,8,5)
 if p1.hitpoints>0 then
  rectfill(5,5,4+(20*(p1.hitpoints/maxhitpoints)),8,p1.cols.p)
 end
 spr(18,3,3,3,1,true)

 --p2 health
 rectfill(103,5,122,8,5)
 if p2.hitpoints>0 then
  rectfill(103+20-20*(p2.hitpoints/maxhitpoints),5,122,8,p2.cols.p)
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
  local lightspr=9

  --centre sprite
  if i==(flr(maxgames/2+1)) then
   lightspr=25
  end

  --change cols based on altcolor

  --highlight defaults
  pal(15,7)
  pal(3,6)

  if i<=p1.score then
   pal(13,p1.cols.point)
   pal(15,p1.cols.lh1)
   pal(3,p1.cols.lh2)
  end

  if i>(maxgames-p2.score) then
   pal(13,p2.cols.point)
   pal(15,p2.cols.lh1)
   pal(3,p2.cols.lh2)
  end

  spr(lightspr,i*8+(57-(maxgames/2)*8),3)

  resetpal()
 end
end

--adapted form
-- https://twitter.com/lexaloffle/status/1149043190218891264
move=0
movevel=0
moveadd=0.00015

function drawbackground()
 movevel+=moveadd
 move+=movevel
 
 if abs(movevel)>0.04 then
  moveadd*=-1
 end

	for z=16,1,-1 do
	 for x=-16,16 do
	  y=cos(x/16+z/32+move/2)*50-80-move*50   
	  sx,r,c=64+x*64/z,8/z,circfill
	  c(sx,64+y/z,r,p1.cols.bg)
	  c(sx,64+-y/z,r,p2.cols.bg)
	 end
	end
end

function drawavhitboxes(av,rx,ry)
 rx=rx or 0
 ry=ry or 0

 for box in all(hitboxes) do
  if box.av == av then

   --p2 fist is visually off by a pixel
   -- for some reason??
   local boxx = box.x
   if av == p2 then
    boxx-=1
   end
  spr(box.anim.sprite,boxx+rx,box.y+ry,1,1,av.flipped)
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
   resetanim(a)
  end

  a.t=time()

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

function resetanim(a)
 a.counter=0
 a.along=1
 a.finished=false
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
"00120312001f1f1f1d00120012001f1f0012081000120312001f1f1f1d0016001f1f13071100120312001f1f1f1d0016001f1f001206120012031f1f1f1f110016001f1f001206120012031f1f1f1f19001f1f001204100014771f1f1f1f1f1f180012031100127b1f1f1f1f1f1f160012021200117e1f1f1f1f12741f1c0012011300107f1f1f1f1d791c711d00120014007285771f1f1f197d19761b00187289751f1f1f137ac37218781b0017728c731f1f7c117ac8721772c2721c0016728d731f1b7f79cb721672c310721c0015728e731f18798677ce721672c311711f13728f731f7312748d72cfc110721572c4117116001b72842287731c7d8e72cd14721572c312711700110017728422718673197e8822708272ca16731572c311721800110016728422728573187484748822718272c815751672c311711a00110015738322738473107a887184218221718372c271c411761871c411711b001773842174847d897183228a71c174c3117b1272c3117519001673842174847c8a208422887ac3117d1072c31177180015738421758476817284228220832270877bc4117f70c811731e73842175847187718324812083217184207381721173c31174c376ca12721d738421758320718720708222728120832172842283711272c41072c91071cb12711e728421758221892182217381208320738b711272c41170ca1170c411c412721d728422748220832382218221738620738b711372c311c510c411c414c312711d7285217481208324822182217386207588721372c311c314c211c41371c311711d728521748120822272832181217387207585741372c311c31271c310c41272c311711d72852174852173832181217382208821791473c310c21272c310c31372c311711d72852173862074832181217382208921771573c310c21173c310c31273c3117116001572852173862074842081217482208821761673c310c31072c410c51072c41171170014738421728720738821788821711875c410c41070c610cc127118001373842172832083718a207210778521721479c41071cc70cb12711d73842170852089708375117f701478c61071c870c173c812721d738421872087728175167c1372cd73c678c513721e7384208820877919791471cd7f7615731f738e702084781f1b71cc7e137d190015738d7f1f1c72c9741275187a1500140014738b207b1f1f1173c6751f15741900140013738a207a1f1f147d1f1f170011001100137289751f1f1c791f1f1b001400127288751f1f1f1f1f1f14001400117286761f1f1f1f1f1f16001400107284761f1f1f1f1f1f1600110014007c1f1f1f1e2f271f12001100147a1f1f1f1d2f2e1f17781f1f1f73192f2f221f15741f1f1f1275172f2f281300130019001f11711f1e77152f2f2b1200130019001f731f1d7715278f872d110013001f19731f1d7715258f8f28110013001f19711f1372177714248f8f842611001f1f1f1274177515248f8f86251f1f1b701774187315258f8f88241f1f197216741f11258f8f8a231f1f1a7018721f12258f8f8b221f1f1f1f1a258f8f8c221f1f1f1f18268f8f8c221f1f1f1f18258f668f86221f1f1a7119d61a258f6e8e221f1f1a7115dc18248f806f6984211f10dfd21cdf17248f806f6984211cdfd819dfd313258f806f69842118dfdf15dfd512258f816f68842116dfdfd312d6c8d711258f816f67852114dfdfd610d5ccd610258f816f67852113dbcfc2decfc0d310258f826f66852112d8cfc8dbcfc2d3258f826f66852111d6cfced8cfc2d3258f8f68862111d5cfcfc0d6cfc4d3248f8f8f2110d5cfcfc1d5cfc5d3248f8f8f2110d5cfcfc1d5cfc5d4238f8f8f21d5cfcfc2d4cfc6d4238f80488b468221d5cfcfc2d4cfc7d3238e4f4c8222d5cfcc70c4d4cfc7d3238f4f4b8222d4cfcc72c3d4cfc7d3238f41134f42128222d4c160cfca70c4d3cfc8d3238f80401848178222d4c160cfcfc0d3cfc8d6218f801946188222d3c163cfcdd4c829c5d7208f801945198123d3c16bcfc5d4c52ec3d88f80194518408123d3c16f67c9d4c32f21c2da8e134b13438323d2c26f67c9d4c02f26d4c2d38e134b13438323d2c26f67c9d42f28d3c3d38e114d11438522d2c26f67c9d2268a29d0c5d38f81214f208522d2c26f67c9d1268d28c5d38f82214d218522d2c26f67ca258f8126c6d38f82214c208622d2c46f65c9258f8424c6d3218f80214b218622d2c46f65c9248f8525c5d3238e214a228523d2cb6ec8248f8724c5d380248c2149238325d2cfcfc3238f8825c4d382238b214726812510d2c3e3cfca238f8a24c4d38521892f2910d2c3e4cfc9238f8a24c4d38f802f2911d1c4e5c9eac2238f8b24c4d38b2f2d12d1c421efe8c2238f8c23c3d48b28802f2213d1c523efe5c2238f8c23c2d48c258d2615d0c626efe1c3238f8c23c1d483708f8f802116d0c626e628e1c3238f8c23d583728f8f2215d0c725e628c5238f8c23d584708f8f802215d0c7e024e628c5238f8c23d420108f8f862214d0c8e122e726c6238f8c23d4248f8f832214d0c9e021ec21c7238f8b24d2288f8f812313d0c9ef20c8238f8b24112b8f8f2313d1c9edd1c8248d208b2415298e607f726011d2caead2c7d1238b218b25172a8b73d011d06010d075d010d0700010d3cae8d3c6d22488228c251a288a7310611062751060107001d5cfc0e0d3c5d32486238d241c278a7213d010d111d011701270100010d5cfc0d3c5d2c02d8f231f27887111d07111701061106010701060107013d4cfc0d2c5d2c22b8f2412711c258870d010d071d01070d011d01171d010d07012d5cfc0d3c4d2c3298f8023127315731423877f7411d6cfc0d4c2d2c6258f8223127314751324867f741000d5cfc2d3c2d2c7248f812413711477132386776052607711d5cfc2d3c2d1c9218f82241b7713238677508250770010d460cfc3d2ce218f82241b7714228677508250771000d363cfcfc3228f80251b771423857460528252607411d264cfcfc2268c251d751200112361837450927262507411d267cfcf2787291e731400112262827450927262507411d16acfcd2f2819701e0010236471605292726252607111d16dcfc1d1c72f2718721e0023647150a278e250710010d16f60ced2c5d12f25137213701f1023647150a278e2507101d16f65c9d2c5d1c02f2214741f1423647150a278e2507101d0c26f6dd2ca2f15741f13002364716052b272d252607101c56f6ad3cc2c16741f1423647450b272d2507401c96f66d4cfc12419721f152380637450b272d2507401cd6f62d4c970c5d41f1f13238162746052c252607401cfc06ed6c772c3d51f1f1323847750c2507701cfc46ad7c770c4d41f1f1324847750c250771000c8d4cfc1d8c9d61f1f142484776052607711c5d7cfc0d710dfd01f1f152484607f726011"

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

function initpedash(av,rndradius,no)
 local e=createeffect(updatepestraight)

 local cols={6,7}

 --out of front foot or back foot?
 local footpos=0
 if av.xvel>0 then
  footpos=av.width
 end

 for i=0,no do
  local p=createparticle(
   av.x+footpos,av.y+av.height,
   (-sgn(av.xvel))+(rnd(1)-0.5),
   rnd(0.5)-0.35,
   rnd(rndradius)+1,cols[ceil(rnd(#cols))],
   rnd(12)+5)
  add(e.particles,p)
 end
end

function initpehit(x,y,rndradius,no,lifespan,rndlifespan,cols)
 local e=createeffect(updatepestraight)
 
 for i=0,no do
  local p=createparticle(
   x,y,
   rnd(2)-1,
   rnd(6)-3,
   rnd(rndradius),cols[ceil(rnd(#cols))],
   rnd(rndlifespan)+lifespan)
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

function initpeflame(x,y,cols)
 local e=createeffect(updatepeflame)
 
 local col1,col2=cols.s,cols.p

 local cols={6,7,col1,col2,col2}
 
 for i=0,5 do
  local p=createparticle(
   x,y,
   rnd(2)-1,
   rnd(2)-1,
   rnd(2),cols[ceil(rnd(#cols))],
   rnd(30)+45)
  add(e.particles,p)
 end
end

function updatepeflame(e)
 for p in all(e.particles) do
  p.x+=p.xvel
  p.y+=p.yvel

  --fall like confettii
  p.yvel+=0.1
  
  p.lifespan-=1
  if p.lifespan<=0 then
   del(e.particles,p)
  end
 end

 if #e.particles==0 then
  del(effects,e)
 end
end

--black circle wipe
function initpetransition()
 local e=createeffect(updatepestraight)
 
 local p=createparticle(
  -64,64,
  transitionspeed,
  0,
  96,0,
  90)
 add(e.particles,p)
end

function updatepetransition(e)
 for p in all(e.particles) do
  p.x+=p.xvel
  
  p.lifespan-=1

  if p.lifespan<=0 then
   del(e.particles,p)
  end
 end
 
 if #e.particles==0 then
  del(effects,e)
 end
end


__gfx__
00000000d6666666cc7ccbbbd66666666666666dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5665bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000002dddddd667cccbbb2dddd6d66d6dddd2bbbbbbbbbbbbbbbbbb28888882bbbbbbb57dd75bbbb88bbbbb88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5000
007007002d2666d676cccbbb27766c7667866772bbbbbbbbbbbbbbbbb2888887878bbbbbb6dd3f6bbb8dd8bbb8dd8bbbbbbbbb000bbbbbbbbbbbbbbbbbbb5670
000770002d2dd6d6cccccbbb2cccccc778888882bbbbb288888882bbb88888888872bbbbb6ddf36bb8dddd8b8dddd8bb0000000670bbbbb000bb000bbbbb0770
000770002d2dd6d6cccccbbb2cccccc228888882bbbb28888878782b288888888888bbbbb6dddd6b8dddddd8dddddd8b06777707700000006700670000000770
007007002d2222d6cccccbbb22222c2662822222bbbb88888888878b8888288888282bbbb6dddd6b8ddddddddddddd8b06767700006777770700775777770670
000000002dddddd6cccccbbb25ddd2d66d2ddd52bbb28888888888828888233323388bbbb57dd75b8ddddddddddddd8b06755006707777770700770777770670
000000002222222dccccbbbb2222222dd2222222bbb88882888888288888823223288bbbbb5665bb8ddddddddddddd8b07777007707700006700770067000670
5ddddddd76777677bbbbbbbbbbbbbbbbbbbbbbbbbbb888822888822888888822e2888bbbb499aa4bb8ddddddddddd8bb077670077077006707777705770b5770
2555555d26776767b51111000000000000001bbbbc7c8881332233282c7c8888e2888bbb4adddda4bb8ddddddddd8bbb077000077077007707777700770bb00b
255ddd5d262666d6b1bbbbbbbbbbbbbbbbbb65bbccc7c2883eee3228bcc7c2882288bbbb9ddd3fd9bbb8ddddddd8bbbb0770bb076077777707007700770bbbbb
25255d5d2d2dd6d6b1bbbbbbbbbbbbbbbbbb761bcccc7c888eeee28bbccc7c2888bbbbbb9dddf3d9bbbb8ddddd8bbbbb0670bb055067777707007700770b5000
25255d5d2d2dd6d6b567bbbbbbbbbbbbbbbbbb1bcccccc2888ee288bbccccc8882bbbbbb9dd3ddd9bbbbb8ddd8bbbbbb0770bbbbbb05500007007700770b0670
2522255d2d2222d6bb56bbbbbbbbbbbbbbbbbb1bccc1cc22828888bbbcccc188882bbbbb9dddddd9bbbbbb8d8bbbbbbb0000bbbbbbbbbbb005bb5000670b0660
2555555d2dddddd6bbb5100000000000011111db6c11cbb88888bbbbb6cc1c88882bbbbb4adddda4bbbbbbb8bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000b5005
222222252222222dbbbbbbbbbbbbbbbbbbbbbbbbb66bbbebbbebbbbbbb66bbebbbbebbbbb4999a4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bddddddd77767777bbbbb888888888bbb6666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbb000bbbbbb000bbbbbbbbbbd6666666bbbbbbbbbbbbbbbb
2555555d67667666bbbb88888888888b2dddddd6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb067770bbb07770bbbb0670bb222d6d665dddddd6bbbbbbbbbbbbbbbb
255ddd5d266ddd6dbbb88888888888882d2666d6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0777770b0677770bb06770bb2222dddd5d2666d6bbbbbbbbbbbbbbbb
25255d5d25255d5dbbb88888888888882d2dd6d6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb005670b0770770bbb0770bbb222225b5d2dd6d6bbbbbb88888888bb
25255d5d25255d5dbbb88888888888882d2dd6d6bbbbb888888888bbbbbbbbbbbbbbbbbbb066770bb007770bbb0770bbb22666db5d2dd6d6bbbbb2888888782b
2522255d2522255dbbb88888888888882d2222d6bbbb28888878782bbbbbbbbbbbbbbbbbb005670bb06750bbbb0770bbb22dd6db5d2222d6bbbb88888888878b
2555555d2555555dbbb88883388883382dddddd6bbb2888888888782bbbbbbbbbbbbbbbb0677770b0677770bbb0770bbb52dd6db5dddddd6bbbb888888888882
2222222522222225bbb88885338833582222222dbbb8888888888888b288888878782bbb0777770b0777770bbb0670bbb52225db2222222dbbb2888888222888
d666666b5ddddddbbbb8888853ee3588bbbbbbbbbbb8828288888828288c7c88888782bb000000bb0000000bbb0000bbb5555d5bbbbbbbbbbbb2888882233888
2dddddd62555555dcccccc888eeee88bcccccbbbbc7c22222888822888ccc7c88888888bbbbbbbbbbbbbbbbbbbbbbbbbb25555dbbbbbbbbbbbb2888888223eeb
2d2666d6255ddd5dccc67c88eeee888bccc67cbbccc7c2233322332888cccc7c8888288bbbbbbbbbbbbbbbbbbbbbbbbbb52ddd5bbbbbbbbbbbbb28828222226c
2d2dd6d625255d5dcccc6c88888888bbcc76ccbbcccc7c223eee3e8888cccccc8882288bbbbbbbbbbbbbbbbbbbbbbbbbb2255d5bbbbbbbbbbbbbb888888886cc
2d2dd6d625255d5dcccc1c8888bbbbbbccccccbbcccccc822eeee88888cccc1c2233388bbbbbbbbbbbbbbbbbbbbbbbbbb2255d5bbbbbbbbbbbbb2888888886cc
2d2222d62522255dcccc1c8888bbbbbb1cccccbbcccc1c8882ee888b886cc1ccee22882bbbbbbbbbbbbbbbbbbbbbbbbbb22225dbbbbbbbbbbbb88888888816dc
2dddddd62555555dcccc1b8888bbbbbb1ccccdbb6ccbbb28888b82bb28866c22ee8882bbbbbbbbbbbbbbbbbbbbbbbbbbb22255dbbbbbbbbbbb28888888bbbb6d
2222222d22222225bbbbbbebbbebbbbbbcccdbbbb6bbebbbebbbbbbbb288888888822bbbbbbbbbbbbbbbbbbbbbbbbbbbb222222bbbbbbbbbbebbbbbbbebbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888878bbbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2888888888888bbbbb28888878782bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8828288888828bbbbb88888888878bbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbb2888888782bbbbb8888888888bb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8882228888228bbbb2888888888882bbbbbb28888888bbbbbbb8888888782bbbbb88888888878bbbb288888878782b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbc7c2232223228bbbb8828288888828bbbbb2888787772bbbbb888888888788bbbb888888888882bbb888888888878b
bb28888888888bbbbbb28888888888bbbccc7c832ee3228bbbb8882228888228bbbb288888888888bbb2888888822882bbb2888888222888bb28888888888882
b2888888888888bbbc7c88888888888bbcccc7ceeeee888bbbb8882333223328bbbb888888888888bbb2888882232888bbb2888882233888bb88282888888828
288c7c888888888bccc7c88888888888bcccccc8eee888bbbbc7c82232ee3228bbccccccccccccccbbb288888822328dbbb2888888223eebbbccccccccccccc8
28ccc7c88888288bcccc7c8888888288bcccc1c828888bbbbccc7c88eeeee88bbbcccc666666677cbbbb28828222226cbbbb28828222226cbbcc76777776cccc
28cccc7c8882288bcccccc8288882288b6cc1cc2888bbbbbbcccc7c88eee882bbccccccccccccc6cbbbbb888888886ccbbbbb888888886ccbbcccccccccccccc
28cccccc8233388bcccc1c8332233388bb66cb88888bbbbbbcccccc2828b82bbbcccccccccccccccbbbb2888888886ccbbbb2888888886ccbbcccccccccccccc
286ccc1c8e22888b6cc1cc82eee22888bbbbbb88888bbbbbbcccc1c8888bbbbbccccccccccccccccbbb88888888816dcbbb88888888816dcbb6ccccccccccccc
288661cc8e8888bbb66c8882eee8888bbbbbbb88888bbbbbb6cc1cc8888bbbbbccccccccccccccccbb28888888bbbb6dbb28888888bbbb6dbbb6cccccccccccb
b288888888828bbbbbb88888888828bbbbbbbbebbbebbbbbbb66bbebbbebbbbbbebbbbbbbbebbbbbbebbbbbbbebbbbbbbebbbbbbbebbbbbbbbbbbebbbbbbebbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbb28888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb2888887878bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccc67cbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbbbbbbbbbbbbbbbb
bbbbb288888882bbb88888888872bbbbbbbb888888888bbbbbbbbbbbbbbbbbbbcc76ccbbbbbbbbbbbbbb888888888bbbbb88888888878bbbbbbb88888888bbbb
bbbb28888878782b288888888888bbbbbbb28888878782bbbbbbbbbbbbbbbbbbccccccbbbbbbbbbbbbb28888888782bbb2888888888882bbbbb28888877882bb
bbbb88888888878b8888288888282bbbbbb88888888878bbbbbbbbbbbbbbbbbb1cccccbbbbbbbbbbbbb88888888778bbb8828288888828bbbbb88888888878bb
bbb288888888888b8888233323388bbbbbb888888888882bbbbbbbb88888888b1ccccdbbbbbbbbbbbb288c7c8878882bb8882228888228bbbb2888888888882b
bbb888828888882b8888823223288bbbbb2828288888828bbbbbbb8888888788bcccdbbbbbbbbbbbbb88ccc7c888828bb8888232222328bbbb8828888888888b
bbb888822888822b88888822e2888bbbbbc7c2228888228bbbbbb88888888878bbbbbbbbbbbbbbbbbb88cccc7c88288bbc7c8883ee3222bbbb8882288888828b
bbbccc883332332b288c7c88e888bbbbbccc7c333223328bbbbb288888882287ccccccdb7777776bbb28cccccc22328bccc7c88eeee88bbbbc7c88228888228b
bbccc7c2e3ee322bb2ccc7c8e288bbbbbcccc7c3eee3e82bbbbb288888222287ccc7777c77777777bb28cccc1ce3e88bcccc7ceeee882bbbccc7c1833223388b
bbcccc7c8eeee28bbbcccc7c882bbbbbbcccccc2eeee88bbbbbb288888833377cc7677cc77777777bb286cc1ccee88bbcccccc888828bbbbcccc7c8222e2882b
bbcccccc88ee288bbbcccccc22bbbbbbbcccc1c82ee888bbbbbb828828222277cccccccc77777777bbb2866c12e882bbcccc1c8888bbbbbbcccccc882ee888bb
bbccc1cc828888bbbbcccc1c22bbbbbbb6cc1cc888b82bbbbb888888888822771cccccccd7777777bbbb222288b28bbb6cc1cc8888bbbbbbcccc1c2288b28bbb
bb6c1ccb8888bbbbbb6cc1cc822bbbbbbb66c88888bbbbbbb888888888bbbbbb1cccccdbd777776bbbbbb88888bbbbbbb66cbb8888bbbbbb6cc1cc8888bbbbbb
bbb66bbbbbebbbbbbbb66bebbbbebbbbbbbbebbbbbebbbbbebbbbbbbbbebbbbbbccccdbbb77776bbbbbbebbbbbebbbbbbbbbbbebbbebbbbbb66cbebbbbebbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbb
bbbb28888878782bbbbbb288888882bbbbbbb288888882bbbbbb28888878782bbbb28888878782bbbbbb288888882bbbbbbb288888882bbbbbb28888878782bb
bbbb88888888878bbbbb28888878782bbbbb28888878782bbbbb88888888878bbbb88888888878bbbbb28888878782bbbbb28888878782bbbbb88888888878bb
bbb2888888888882bbbb88888888878bbbbb88888888878bbbb2888888888882bb2882888888882bbbb88888888878bbbbb88888888878bbbb2882888888882b
bbb8888288888828bbb2888888888882bbb2888888888882bbb8888288888828bb8822288888828bbb2882888888882bbb2882888888882bbb8822288888828b
bbb8888228888228bbb8888288888828bbb8888288888828bbb8888228888228bb8822228888228bbb8822288888828bbb8822288888828bbb8822228888228b
bc7c888233323328bc7c888228888228bbb8888228888228bbb8888233323328bbc7c2332233228bbbc7c2228888228bbb8822228888228bbb8822332233228b
ccc7c288e3ee3228ccc7c88233323328bc7c888233323328bc7c8888e3ee3228bccc7c322e32228bbccc7c332233228bbbc7c2332233228bbbc7c2322e32228b
cccc7c888eeee28bcccc7c8823ee3228ccc7c88823ee3228ccc7c2888eeee28bbcccc7ceeeee88bbbcccc7c22e32228bbccc7c322e32228bbccc7c8eeeee88bb
cccccc2888ee288bcccccc888eeee28bcccc7c888eeee28bcccc7c2888ee288bbcccccc8eee882bbbcccccceeeee88bbbcccc7ceeeee88bbbcccc7c8eee882bb
cccc1c22828888bbcccc1c2888ee288bcccccc2888ee288bcccccc22828888bbbcccc1c828b88bbbbcccc1c8eee882bbbcccccc8eee882bbbcccccc828b88bbb
6cc1ccb88882bbbb6cc1cc22828888bbcccc1c22828888bbcccc1cb88882bbbbb6cc1cc888bbbbbbb6cc1cc828b88bbbbcccc1c828b88bbbbcccc1c888bbbbbb
b66cbbb88888bbbbb66cbbb88888bbbb6cc1ccb88888bbbb6cc1ccb88888bbbbbb66cb8888bbbbbbbb66cb8888bbbbbbb6cc1cc888bbbbbbb6cc1cc888bbbbbb
bbbbbbbebbbebbbbbbbbbbbebbbbebbbb66bbbbebbbbebbbb66bbbebbbebbbbbbbbbbbebbebbbbbbbbbbbbebbbebbbbbbb66cbebbbebbbbbbb66cbbbebbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbbbb888888888bbbbbbbbbbbbbbbbbbb
bbbb28888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbb28888878782bbbbbb888888888bbb
bbb2888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888878bbbbb88888888878bbbbb28888878782bb
bbb88888888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2888888888882bbb2888888888882bbbb88888888878bb
bcc7c288888888bbbbbbb2888888bbbbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbbb888888888bbbb8828288888828bbb8828288888828bbb2888888888882b
cccc7c288888282bbbcccc88877882bbbbbbb88888888bbbbbbb28888877882bbbbb28888878782bbb8882333833328bbb8882238883228bbb8828288888828b
cccc7c232222388bccc67cc8888788bbbbbb28888877882bbbbb88888888878bbbbb88888888878bbb8888222222228bbb8882323232328bbb8882238883228b
cccccc823223288bbccc7cc88888882bbbbb88888888878bbbb2888888888882bbb2888888888882bb8888822ee2228bbbc7c2222ee2228bbb8882323232328b
6cc1cc88ee22888bbccccc7c8888888bbbb2888888888882bbb8828888888888bbc7c28288888828bb28888eeeee88bbbccc7c2eeeee88bbbbc7c8222ee2228b
b61cc288eee2888bbbcccc7c8888828bbbb8828888888888bbc7c82288888828bccc7c2228888228bbc7c828eee888bbbcccc7c8eee888bbbccc7c8eeeee88bb
bbb288888ee888bbbbcccccc8888228bbbb8882288888828bccc7c8228888228bcccc7c232222328bccc7c8828882bbbbcccccc828b82bbbbcccc7c8eee888bb
bbbb288288bb8bbbbbcccccc2222288bbcccc7c228888228bcccc7c833223388bcccccc223ee3228bcccc7c8888bbbbbbcccc1c888bbbbbbbcccccc828b82bbb
bbbbb88888bbbbbbbbcccccc22e2882bbccccc7833223388bcccccc8222e2882bcccc1c8eeeee88bbcccccc8888bbbbbb6cc1cc888bbbbbbbcccc1c888bbbbbb
bbbbb88888bbbbbbbbcccccc2ee888bb6ccccccc222e2882bcccc1c882ee888bb6cc1cc88eee888bbcccc1c8888bbbbbbb66bebbbbebbbbbb6cc1cc888bbbbbb
bbbbb88888bbbbbbbbcccccc88b28bbb6ccccc1c82ee888bb6cc1cc2288b28bbbb66cb82828b82bbb6cc1cc8888bbbbbbbbbbbbbbbbbbbbbbb66bbbbbebbbbbb
bbbbbebbbebbbbbbbbcccccc88bbbbbbb6ccc1cc288b28bbbb66cb28888bbbbbbbbbbb28888bbbbbbb66cb8bbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbb288888882bb
bbbb88888888bbbbbbbb88888888bbbbbbbb288888888bbbbbbb288888888bbbbbbbb888888888bbbbb88888888bbbbbbbbb28888878782bbbbb28888878782b
bbb28888877882bbbbb28888877882bbbbb28888887782bbbbb28888887782bbbbbb28888878782bbb28888877882bbbbbbb88888888878bbbbb88888888878b
bbb88888888878bbbbb88888888878bbbbb88888888878bbbbb88888888878bbbbbb88888888878bbb88888888878bbbbbb2888888888882bbb2888888888882
bb2888888888882bbc7c88888888882bbb2888888888882bbb2888888888882bbbb2888888888882b2888888888882bbbbb8828288888828bbb8828288888828
bc7c28888888888bccc7c2888888888bbb8888888888888bbb8888888888888bbbb8828288888828b8828888888888bbbbb8882228888228bbb8882228888228
ccc7c2288888828bcccc7c288888828bbb88c7c28888288bbb8888c7c888288bbbb8c7c228888228b8882288888828bbbbc7c88333223328bbbc7c2333223328
cccc7c228888228bcccccc228888228bbb2ccc7c2222328bbb888ccc7c22338bbbbccc7c33223328bc7c8228888228bbbccc7c8232ee3228bbccc7c232ee3228
cccccc833223388bcccc1c822222288bbb2cccc7cee3e88bbb888cccc7c2388bbbbcccc7ceee3222ccc7c333223388bbbcccc7c8eeeee88bbbcccc7ceeeee88b
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
bccc7c2228888228bc7c888888888882bbb8828288888828bb8882333223328bbb8882228888228bb2888888888882bbbb888c7c8888828bbbccc7c233223328
bcccc7c333223328ccc7c82888888828bc7c882228888228bb2888232ee3228bbb8882333223328bb288c7c8888828bbbb88ccc7c888228bbbcccc7c32ee3228
bcccccc232ee3228cccc7c8228888228ccc7c82333223328bbc7c88eeeee88bbbb2c7c232ee3228bb28ccc7c888228bbbb88cccc7c23328bbbcccccc8eeee88b
bcccc1c8eeeee88bcccccc8333223328cccc7c8232ee3228bccc7c88eee882bbbbccc7c2eeee88bbb28cccc7c23328bbbb88cccccc23228bbbcccc1c88ee882b
b6cc1cc8eeee882bcccc1c8232223228cccccc88eeeee88bbcccc7c828882bbbbbcccc7ceee882bbb28cccccce3228bbbb28cccc1cee88bbbb6cc1cc888b82bb
bb66cb88228b82bb6cc1cc88eeeee88bcccc1c288eee882bbcccccc8888bbbbbbbcccccc22882bbbb28cccc1cee88bbbbbb86cc1cce882bbbbb66c88888bbbbb
bbbbbb88888bbbbbb66cb8888eee882b6cc1cc82828b82bbbcccc1c8888bbbbbbbcccc1c888bbbbbbb86cc1cce882bbbbbbb266c22282bbbbbbbbb88888bbbbb
bbbbbb88888bbbbbbbbbbb22828b82bbb66cbb88888bbbbbb6cc1cc8888bbbbbbb6cc1cc888bbbbbbbbb66c88882bbbbbbbbbb88228bbbbbbbbbbb88888bbbbb
bbbbbbebbbebbbbbbbbbbbebbbbebbbbbbbbbbebbbbebbbbbb66cbebbbebbbbbbbb66cebbbebbbbbbbbbbebbbbebbbbbbbbbbebbbbebbbbbbbbbbbebbbebbbbb
__label__
01110000111011111111111111111111111111111111111111111111111111111111111111011101110111111111111111111111111111111110111000000000
10111000011101111111111111111111111111111111111111111111111111111111111111101111111011111111111111111111111111111111111100000000
11011100001110111111111111111111111111111111111111111111111111111111111111110111111101111111111111111111111111111111101110000000
11101110000111111111111111111111111111111111111111111111111111111111111111111011111110111111111111111111111111111111110111000000
01110111000011111111111111111111111111111111111111111111111111111111111111111111111111011111111111111111111111111111111011100000
10111117777777711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101110000
11011177777777777711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110111000
11101177777777777777711111111111111111111111111111111111111111111111111111111111111111117777711111111111111111111111111111011100
11110177777777777777771111111111111111111111111111111111111111111111111111111111111177777777771111111111111771111111111111101110
11111077788888877777777111111111111111111111111111111111111111111111111111111111177777777777777111111111177777771111111111110111
1111117778888888888777777111111111111111111111111111111111111111111111111111177777777777cccc777111111111777777777111111111111011
111111777888888888888877771111111111111111111111111111111177777777777771177777777777ccccccccc77711111111777ccc777111111111111101
111111777888888888888887777111111111111111111111111111177777777777777777777777777cccccccccccc7771111111777cccc177711111111111110
111111777888888888888888777711111111111111111111111117777777777888888877777777ccccccccccccccc7771111111777cccc117711111111111111
11111177788888888888888887777111111111111111177771117777788888888888888777cccccccccccccccccc1777111111777ccccc117711111110111111
11111177788888222888888887777111111111111177777777777777888888888888888777cccccccccccccc11111777111111777cccc1117711111111011011
11111177788888222778888888777711111111117777777777777778888888882227888777ccccccccccc11111117777111111777cccc1177711111111101101
11111177788888222777888888777711111111177777888887777788888888822277888777ccccccccc1111117777771111111777cccc1177111111111110110
11111177778888222777788888777717777777777788888888877888882288822778888777ccc77ccccc11777777711111111177ccccc1177111111111111011
1111117777888882277777888887777777777777788888888887788882228888888888877cc77777cccc11777777777777111777cccc11777777111111111101
11111177778888822777778888877777777777778888888888828888822288888888877777777777cccc11777777777777771777cccc11777777771111111110
11111177778888822777777888887777777887778888822288828888222788888888777777777777ccccc1177777777777777777ccccccccc117777111111111
111111777788888227777778888877888888887788882222288288882277888882777788777117777cccc1177777cccc7777777ccccccccccc11177711111111
111111777788888227777778888277888888882788822277788288882277788888222888877111777ccccc1777cccccccccc177cccccccccccc1117711111111
111111177788888227777778882288888888882288822777788288882777788888888888877111777ccccc117ccccccccccc117ccccc11ccccc1117771111111
1111111777888882227777788828888222288822888227777888888827777888888888888771111777cccc11cccccc1ccccc11ccccc11111cccc111771111111
1111111777888888227777788288882222288822888227777888888827777778888888887771111777cccc11cccc11111ccc11ccccc111177cccc11771111111
1111111777888888227777788288822277788882288227777888888882777777888888777771111777cccc11cccc11177cccc1ccccc111777cccc11771111111
11111117778888882277777888888227777888822882277778882888888888227777777777111117777cccc1ccc111777cccc1cccc1111777cccc11771111111
11111117778888882277778888888277777888822882277778882888888888822777777771111117777cccc1ccc117777cccc1cccc1117777cccc11771111111
01111117778888882277778888888277777888882882277777888288888888822777777711111117777cccc1cccc1777ccccc1cccccc1777ccccc11771111111
1011111777788888227778888888827777888888888227777777778888888882277111111111777777ccccc1ccccc17ccccccc1ccccccccccccc111771111111
1101111777788888227778888288887788888888888277717777777788888822777111117777777777ccccc177ccccccccccccc7cccccccccccc111771111111
11111117777888882278888882888888888878888777777117777777777777777711111777777777ccccccc177ccccccccc7cc7777ccccccccc1117771111111
1111111777788888228888888828888888877788777777111111177777777777771111777cccccccccccccc7777ccccccc777777777cccccc111177711111111
111111177778888828888888882888888887777777777111111111177777777771111177cccccccccccccc777777777777777777777771111117777111111111
111111177778888888888888887288888777777777111111111111111111111111111177ccccccccccccc7777777777777771111777777777777771111111111
0111111777788888888888888777777777777777711111111111111111111111111111777cccccccccc777771117777771111111117777777777711111101111
10111117777888888888888277777777777711111111111111111111111111111111117777ccccccc77777711111111111111111111117777711111111110111
11011117777888888888882777777777771111111111111111111111111111111111111777777777777771111111111111111111111111111111111111111011
01101111777888888888877777711111111111111111111111111111111111111111111177777777771111111111111111111111111111111111111111111101
11110111777888888888777777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111011777888888877777771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
01111101777888887777777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101
10111110777777777777711111111111111111111111111111111111111111111111111111111111111122222222222222222222222211111111111111111110
11011111777777777771111111111111111111111111111111111111111111111111111111111111122222222222222222222222222222221111111111111111
11111111777777777111111111111111111111111111111111111111111111111777711111111112222222222222222222222222222222222211111111111111
11111111777771111111111111111111111111111111111111111111111111117777771111111122222222222222222222222222222222222222222111101111
01111111111011111111111111111177111111111111111111111111111111177777777111111222222222222222222222222222222222222222222221110111
10111111111101111111111111111777711111111111111111111111111111177777777111111222222228888888888888888888888882222222222222211011
11011111111111111111111111111777711111111111111111111111111111177777777111111222222888888888888888888888888888888882222222221101
11101111111111111111111111111177111111111111111111117771111111177777777111112222288888888888888888888888888888888888882222222110
11111111111111111111111111111111111111111111111111177777111111117777771111112222288888888888888888888888888888888888888822222211
11111111111111111111111111111111111111111171111111177777111111111777711111122222288888888888888888888888888888888888888888222221
11111111111111111111111111111111111111111777111111177777111111111111111111222222888888888888888888888888888888888888888888822221
11111111111111111111111111111111111111111171111111117771111111111111111111222222888888888888888888888888888888888888888888882221
11111111111111111111111111111111111111111111111111111111111111111111111111222222888888888888888888888888888888888888888888888222
11111111111111111111111111111111111111111111111111111111111111111111111112222222888888888888888888888888888888888888888888888222
11111111111111111111111111111111111111111111111111111111111111111111111112222228888888888888888666666688888888888888888888888222
1111111111111111111111111111111111111111111771111111111ddddddd111111111112222228888888888888888666666666666666888888888888888222
111111111111111111111111111111111111111111177111111ddddddddddddd1111111112222288888888888888888666666666666666666666666668888822
11111111111111111ddddddddddddddddddd1111111111111dddddddddddddddd111111112222288888888888888888666666666666666666666666668888822
1111111111111ddddddddddddddddddddddddd1111111111dddddddddddddddddddd111122222288888888888888888666666666666666666666666668888822
111111111dddddddddddddddddddddddddddddddd111111dddddddddddddddddddddd11122222288888888888888888866666666666666666666666668888822
1111111dddddddddddddddddddddddddddddddddddd111dddddddcccccccccdddddddd1122222288888888888888888866666666666666666666666688888822
11111ddddddddddddddddddddddddddddddddddddddd1ddddddcccccccccccccddddddd122222288888888888888888866666666666666666666666688888822
1111ddddddddddddcccccccccccccccccccdddddddddddddddcccccccccccccccccdddd122222288888888888888888886666666666666666666666688888822
111dddddddddcccccccccccccccccccccccccddddddddddddcccccccccccccccccccdddd22222288888888888888888886666666666666666666666688888822
11dddddddcccccccccccccccccccccccccccccccdddddddddcccccccccccccccccccdddd22222288888888888888888888888888888888666666666888888822
11ddddddcccccccccccccccccccccccccccccccccdddddddcccccccccccccccccccccdddd2222288888888888888888888888888888888888888888888888822
1ddddddccccccccccccccccccccccccccccccccccddddddccccccccccccccccccccccdddd2222288888888888888888888888888888888888888888888888822
1ddddddccccccccccccccccccccccccccccccccccddddddccccccccccccccccccccccddddd222288888888888888888888888888888888888888888888888822
ddddddcccccccccccccccccccccccccccccccccccdddddcccccccccccccccccccccccddddd222288888888888888888444444444888888888888444444488822
ddddddcccccccccccccccccccccccccccccccccccdddddccccccccccccccccccccccccdddd222288888888888888844444444444444444444444444444888222
ddddddccccccccccccccccccccccccccccc7cccccdddddccccccccccccccccccccccccdddd222288888888888888884444444444444444444444444444888222
dddddccccccccccccccccccccccccccccc777ccccdddddccccccccccccccccccccccccdddd222288888888888888884411114444444444444444444111888222
dddddcc6ccccccccccccccccccccccccccc7cccccddddcccccccccccccccccccccccccdddd222288888888888888888411111111144444444411111111888222
dddddcc6cccccccccccccccccccccccccccccccccddddcccccccccccccccccccccccccddddddd228888888888888888811111111114444444111111111888222
ddddcc6666ccccccccccccccccccccccccccccccdddddccccccccc2222222222ccccccdddddddd28888888888888888811111111114444441111111111882222
ddddcc666666666666ccccccccccccccccccccccdddddcccccc222222222222222ccccddddddddd8888888888888888811111111114444441111111114882222
ddddcc666666666666666666666666ccccccccccdddddcccc222222222222222222cccddddddddddd88888888888888811114444444444441111444488882222
dddccc666666666666666666666666ccccccccccdddddc22222222222222222222222dddddcccdddd88888888888888811114444444444441111444488882222
dddccc666666666666666666666666ccccccccccddddd2222222222222222222222222ddddccccdddd8888888888888881144444444444444114444888888222
dddccc666666666666666666666666ccccccccccddd2222222888888888882222222222dccccccdddd8888888888888888882244444444444444442888888222
dddccc666666666666666666666666ccccccccccdd222222288888888888888222222222ccccccdddd8888888888888888888224444444444444422888888222
dddccc666666666666666666666666ccccccccccc2222228888888888888888882222222cccccccdddd888888888888888888822444444444444428888888222
dddccccc6666666666666666666666cccccccccc22222288888888888888888888822222cccccccdddd228888888888888888822444444444444228888888222
dddccccc6666666666666666666666cccccccccc222228888888888888888888888222222ccccccdddd222288888888888888822444444444442228888882222
dddcccccccccccc666666666666666ccccccccc2222288888888888888888888888822222ccccccdddd822222888888888888822444444444422228888222222
dddcccccccccccccccccccccccccccccccccccc22228888888888888888888888888222222cccccdddd888222288888888888822444444442222222882222221
dddcccceeeeccccccccccccccccccccccccccc222288888888888888888888888888822222cccccdddd888888228888888888222222222222222222222222221
dddcccceeeeecccccccccccccccccccccccccc222288888888888888888888888888822222cccccdddd888888888888888882222222222222222222222222211
ddccccceeeeeecccccccccceeeeeeeeeeeccc2222888888888888888888888888888822222cccccdddd888888888888222222222222222222222222222222111
ddccccc22eeeeeeeeeeeeeeeeeeeeeeeeeccc2222888888888888888888888888888882222ccccddddd888888888888222222222822222222222222222221111
ddcccccc2222eeeeeeeeeeeeeeeeeeeeeeccc2222888888888888888888888888888882222cccddddd8888888888888222222888888888888882222222111111
dccccccc2222222eeeeeeeeeeeeeeeeeecccc2222888888888888888888888888888882222ccddddd88887888888888888888888888888888888888221111111
dccccccc2222222eeeeeee222222222eecccc2222888888888888888888888888888882222dddddd888877788888888888888888888888888888888222111111
dcccccccc222222eeeeeee222222222cccccc2222888888888888888888888888888882222dddddd888887888888888888888888888888888888888222111111
dcccccccce22222eeeeeee222222222cccccc2222888888888888888888888888888882222ddddd2188888888888888888888888888888888888888822211111
dcccccccccee222eeeeeeee2222222ccccccc2222888888888888888888888888888882222ddddd2222288888888888888888888888888888888888822211111
dcccccccccce22eeeeeeeeeeeee22cccccccc2222888888888888888888888888888822222ddd222222222888888888888888888888888888888888822221111
dcccccccccceeeeeeeeeeeeeeee2ccccccccc2222888888888888888888888888888822222112222222222228888888888888888888888888888888822221111
ddcccccccccceeeeeeeeeeeeeeddccccccccc2222288888888888888288888888888822222111111222222222288888888888888867777777777777777777611
dddccccccccccceeeeeeeeeeedddccccccccdd22228888888888882288888888888822222211111111222222222228888888888887777d11d61d777777d1d701
ddddccccccccccceeeeeeeeeddddcccccccddd222228888888882228888888888888222222111111111112222222228888888888877771661666777777161700
ddddddccccccccccccccccceddddccccccdddd22222888888822228888888888888822222111111111111122222222888888888887771111d1dd11d117111710
1ddddddcccccccccccccccccddddccccccdddc22222222222222888888888888888822221111111111111111222222228888888887711d771171661617161711
11dddddcccccccccccccccccdddccccccdddccc2222222222228888888888888888222221117711111111111112222228888888887d1d77d17d11d1177d1d711
1ddddddcccccccccccccccccddddcccccdddcccc2222222222888888888888888882222111777711111177771111122228888888877777777777777777777711
dddddddcccccccccccccccccdddddcccdddccccccc22222288888888888888888882222111777711111777777111122222888888877777777777777777777710
ddddddcccccccccccccccccccddddcccdddcccccccc2222288888888888888888822222111177111117777777711112222888888877777777655567777777711
ddddddcccccccccccccccccccddddcccddcccccccccc228888888888888888888222221111111111117777777711112222888888877777777588857777777701
ddddd6ccccccccccccccccccccdddccccccccccccccc228888888888888888888222221111111111117777777711111222888888877777777588857777777710
dddd6666cccccccccccccccccccccccccccccccccccc222888888888888888882222221111111111117777777711111222288888877777655588855567777711
ddd66666ccccccccccccccccccccccccccccccccccc2222222888888888888822222211111111111111777777111011222266888877777599977766657777711
ddd66666666cccccccccccccccccccccccccccccccc2222222288888888222222222211111111111111177771111101122266688877777599977766657777711
dd66666666666cccccccccccccccccccccccccccccc2222222222222222222222222111111111171111111111111110122226666677655599977766655567711
dd66666666666666ccccccccccccccccccddcccccccc2222222222222222222222221111111117771111111111111110222266666775aaa777777777eee57701
dd66666666666666666cccccccccccccccdddccccccdd222222222222222222222211117771111711111111111111111222266666775aaa777777777eee57700
dd6666666666666666666666ccccccccccdddccccccddc22222222222222222221111177777111111111111111111111222266666775aaa777777777eee57700
dccc666666666666666666666666666666dddccccccccccc222222222222222211111177777111111111111111111110222266666776555bbb777ddd55567700
cccccc666666666666666666666666666ddddccccccccccccc2222222222222111111177777111111111111111111111222266666777775bbb777ddd57777700
cccccccccc66666666666666666666666dddddcccccccccccccccccc2222211111111117771111111111111111111111222286666777775bbb777ddd57777700
cccccccccccccc6666666666666666666dddddcccccccccc7ccccccddddd111111111111111111111111111111111111222288666777776555ccc55567777700
ccccccccccccccccc666666666666666dddddddcccccccc777ccccdddddd111111111111111111111111111111111111222288888777777775ccc57777777700
ccccccccccccccccccccc66666666666ddddddddcccccccc7cccccddddd1111111111111111111111111111111111112222288888777777775ccc57777777710
cccccccccdddddccccccccccccccccccdddddddddccccccccccddddddd1111111111111111111111111111111111111222228888877777777655567777777711
ccccccddddddddcccccccccccccccccdddddddd1ddddddddddddddddd11111111111111111111111111111111111111222228888867777777777777777777611

__gff__
0001000503000000000000000000000001090000000000000000000000000000010900000100000000000000010100000101000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000024100110011001100110013100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c0000000000000000000000002c002c00000000000000000000000000002c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003c0000000000000000000000003c003c00000000000000000000000000003c
000024100110011001100110013100000000000024100110011001310000000000002410011001100110011001310000000004040404042d100303030303000000000303030303011004040404040000000021112111211121112111211100000020011001100110011001100110300024030303030303000004040404040431
0000100110011001100110011001000000000000100110011001100100000000000010011001100110011001100100000000011001100110011001100110000000000110011001100110011001100000000001100110011001100110011000000001100110011001100110011001100010011001100110000001100110011001
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
0000000000000404000303000000000000000024100110011001100131000000000000000024100110013100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000110000110000000000000000010011001100110011001000000000000000010011001100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011100140e0501a050000000e0501a0500000010050100501c0501c050110501a05000000110501a0500000013050130501005010050000000000000000000000000000000000000000000000000000000000000
010e002030625306250c0530c05330625306250c0530c0530c0533064500000000003062500000306253062530625306250c0530c05330625306250c0530c0530c05330645000000000030625000003062530625
010300002977129772297372973229727297222972229707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707
010400003507135072350723506035052350423503235020350123501235010350123501235010350123501200010000120000200002000020000200002000010000100001000010000100001000010000100001
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001ac401bc001cc001fc301ec001ec001bc3018c2017c0014c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001564106601066710665106641066330662306613066131564106601066510665106641066001564106601066510665106641066330662306613066000060000600006000060000600006000060000600
010500003547329673334730f6633f613106000665106651066510664106633066230661306611066110660006600066000a700047000a600046000a600046000000000000000000000000000000000000000000
01100000396550a053220231611305713000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200003c071307612b05127751220511d7511b0511875113051117510f0510f7510c0510a7510a0510775107051057510305103751030510375100051007510005100701000010000100001000010000100001
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

