pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- dancejab prototype
-- footsies based fighting game

test=""

--avatar
function createav(x,name,flipped)
 local av={
  --constants, play around with
 
  --how long each action lasts
  -- in frames at 60fps
  dashframes=7,
  jabframes=7,
  jablagframes=10,
  connectlagframes=10,
  hitstunframes=8,
  
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
  animidle=createanim({224,66,226,228,230,232,64,234,236,238},{5,2,5,5,5,5,2,5,5,5}),
  animwalkforward=createanim({128,130,132,134},5),
  animwalkback=createanim({136,138,140,142},5),
  animdashforward=createanim({37,96,5},{3,2,2},false),
  animdashback=createanim({39,98,7},{3,2,2},false),
  animjab=createanim({72,74,76},{3,6,1},false),
  animringout=createanim({192,194},6,false),
  animjablag=createanim({78,44,100},{3,3,5},false),
  animconnectlag=createanim(7),
  animhitstun=createanim(108),
  animlostround=createanim({108,110},{6,1},false),
  animlostmatch=createanim({160,162,164,166},{6,3,10,10}),
  animvictory=createanim({168,170,172,174},6),
  animclank=createanim(106),

  hitpoints=maxhitpoints,
 
  --vars, don't edit
  x=x,
  xvel=0,
  y=96,
  yvel=0,
  flipped=flipped,
  state="none",
  statetimer=0,
  name=name,
 }
 av.anim=av.animidle
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
 }
 add(hitboxes,box)
 return box
end

function _init()
 music(0)

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

 mode="normal"

 resetmatch()
 
 currentupdate=updatestart
 currentdraw=drawstart
end

function resetmatch()
 resetround()
 
 --vars
 announce=""
 p1.score=0
 p2.score=0

 --todo:back to menu option
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

 p1=createav(24,"red")
 p1.no=0
 p1.score=scorep1
 
 p2=createav(88,"blue",true)
 p2.no=1
 p2.score=scorep2

 --remember opponent avatar
 p1.oav=p2
 p2.oav=p1
end

function initcountdown()
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
  currentupdate=updatemenu
  currentdraw=drawmenu
 end
end

function updatemenu()
 if btnp(❎) or btnp(🅾️) then
  initcountdown()
  currentupdate=updatecountdown
  currentdraw=drawcountdown
 
  if btnp(❎) then
   mode="normal"
  end

  if btnp(🅾️) then
   mode="sumo"
  end
 end
end

function updatecountdown() 
 updateanim(p1.anim)
 updateanim(p2.anim)

 if countdownno==3 and ctvel==0 then
  sfx(2)
 end

 ctvel+=0.25
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
 end
 
 --jab
 if btnp(🅾️,av.no) then
  sfx(9+flr(rnd(2)))
  av.state="jab"
  av.anim=av.animjab
  av.statetimer=av.jabframes
  createhitbox(av.jabwidth,av.jabheight,av)
 end
end

function updateav(av)
 if av.statetimer>0 then
  av.statetimer-=1
 end

 --on ground?
 if checkavflagarea(
    globalbox(av,av.hurtbox),0) then
  av.yvel=0
 else
  --on first ringout detection
  if av.state!="ringout" then
   av.hitpoints=0

   --prevent double death
   if av.state!="dead" then
    sfx(15)
    av.anim=av.animringout
    updatescore(av)
    av.statetimer=90
   end
   
   av.state="ringout"
  end
 end
 
 hitboxcollision(av)
 
 --can only act in some states
 if av.state=="none" or
    av.state=="dash" then
  detectinputs(av)
 end
 
 if av.state=="none" then
  --check for winner
  -- (after round end pause)
  -- and hard reset
  if av.score==firstto then
   resetmatch()
  end

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
   av.xvel*=av.xdecellrate
   av.anim=av.animidle
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
  av.xvel=0
 elseif av.state=="connectlag" then
  --pause
 elseif av.state=="hitstun" then
  --pause
 elseif av.state=="won" then
  av.xvel=0
 elseif av.state=="dead" then
  av.xvel*=0.9

  if av.statetimer==0 then
   resetround()
  end
 elseif av.state=="ringout" then
  av.yvel+=gravity
  av.xvel*=0.9
  
  if av.statetimer==0 then
   resetround()
  end
 end
 
 if av.statetimer==0 then
  av.state="none"
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

function hitboxcollision(av)
 for box in all(hitboxes) do
  if box.pno!=av.no then

   if aabbcollision(globalbox(av,av.hurtbox),box) then
    --other avatar pauses
    av.oav.state="connectlag"
    av.oav.statetimer=av.oav.connectlagframes
    av.oav.anim=av.oav.animconnectlag
    av.oav.xvel=0

    --been punched!
    if mode!="sumo" then
     av.hitpoints-=1
    end

    av.state="hitstun"
    av.statetimer=av.hitstunframes
    av.anim=av.animhitstun

    if av.flipped then
     av.xvel=hitknockback
    else
     av.xvel=-hitknockback
    end

    if av.hitpoints==0 then
     sfx(14)
     av.anim=av.animlostround
     updatescore(av)
     av.state="dead"
     av.statetimer=90
    else
     sfx(12)
    end

    del(hitboxes,box)
   end
  end
 end
end

--pass in av that just died
function updatescore(av)
 av.oav.score+=1
 
 if av.oav.score==firstto then
  announce=av.oav.name.." wins!"
  sfx(0)
  av.anim=av.animlostmatch
 end
 av.oav.state="won"
 av.oav.anim=av.animvictory
 av.oav.statetimer=90
end

function updatehitbox(box)
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
     box.pno!=otherbox.pno then
   --hitboxes colided,
   -- seperate avs
   -- (should be generic...)
   
   p1.anim=p1.animclank
   p2.anim=p2.animclank
   p1.xvel=-1
   p2.xvel=1
   
   --...or could just visually remove it
   --todo:should have some sparks or something
   del(hitboxes,box)
   del(hitboxes,otherbox)
  end
 end 
end

function _draw()
 cls(1)
 currentdraw()
 print(test,0,0,4)
end

function drawstart()
 sspr(0,50,16,16,
  10,40,32,32)

 drawwithp2colours(drawp2start)

 print("dancejab!",30,30,7)

 print("press any to start",20,100,7)
end

function drawmenu()
 sspr(0,50,16,16,
  10,40,32,32)

 drawwithp2colours(drawp2start)

 print("normal mode: ❎",20,100,7)
 print("sumo mode: 🅾️",20,110,7)
end

function drawcountdown()
 drawgame()

 sspr(xcorner,16,8,8,
  ct/2,ct/2,
  128-ct,128-ct)
end

function drawgame()
 --drawbackground()
 map(0,0,0,0,16,16)
 
 spr(p1.anim.sprite,p1.x,p1.y,2,2,p1.flipped)

 drawavhitboxes(p1)
 
 drawwithp2colours(drawp2)
 
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
 if mode=="sumo" then
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

 print(announce,30,64)

 --debug info
 --drawlocalbox(p1,p1.pushbox,5)
 --drawlocalbox(p1,p1.hurtbox,9)

 -- for box in all(hitboxes) do
 --  rectfill(box.x,box.y,
 --   box.x+box.width,
 --   box.y+box.height,3)
 -- end
end

function drawp2start()
 sspr(96,50,16,16,
  66,42,32,32,true)
end

function drawp2()
 spr(p2.anim.sprite,p2.x,p2.y,2,2,p2.flipped)

 drawavhitboxes(p2)
end

function drawwithp2colours(drawing)
 pal(8,12)
 pal(2,13)
 pal(12,8)
 pal(1,2)
 
 drawing()

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
   spr(2,boxx,box.y,1,1,av.flipped)
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
 return checkflagarea(av.x,av.y,av.width,av.height,f)
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
      a.along=#a.sprites
     end
    end
  end
  
  a.sprite=a.sprites[a.along]
 end
end

__gfx__
00000000d6666666cc7ccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4994bbbb4994bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000002dddddd667cccbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbb888888888bbbbbbbbbbbbb4a88a4bb4acca4bbbbbbbbbbbbbbbbbbbbbbbbbbbbb5000
007007002d2666d676cccbbbbbbbbbbbbbbbbbbbbbbb28887877782bbb28888878782bbbbbbbbbbbb988e79bb9cc679bbbbbbb000bbbbbbbbbbbbbbbbbbb5670
000770002d2dd6d6cccccbbbbbbbbbbbbbbbbbbbbbbb88888888878bbb88888888878bbbbbbbbbbbb9887e9bb9cc769b0000000670bbbbb000bb000bbbbb0770
000770002d2dd6d6cccccbbbbbbbbbbbbbbbbbbbbbbb888888888882bb888888888882bbbbbbbbbbb988889bb9cccc9b06777707700000006700670000000770
007007002d2222d6cccccbbbbbbbbbbbbbbbbbbbbbb2828288888828b2828288888828bbbbbbbbbbb988889bb9cccc9b06767700006777770700775777770670
000000002dddddd6cccccbbbbbbbbbbbbbbbbbbbbbb8882228888228b8882228888228bbbbbbbbbbb4a88a4bb4acca4b06755006707777770700770777770670
000000002222222dccccbbbbbbbbbbbbbbbbbbbbbbb8882222222228b8882222222228bbbbbbbbbbbb4994bbbb4994bb07777007707700006700770067000670
5dddddddccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbb8888211ee1122b2882211221122bbbbbbbbbbbb4994bbbbbbbbbb077670077077006707777705770b5770
2555555dccccccccb51111000000000000001bbbbbbcccc8eeeee88bbb88cccccee88bbbbbbbbbbbb4adda4bbbbbbbbb077000077077007707777700770bb00b
255ddd5dccccccccb1bbbbbbbbbbbbbbbbbb65bbbbbc67cc8eee888bbb28c67ccc888bbbbbbbbbbbb9dd679bbbbbbbbb0770bb076077777707007700770bbbbb
25255d5dccccccccb1bbbbbbbbbbbbbbbbbb761bbbbcc61c828b82bbbbbbcc6c1c82bbbbbbbbbbbbb9dd769bbbbbbbbb0670bb055067777707007700770b5000
25255d5dccccccccb567bbbbbbbbbbbbbbbbbb1bbbbccc1c888bbbbbbbbbcccc1c8bbbbbbbbbbbbbb9dddd9bbbbbbbbb0770bbbbbb05500007007700770b0670
2522255dccccccccbb56bbbbbbbbbbbbbbbbbb1bbbbccc1c88bbbbbbbbbbcccc1c8bbbbbbbbbbbbbb9dddd9bbbbbbbbb0000bbbbbbbbbbb005bb5000670b0660
2555555dccccccccbbb5100000000000011111dbbbbcc11b88bbbbbbbbbbccc1188bbbbbbbbbbbbbb4adda4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000b5005
22222225ccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbebbbbbbbbbbbebbbebbbbbbbbbbbbbbb4994bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
2222f222dddddddd5dddddddd6666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbb000bbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
2ffffff2d111111d2555555d2dddddd6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb067770bbb07770bbbb0670bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
2ffffff2d6dddd1d2555555d2dddddd6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0777770b0677770bb06770bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
fffffff2d6d11d1d2555555d2dddddd6bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb005670b0770770bbb0770bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
2fffffffd6d61d1d2555555d2dddddd6bbbbbbbbbbbbb8888888888bbb28888888888bbbb066770bb007770bbb0770bbbbbb888888888bbbbbbbbbbbbbbbbbbb
fffffff2d6dddd1d2555555d2dddddd6bbbbbbbbbbbb888887877782bb888887777888bbb005670bb06750bbbb0770bbbbb28888878782bbbbbbbbbbbbbbbbbb
2ffffff2d666661d2555555d2dddddd6bbbbbbbbbbb8888888888878b88888888887888b0677770b0677770bbb0770bbbbb88888888878bbbbbbbbbbbbbbbbbb
2222f222dddddddd22222255222222ddbbbbbbbbbbb8888888888888b88828888882888b0777770b0777770bbb0670bbbbb888888888882bbbbbbbbbbbbbbbbb
dddddd1dd6ddddddbbbbbbbbbbbbbbbbbbbbbbbbbbb8282888888882b88222888822288b000000bb0000000bbb0000bbbb2828288888828bbbbbbbbbbbbbbbbb
d11111111d66661dbbbbbbbbbbbbbbbbbbbbbbbbccccccc222222222b88211111111188bbbbbbbbbbbbbbbbbbbbbbbbbbb8882228888228bbbbbbbbbbbbbbbbb
d6dddd1dd611116dbbbbbbbbbbbbbbbbbbbbbbbbcc67777c11111111b88cccccccccc88bbbbbbbbbbbbbbbbbbbbbbbbbbcccccc11221128bbbbbbbbbbbbbbbbb
d6d11d1dd61dd16dbbbbbbbbbbbbbbbbbbbbbbbbcccccccc8eeeee88b88c777777ccc88bbbbbbbbbbbbbbbbbbbbbbbbbbcc67ccceee1228bbbbbbbbbbbbbbbbb
d6d61d1dd616d16dbbbbbbbbbbbbbbbbbbbbbbbbcccccccc88eee888b88cccccccccc88bbbbbbbbbbbbbbbbbbbbbbbbbbccc6c1ceeee88bbbbbbbbbbbbbbbbbb
d6dddd1dd611116dbbbbbbbbbbbbbbbbbbbbbbbbcccccccc2828b82bbb8cccccccccc8bbbbbbbbbbbbbbbbbbbbbbbbbbbccccc1c2ee888bbbbbbbbbbbbbbbbbb
6d66661dd16666d6bbbbbbbbbbbbbbbbbbbbbbbbcccccccc888bbbbbbbbcccccccccc8bbbbbbbbbbbbbbbbbbbbbbbbbbbccccc1c88b82bbbbbbbbbbbbbbbbbbb
d6dddddddddddd1dbbbbbbbbbbbbbbbbbbbbbbbbbbbebbebbbbbbbbbbbbbbbbbbebbbbebbbbbbbbbbbbbbbbbbbbbbbbbbcccc11bbebbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888878bbbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2888888888888bbbbb28888878782bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbb888888888bb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8828288888828bbbbb88888888878bbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbb2888888782bbbbb28888878782b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8882228888228bbbb2888888888882bbbbbb28888888bbbbbbb8888888782bbbbb88888888878bbbbb88888888878b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8882212221228bbbb8828288888828bbbbb2888787772bbbbb888888888788bbbb888888888882bbb2888888888882
bb28888888888bbbbbb28888888888bbbccccc812ee1228bbbb8882228888228bbbb288888888888bbb2888888822882bbb2888888222888bbb8828288888828
b2888888888888bbbb2888888888888bbc7cccceeeee888bbbb8882111221128bbbb888888888888bbb2888882212888bbb2888888211288bbb8882228888228
288888888888888bb288888888888888bc7cc1c8eee888bbbbb2882212ee1228bbccccccccccccccbbb2888888221288bbb2888888821ebbbbb288211122ccc8
28ccccc88888288bccccc88888888288bcccc1c828888bbbbccccc88eeeee88bbbcccc666666677cbbbb288282222288bbbb2888882c67ccbbbc6777776666c2
28c67ccc8882288bc67c1c8288882288bcccc1c2888bbbbbbc67ccc88eee882bbccccccccccccc6cbbbbb8888888881cbbbbb288888cc6ccbbbccccccccccccb
28cc6c1c8211188bcc6c1c8112211188bccc1188888bbbbbbcc6c1c2828b82bbbcccccccccccccccbbbb2888888881ccbbbb8822288cccccbbbccccccccccccb
28cccc1c8e22888bcccc1c82eee22888bbbbbb88888bbbbbbcccc1c8888bbbbbccccccccccccccccbbb88888888811ccbbb88888881cccccbbbccccccccccccb
28ccc1188e8888bbccc11882eee8888bbbbbbb88888bbbbbbcccc1c8888bbbbbccccccccccccccccbb28888888bbbbbcbb8888888bbcccccbbb6cccccccccccb
b288888888828bbbbbb88888888828bbbbbbbbebbbebbbbbbccc11ebbbebbbbbbebbbbbbbbebbbbbbebbbbbbbebbbbbbbebbbbbbebbbbbbbbbbbbccccccc6bbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbbb
bbbbb888888888bbbb28888878782bbbbbbb888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbb28888878782bbbbbbb88888888bbbb
bbbb28887877782bbb88888888878bbbbbb28888878782bbbbbbbb88888888bbbbbbbbbbbbbbbbbbbbb28888888782bbbb88888888878bbbbbb28888877882bb
bbbb88888888878bbb888888888882bbbbb88888888878bbbbbbb8888888788bbbbbbbbbbbbbbbbbbbb88888888778bbb2888888888882bbbbb88888888878bb
bbbb888888888882b2828288888828bbbbb888888888882bbbbb888888888788bbbbbbbbbbbbbbbbbb2888888878882bb8828288888828bbbb2888888888882b
bbb2828288888828b8882228888228bbbb2828288888828bbbb2888888822888bbbbbbbbbbbbbbbbbb88ccccc888828bb8882228888228bbbb8828888888888b
bbb8882228888228b8882222222228bbbb8882228888228bbbb2888882212888cc7ccccbbbbbbbbbbb88c67ccc88288bb8888212222128bbbb8882288888828b
ccccccc222222228b28ccccccc1122bbbccccc111221128bbbb288888822128167cccccbbbbbbbbbbb28cc6c7c22128bb2888881ee1222bbbb2888228888228b
c677777c11ee1122bb8c67ccccc88bbbbc67ccc1eee1e82bbbbb28828222221c76cccccbbbbbbbbbbb28cccccce1e88bccccc88eeee88bbbccccc1811221188b
cccccccceeeee88bbb2cc6cccccc8bbbbcc6c1c2eeee88bbbbbbb8888888881ccccccccbbbbbbbbbbb28ccccccee88bbc67ccceeee882bbbc67ccc8222e2882b
cccccccc8eee888bbbbcccccccccbbbbbcccc1c82ee888bbbbbb2888888881cccccccccbbbbbbbbbbbb2cccc12e882bbcc6c1c888828bbbbcc6c1c882ee888bb
cccccccc828b82bbbbbcccccccccbbbbbcccc1c888b82bbbbbb88888888811cccccccccbbbbbbbbbbbbb222288b28bbbcccc1c8888bbbbbbcccc1c2288b28bbb
cccccccc88bbbbbbbbbcccccccccbbbbbccc118888bbbbbbbb2888888bbbbbcccccccccbbbbbbbbbbbbbb88888bbbbbbcccc1c8888bbbbbbcccc1c8888bbbbbb
bbbbebbbebbbbbbbbbbbbbebbbebbbbbbbbbebbbbbebbbbbbebbbbbbebbbbbccccccccbbbbbbbbbbbbbbebbbbbebbbbbccc11bebbbebbbbbccc11ebbbbebbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbb
bbbb28888878782bbbbbb288888882bbbbbbb288888882bbbbbb28888878782bbbb28888878782bbbbbb288888882bbbbbbb288888882bbbbbb28888878782bb
bbbb88888888878bbbbb28888878782bbbbb28888878782bbbbb88888888878bbbb88888888878bbbbb28888878782bbbbb28888878782bbbbb88888888878bb
bbb2888888888882bbbb88888888878bbbbb88888888878bbbb2888888888882bb2882888888882bbbb88888888878bbbbb88888888878bbbb2882888888882b
bbb8888288888828bbb2888888888882bbb2888888888882bbb8888288888828bb8822288888828bbb2882888888882bbb2882888888882bbb8822288888828b
bbb8888228888228bbb8888288888828bbb8888288888828bbb8888228888228bb8822228888228bbb8822288888828bbb8822288888828bbb8822228888228b
bbb2888211121128bbb8888228888228bbb8888228888228bbb8888211121128bb8822112211228bbb8822228888228bbb8822228888228bbb8822112211228b
ccccc288e1ee1228ccccc88211121128bbb8888211121128bbb28888e1ee1228bccccc122e12228bbccccc112211228bbb2822112211228bbb8882122e12228b
c67ccc888eeee28bc67ccc8821ee1228ccccc88821ee1228ccccc2888eeee28bbc67ccceeeee88bbbc67ccc22e12228bbccccc122e12228bbccccc8eeeee88bb
cc6c1c2888ee288bcc6c1c888eeee28bc67ccc888eeee28bc67ccc2888ee288bbcc6c1c8eee882bbbcc6c1ceeeee88bbbc67ccceeeee88bbbc67ccc8eee882bb
cccc1c22828888bbcccc1c2888ee288bcc6c1c2888ee288bcc6c1c22828888bbbcccc1c828b88bbbbcccc1c8eee882bbbcc6c1c8eee882bbbcc6c1c828b88bbb
cccc1cb88882bbbbcccc1c22828888bbcccc1c22828888bbcccc1cb88882bbbbbcccc1c888bbbbbbbcccc1c828b88bbbbcccc1c828b88bbbbcccc1c888bbbbbb
ccc11bb88888bbbbccc11bb88888bbbbcccc1cb88888bbbbcccc1cb88888bbbbbccc118888bbbbbbbccc118888bbbbbbbcccc1c888bbbbbbbcccc1c888bbbbbb
bbbbbbbebbbebbbbbbbbbbbebbbbebbbccc11bbebbbbebbbccc11bebbbebbbbbbbbbbbebbebbbbbbbbbbbbebbbebbbbbbccc11ebbbebbbbbbccc11bbebbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbbbbbbbbbbbbbbbb
bbbb28888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888888888bbbbbb28888878782bbbbbb888888888bbb
bbb2888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbb88888888878bbbbb28888878782bb
bbb88888888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888878bbbb2888888888882bbbb88888888878bb
ccccc288888888bbbbbbb2888888bbbbbbbbbbbbbbbbbbbbbbbbb88888888bbbbbbbb888888888bbbb2888888888882bbb8828288888828bbb2888888888882b
c67ccc288888282bbbcccc88877882bbbbbbb88888888bbbbbbb28888877882bbbbb28888878782bbb8828288888828bbb8882218881228bbb8828288888828b
cc6c1c212222188bccc67cc8888788bbbbbb28888877882bbbbb88888888878bbbbb88888888878bbb8882111811128bbb8882121212128bbb8882218881228b
cccc1c821221288bbccc7cc88888882bbbbb88888888878bbbb2888888888882bbb2888888888882bb8882222222228bbccccc222ee2228bbb8882121212128b
cccc1c88ee22888bbccccc7c8888888bbbb2888888888882bbb8828888888888bbb8828288888828bb8888222ee2228bbcc7ccceeeee88bbccccc8222ee2228b
ccc11288eee2888bbbcccc7c8888828bbbb8828888888888bbb8882288888828bccccc2228888228bb28888eeeee88bbbcc6c1c8eee888bbcc7ccc8eeeee88bb
bbb288888ee888bbbbcccccc8888228bbbb8882288888828bccccc8228888228bc67ccc212222128bbb28888eee888bbbcccc1c828b82bbbcc6c1c88eee888bb
bbbb288288bb8bbbbbcccccc2222288bccccccc228888228bc67cc1811221188bcc6c1c221ee1228bccccc8828b82bbbbcccc1c888bbbbbbcccc1c8828b82bbb
bbbbb88888bbbbbbbbcccc1c22e2882bcc677cc811221188bcc6ccc8222e2882bcccc1c8eeeee88bbcc6c1c888bbbbbbbccc118888bbbbbbcccc1c8888bbbbbb
bbbbb88888bbbbbbbbcccc1c2ee888bbccc67ccc222e2882bcccc1c882ee888bbcccc1c88eee888bbcccc1c888bbbbbbbbbbbebbbbebbbbbccc1188888bbbbbb
bbbbb88888bbbbbbbbcccc1c88b28bbbcccccc1c82ee888bbcccc1c2288b28bbbccc1182828b82bbbcccc1c888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbb
bbbbbebbbebbbbbbbbccc11c88bbbbbbcccccc1c288b28bbbccc1128888bbbbbbbbbbb28888bbbbbbccc11ebbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bb
bbbb88888888bbbbbbbb88888888bbbbbbbb288888888bbbbbbb288888888bbbbbbbb888888888bbbbb88888888bbbbbbbbbbbbbbbbbbbbbbbbb28888878782b
bbb28888877882bbbbb28888877882bbbbb28888887782bbbbb28888887782bbbbbb28888878782bbb28888877882bbbbbbbbbbbbbbbbbbbbbbb88888888878b
bbb88888888878bbbbb88888888878bbbbb88888888878bbbbb88888888878bbbbbb88888888878bbb88888888878bbbbbbbbbbbbbbbbbbbbbb2888888888882
bb2888888888882bbb2888888888882bbb2888888888882bbb2888888888882bbbb2888888888882b2888888888882bbbbbbbbbbbbbbbbbbbbb8828288888828
bb8828888888888bccccc2888888888bbb8888888888888bbb8888888888888bbbb8828288888828b8828888888888bbbbbbbbbbbbbbbbbbbbb8882228888228
ccccc2288888828bc67ccc288888828bbb8888828888288bbb8888828888288bbbb8882228888228b8882288888828bbbbbbbbbbbbbbbbbbbbbc7c2111221128
c67ccc228888228bcc6c1c228888228bbb2ccccc2222128bbb888ccccc22118bbbb2882111221128b2888228888228bbbbbbbbbbbbbbbbbbbbccc7c212ee1228
cc6c1c811221188bcccc1c822222288bbb2c67cccee1e88bbb888c67ccc2188bbbbc67cc1eee1222ccccc111221188bbbbbbbbbbbbbbbbbbbccccc7ceeeee88b
cccc1c8222e2882bcccc1c8222e2882bbb2cc6c1ceee88bbbb288cc6c1ce88bbbbbcc6c1ceeee88bc76ccc222e2882bbbbbbbbbbbbbbbbbbbccccccc8eee882b
cccc1c882ee888bbccc112882ee888bbbbbcccc1c2e882bbbbb28cccc1c882bbbbbcccc1ceee888bc6cc1c82ee888bbbbbbbbbbbbbbbbbbbb6cccc1c828b82bb
ccc1122288b28bbbbbbbb82288b28bbbbbbcccc1c8b28bbbbbbb2cccc1c28bbbbbbcccc1c2bb82bbcccc1c288b28bbbbbbbbbbbbbbbbbbbbbb6cc1cc888bbbbb
bbbbbee888ebbbbbbbbbbee888ebbbbbbbbccc1128bbbbbbbbbb2ccc112bbbbbbbbccc1188bbbbbbcccc1c888bbbbbbbbbbbbbbbbbbbbbbbbbb66c88888bbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbebbbbbbbbbebbbbbebbbbbbbbbbebbbbebbbbbccc11ebbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbebbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb288888882bb
bbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782bbbbbb288888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28888878782b
bbbb28888878782bbbbbbbbbbbbbbbbbbbbbb288888882bbbbb88888888878bbbbb28888878782bbbbbbbbbbbbbbbbbbbbbb288888882bbbbbbb88888888878b
bbbb88888888878bbbbbb288888882bbbbbb28888878782bbb2888888888882bbbb88888888878bbbbb288888882bbbbbbb28888878782bbbbb2888888888882
bbb2888888888882bbbb28888878782bbbbb88888888878bbb8828288888828bbb2888888888882bbb28888878782bbbbbb88888888878bbbbb8828288888828
bbb8828288888828bbb288888888878bbbb2888888888882bb8882228888228bbb8888288888828bbb28888888878bbbbb2888888888882bbbb8882228888228
bccccc2228888228bbb8888888888882bbb8828288888828bb8882111221128bbb8882228888228bb2888888888882bbbb8828288888828bbbccccc211221128
bc67ccc111221128ccccc82888888828bbb8882228888228bb2888212ee1228bbb8882111221128bb2888888888828bbbb88ccccc888228bbbc67ccc12ee1228
bcc6c1c212ee1228c67ccc8228888228ccccc22111221128bbb2888eeeee88bbbb2882212ee1228bb28ccccc888228bbbb88c67cc221128bbbcc6c1c8eeee88b
bcccc1c8eeeee88bcc6c1c8111221128c67ccc8212ee1228bc7cccc8eee882bbbbccccc2eeee88bbb28c67ccc21128bbbb88cc6c1221228bbbcccc1c88ee882b
bcccc1c8eeee882bcccc1c8212221228cc6c1c88eeeee88bbc6cccc828882bbbbbc7ccc1eee882bbb28cc6c1ce1228bbbb28cccc1eee88bbbbcccc1c888b82bb
bccc1188228b82bbcccc1c88eeeee88bcccc1c288eee882bbcccccc8888bbbbbbbc6cc1c22882bbbb28cccc1cee88bbbbbb8cccc1ee882bbbbccc118888bbbbb
bbbbbb88888bbbbbccc118888eee882bcccc1c82828b82bbbcccc1c8888bbbbbbbcccc1c888bbbbbbb8cccc1ce882bbbbbbbccc112282bbbbbbbbb88888bbbbb
bbbbbb88888bbbbbbbbbbb22828b82bbccc11b88888bbbbbbcccc1c8888bbbbbbbcccc1c888bbbbbbbbccc118882bbbbbbbbbb88228bbbbbbbbbbb88888bbbbb
bbbbbbebbbebbbbbbbbbbbebbbbebbbbbbbbbbebbbbebbbbbccc118bbbebbbbbbbcc1112bbebbbbbbbbbbebbbbebbbbbbbbbbebbbbebbbbbbbbbbbebbbebbbbb
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
888888888888888888888888888888888888888888888888888888888888888888888888888888888882282288882288228882228228888888ff888888228888
888882888888888ff8ff8ff88888888888888888888888888888888888888888888888888888888888228882288822222288822282288888ff8f888888222888
88888288828888888888888888888888888888888888888888888888888888888888888888888888882288822888282282888222888888ff888f888888288888
888882888282888ff8ff8ff888888888888888888888888888888888888888888888888888888888882288822888222222888888222888ff888f888822288888
8888828282828888888888888888888888888888888888888888888888888888888888888888888888228882288882222888822822288888ff8f888222288888
888882828282888ff8ff8ff8888888888888888888888888888888888888888888888888888888888882282288888288288882282228888888ff888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555500000000000055555555555555555555555555555555555555500000000000055000000000000555
555555e555566656555555e555555555555665666566555506600600000055555555555555555555565555665566566655506660666000055066606660000555
55555ee555565656555555ee55555555556555656565655500600600000055555555555555555555565556565656565655506060606000055060606060000555
5555eee555565656665555eee5555555556665666565655500600666000055555555555555555555565556565656566655506060606000055060606060000555
55555ee555565656565555ee55555555555565655565655500600606000055555555555555555555565556565656565555506060606000055060606060000555
555555e555566656665555e555555555556655655566655506660666000055555555555555555555566656655665565555506660666000055066606660000555
55555555555555555555555555555555555555555555555500000000000055555555555555555555555555555555555555500000000000055000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555566666577777566666566666555555588888888566666666566666666566666666566666666566666666566666666566666666555555555
55555665566566655565566575557565556565656555555588877888566666766566666677566777776566667776566766666566766676566677666555dd5555
5555656565555655556656657775756665656565655555558878878856667767656666776756676667656666767656767666657676767656677776655d55d555
5555656565555655556656657555756655656555655555558788887856776667656677666756676667656666767657666767657777777756776677655d55d555
55556565655556555566566575777566656566656555555578888887576666667577666667577766677577777677576667767567676767577666677555dd5555
55556655566556555565556575557565556566656555555588888888566666666566666666566666666566666666566666666567666667566666666555555555
55555555555555555566666577777566666566666555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555555555555005005005005005dd500566555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555565655665655555005005005005005dd5665665555555777777775dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd555555555
555565656565655555005005005005005775665665555555777777775d55ddddd5dd5dd5dd5ddd55ddd5ddddd5dd5dd5ddddd5dddddddd5dddddddd555555555
555565656565655555005005005005665775665665555555777777775d555dddd5d55d55dd5dddddddd5dddd55dd5dd55dddd55d5d5d5d5d55dd55d555555555
555566656565655555005005005665665775665665555555777557775dddd555d5dd55d55d5d5d55d5d5ddd555dd5dd555ddd55d5d5d5d5d55dd55d555555555
555556556655666555005005665665665775665665555555777777775ddddd55d5dd5dd5dd5d5d55d5d5dd5555dd5dd5555dd5dddddddd5dddddddd555555555
555555555555555555005665665665665775665665555555777777775dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000060600e0000c0000ddd005500770000066000eee00ccc000000055000000000000000000000000000005500000000000000000000000000000555
55507000000060600e0000c000000d005507000000006000e0e00c00000000055000000000000000000000000000005500000000000000000000000000000555
55507700000066600eee00ccc000dd005507000000006000e0e00ccc000000055000000000000000000000000000005500000000000000000000000000000555
55507000000000600e0e00c0c0000d005507070000006000e0e0000c000000055000000000000000000000000000005500000000000000000000000000000555
55507000000000600eee00ccc00ddd005507770000066600eee00ccc000d00055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600e0000c0000ddd005500770000066000eee00ccc000000055000000000000000000000000000005500000000000000000000000000000555
55507000000000600e0000c000000d005507000000006000e0e00c00000000055000000000000000000000000000005500000000000000000000000000000555
55507700000006600eee00ccc000dd005507000000006000e0e00ccc000000055000000000000000000000000000005500000000000000000000000000000555
55507000000000600e0e00c0c0000d005507070000006000e0e0000c000000055000000000000000000000000000005500000000000000000000000000000555
55507000000066600eee00ccc00ddd005507770000066600eee00ccc000d00055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507700707066600e0000ccc00ddd005500770000066000eee00ccc000000055000000000000000000000000000005500000000000000000000000000000555
55507070777000600e0000c000000d005507000000006000e0e00c00000000055000000000000000000000000000005500000000000000000000000000000555
55507070707066600eee00ccc000dd005507000000006000e0e00ccc000000055000000000000000000000000000005500000000000000000000000000000555
55507070777060000e0e0000c0000d005507070000006000e0e0000c000000055000000000000000000000000000005500000000000000000000000000000555
55507770707066600eee00ccc00ddd005507770000066600eee00ccc000d00055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507700707066600eee00ccc0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507070777000600e0e00c000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507070707066600e0e00ccc0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507070777060000e0e0000c0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770707066600eee00ccc000d000550010001000100001000010000100055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55501111111aaaaa1111111111111110550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507711717a66aa1eee11ccc1111110550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507171777aa6aa1e1e11c111111110550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507171717aa6aa1e1e11ccc1111110550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507171777aa6aa1e1e1111c1111110550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507771717a666a1eee11ccc111d110550010001000100001000010000100055001000100010000100001000010005500100010001000010000100001000555
55501111111aaaaa1111111111111110550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000001710000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000001771000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550777000006600177710ccc0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550700000000600177771c000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
5550770000000600177110ccc0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
555070000000060001171000c0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600eee00ccc000d000550010001000100001000010000100055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066000eee00ccc0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507000000006000e0e00c000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507700000006000e0e00ccc0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507000000006000e0e0000c0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600eee00ccc000d000550010001000100001000010000100055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066000eee00ccc0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507000000006000e0e00c000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507700000006000e0e00ccc0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507000000006000e0e0000c0000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600eee00ccc000d000550010001000100001000010000100055001000100010000100001000010005500100010001000010000100001000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0001000000000000000000000000000001000000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000011001100110011001100110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000100110011001100110011001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010c00001c350000001c350000001c350000002135021350213502135000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000030625306250c0530c05330625306250c0530c0530c053306450000000000306250000030625306253c615000000c0433c615000000000030620306153c6150c043000003c6150c043000003c6153c623
000200001e1601c1601a15014140101400e1300b12006110001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002b1702b1602b1502b1402b1302b1202b1102b110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000740006400054000440002400024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002d3002d3002b3002a3002830024300203001b30017300123000d300073000130001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00000c0630c000000000c60024645186250c6150c0000c0000c0000c0630c0000c0000c0000c0630c00024645186250c0630c00000000000000c0430c0430c0530c0000c0430000024655186250c61500000
010d00000c0633f215272152721524645186253f2150c0003f2003f2150c0630f21527215272150c0630c00024645186250c6150c0633f2150c0630c0430c0430c0533f2150c0433f21524655186250c6150c615
010d00200c0730c000000000c60024655186450c6250c0003f200272000c0730c0003f200272000c0733f21524665186550c0233f22524665186550c0230c0433f225272150c0433f21524655186450c6250c615
010d00200c0633f215272152721524645186253f2150c0003f2003f2150c0630f21527215272150c0630c00024645186250c6150c0633f2150c0630c0430c0430c0533f2150c0433f21524655186250c6150c615
010d00200c0630c000000000c60024645186250c6150c0000c0000c0000c0630c0000c0000c0000c0630c0000c0000c0000c0630000000000000000c0430c0430c0530c0000c0430000024655186250c61500000
010d0020277001a0001c0001d0001f0001f0001f0001f0001f000210002100023000230002100021000230002300007000070000700007700070000700007000077000700007000050001b0201d7311d0421f761
010d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000074000c0130742505225074250723513435
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
__music__
00 17555644
00 17195844
01 17231844
01 17231b44
00 17251a44
00 17261c44
00 24231d44
00 16272044
00 15281f44
00 24272044
00 16222144
02 132b2a44
00 575a6144
01 2e2f3144
02 2e303244

