pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

move=0
movevel=0
moveadd=0.0025

function _update60()
end

function _draw()
 cls()

 movevel+=moveadd
 move+=movevel
 
 if abs(movevel)>0.3 then
  moveadd*=-1
 end

	for z=32,1,-1 do
	 for x=-32,32 do
	  y=cos(x/16+z/32+move/2)*50-80-move*50   
	  sx,r,c=64+x*64/z,8/z,circfill
	  c(sx,64+y/z,r,12+(x+z*2)%4)
	  c(sx,64+-y/z,r,1)
	 end
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000