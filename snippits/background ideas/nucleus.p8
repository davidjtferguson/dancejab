pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--necleus program
--potentual background idea

electrons={}
particles={}

function makeparticle(x,y,z,xvel,yvel,zvel,r,col)
 p={}
 p.x=x
 p.y=y
 p.z=z
 p.xvel=xvel
 p.yvel=yvel
 p.zvel=zvel
 p.r=r
 p.col=col
 add(particles,p)
 return p
end

function _init()

 -- nucleus
 nuk=makeparticle(60,60,1,0,0,0,4,7)

 add(electrons,
     makeparticle(30,30,1, 1,-0.2,1, 1,3))
 
 add(electrons,
     makeparticle(90,30,1, 0.2,1,-1, 1,11))
 
 add(electrons,
     makeparticle(90,90,1, -1,0.2,1, 1,12))
 
 add(electrons,
     makeparticle(30,90,1, -0.2,-1,-1, 1,13))
end

function _update()
 for e in all(electrons) do
  --update vel to move to nuk
  local xvec=nuk.x-e.x
  local yvec=nuk.y-e.y
  local zvec=nuk.z-e.z

  e.xvel=e.xvel+xvec*0.009
  e.yvel=e.yvel+yvec*0.009
  e.zvel=e.zvel+zvec*0.009

  e.x=e.x+e.xvel
  e.y=e.y+e.yvel
  e.z=e.z+e.zvel
  
 end
end

-->8

function _draw()
 cls()

 for p in all(particles) do
  local z=p.z

  --have a 'back layer'?
  -- go to darker color and
  -- draw first? 
  if z <= 0 then
   z=1;
  end

  circfill(p.x,p.y,z,p.col)
 end
end
