pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- pico-8 tunes vol. 1
--  by @gruber_music / @krajzeg

vtop=20

------------------------------
-- utilities
------------------------------

function round(x)
 return flr(x+0.5)
end

function ceil(x)
 return -flr(-x)
end

function lerp(a,b,t)
 return b+(a-b)*(1-t)
end

function lerpp(ob,prop,tgt,t)
 ob[prop]=
  tgt+(ob[prop]-tgt)*(1-t)
 if abs(ob[prop]-tgt)<0.1 then
  ob[prop]=tgt
 end
end

soff={{x=1,y=0},{x=-1,y=0},{x=-1,y=1},{x=0,y=1},{x=1,y=1},{x=0,y=-1}}
function prints(txt,x,y,clr,align)
 sh,align=sh or 0,align or 0
 x-=#txt*4*align
 for o in all(soff) do
  print(txt,x+o.x,y+o.y,0)
 end
 print(txt,x,y,clr)
end

-- copies props to obj
-- if obj is nil, a new
-- object will be created,
-- so set(nil,{...}) copies
-- the object
function set(obj,props)
 obj=obj or {}
 for k,v in pairs(props) do
  obj[k]=v
 end
 return obj
end

function g_add(tab,ind,e)
 tab[ind]=tab[ind] or {}
 add(tab[ind],e)
end

------------------------------
-- class system
------------------------------

-- creates a "class" object
-- with support for basic
-- inheritance/initialization

object={}
 function object:extend(kob)
  kob=kob or {}
  kob.extends=self
  setmetatable(kob,{__index=self})
  kob.new=function(self,ob)
   ob=set(ob,{kind=kob})
   setmetatable(ob,{__index=kob})
   local ko,create_fn=kob
   while ko~=object do
    if ko.create~=create_fn then
     create_fn=ko.create
     create_fn(ob)
    end
    ko=ko.extends
   end
   return ob
  end 
  return kob
 end

-------------------------------
-- vectors & 3d
-------------------------------

vec={}
 function vec.__add(v1,v2)
  return v(v1.x+v2.x,v1.y+v2.y,v1.z+v2.z)
 end
 function vec.__sub(v1,v2)
  return v(v1.x-v2.x,v1.y-v2.y,v1.z-v2.z)
 end
 function vec.__mul(v1,a)
  return v(v1.x*a,v1.y*a,v1.z*a)
 end
 function vec:copy()
  local cpy=set({},self)
  setmetatable(cpy,vec)
  return cpy
 end
 function vec:str()
  return self.x..","..
   self.y..","..
   self.z
 end
vec.__index=vec
function vec:project(cx,cy)
 local dv=1+self.z/49
 return v(cx+self.x/dv,cy+self.y/dv,self.z)
end

function v(x,y,z)
 local nv={x=x,y=y,z=z}
 setmetatable(nv,vec)
 return nv
end

-------------------------------
-- polygons
-------------------------------

dummy_hole={yt=16000}

function fl_color(c)
 return function(x1,x2,y)
  rectfill(x1,y,x2,y,c)
 end
end
function fl_odd(c)
 return function(x1,x2,y)
  if band(y,1)==1 then
   rectfill(x1,y,x2,y,c)
  end
 end
end

function project(pts,cx,cy,...)
 for i,p in pairs(pts) do
  pts[i]=p:project(cx,cy)
 end
 return pts
end

function holed_ngon(pts,ln,hole)
 local xls,xrs,npts={},{},#pts
 for i=1,npts do
  ngon_edge(
   pts[i],pts[i%npts+1],
   xls,xrs
  )
 end
 --
 hole=hole or dummy_hole
 local htop,hbot,hl,hr=
  hole.yt,hole.yb,
  hole.xl,hole.xr
 for y,xl in pairs(xls) do
  local xr=xrs[y]
  if y<htop or y>hbot then
   ln(xl,xr,y)
  else
   local cl,cr=
    min(hl,xr),max(hr,xl)
   if xl<=cl then
    ln(xl,cl,y)
   end
   if cr<=xr then
    ln(cr,xr,y)
   end
  end
 end
end

function ngon_edge(a,b,xls,xrs)
 local ax,ay=a.x,round(a.y)
 local bx,by=b.x,round(b.y)
 if (ay==by) return

 local x,dx,stp=
  ax,(bx-ax)/abs(by-ay),1
 if by<ay then
  --switch direction and tables
  xrs,stp=xls,-1 
 end
 for y=ay,by,stp do
  xrs[y]=x
  x+=dx
 end
end

-------------------------------
-- bg draws
-------------------------------
   
function blank(clr)
 return function()
  rectfill(0,0,127,63,clr)
 end
end

function mapwrap(mx,my,w,h,vx,vy,wx,wy,tx,ty)
 vx=vx or 0
 vy=vy or 0
 tx=tx or 0
 ty=ty or 0
 local wp,hp=w*8,h*8
 local wd,hd=
  wx and 0 or wp,
  wy and 0 or hp
 
 return function(t)
  local dx,dy=
   tx+vx*t%wp,ty+vy*t%hp
  for x=dx-wd,dx+wd,wp do
   for y=dy-hd,dy+hd,hp do
    map(mx,my,x,y,w,h)
   end
  end
 end
end

-------------------------------
-- 0. title
-------------------------------

titletext={
 {"music by          ",15},
 {"     @gruber_music",7},
 {"with stuff by     ",15},
 {"          @krajzeg",7},
 {"",0},
 {"",0},
 {"⬅️➡️ prev/next  ❎ pause/play   ",12},
}
function title(cmul)
 return function(t)  
  for y=1,#titletext do
   local text,clr=
    unpack(titletext[y])
   prints(text,64,5+y*7,clr*cmul,0.5)
  end
 end
end

-------------------------------
-- 1. mario
-------------------------------

plgrass=v(0,2,0)

platform=object:extend()
 function platform:move()
  self.x-=2
 end
 
 function platform:dead()
  local plin=v(0,0,self.d*10)
  local rx=self.x-64+self.w*8
  local br=v(rx,0,self.d*10):project(64,32)
  return br.x<-2
 end
 
 function platform:draw_sides()
 local w,h=self.w,self.h
  local x,y=self.x,64-h*8  
  -- polygons
  local nx,ny=x-64,y-32
  local fl,fr=
   v(nx,ny,0),v(nx+w*8-1,ny,0)
  local plin=v(0,0,self.d*10)
  local bl,br=
   fl+plin,fr+plin
  if fr.x<0 then
	  local grf,grb=
	   fr+plgrass,br+plgrass
	  local side=project({grf,grb,grb,grf},64,32)
	  side[3].y=64
	  side[4].y=64
	  holed_ngon(side,fl_color(1))
	  holed_ngon(
	   project({fr,br,grb,grf},64,32),
	   fl_color(3)
   )	    
  end
  if fl.x>0 then
	  local grf,grb=
	   fl+plgrass,bl+plgrass
	  local side=project({grb,grf,grf,grb},64,32)
	  side[3].y=64
	  side[4].y=64
	  holed_ngon(side,fl_color(1))	   
	  holed_ngon(
	   project({bl,fl,grf,grb},64,32),
	   fl_color(3)
   )	    
  end
 end
 
 function platform:draw_fronts()
  local w,h=self.w,self.h
  local x,y=self.x,64-h*8  
  -- polygons
  local nx,ny=x-64,y-32
  local fl,fr=
   v(nx,ny,0),v(nx+w*8-1,ny,0)
  local plin=v(0,0,self.d*10)
  local bl,br=
   fl+plin,fr+plin
  local pts=project({fl,bl,br,fr},64,32)
  holed_ngon(
			pts,
   fl_color(11)
  )
  -- grass
  local prfl,prbl,prbr,prfr=
   unpack(pts)
  
  local grcnt=
   max(ceil((prfl.y-prbr.y)/3)+1,2)
  local stp=-1/(grcnt-1)
  for t=1,0,stp do
   local pl,pr=
    lerp(prfl,prbl,t),
    lerp(prfr,prbr,t)
   self:grass(pl,pr,1-t*0.2)
  end
  -- tiles
  local r=rnd()
  srand(self.seed)  
  for dx=0,w-1 do
   spr(4+rnd(2),x+dx*8,y)
   for dy=1,flr(h) do
    spr(20+rnd(4),x+dx*8,y+dy*8)
   end
  end
  srand(r)
 end
 
	function platform:grass(p1,p2,scl)
	 local sx=flr(32*scl)
	 local h=8*scl
	 local y=ceil(p1.y-h)
	 for x=p1.x,p2.x,sx do
	  local w=min((p2.x-x)/sx,1)
	  sspr(32,24,32*w,8,x,y,sx*w,h)
	 end
	end
 
jumper_frms={37,38,39,38}
jumper=object:extend()
 function jumper:update() 
  local nxt=self.seq[1]
  if (not nxt) return

  local tgty=64-nxt.h*8
  if self.air then
   self.y+=self.vy
   self.vy+=0.3
   if 40>=nxt.x and self.y>=tgty then
    self.y=tgty
    self.air=false
    del(self.seq,nxt)
   end
  else
   if nxt.x<=80 then
    self.air=true
    self.vy=-sqrt(
     21+self.y-tgty)*0.7
   end
  end 
 end
 function jumper:render(t)
  local frm
  if self.air then
   frm=36
  else
   frm=jumper_frms[flr(t*0.2%4)+1]
  end
  local p=v(-16,self.y-32,7):project(64,32)
  spr(frm,p.x-4,p.y-8)
 end

function platforms()
 local ps={}
 local last=platform:new({
  x=16,w=18,h=2.5,d=2,seed=323
 })
 local seq={}
 ps[rnd()]=last
 
 local jmp=jumper:new({seq=seq,y=44})
 
 return function(t)
  -- draw/update all
  for k,p in pairs(ps) do
   p:draw_sides()
  end
  for k,p in pairs(ps) do
   p:draw_fronts()
   p:move()
   if (p:dead()) ps[k]=nil
  end
  jmp:update()
  jmp:render(t)
  -- generate new platforms
  if last.x+last.w*8<160 then
   last=platform:new({
    x=176+rnd(16),
    w=flr(rnd(12))+4,
    h=mid(last.h+rnd(3)-1.5,0.5,3.5),
    d=1.8+rnd(0.4),seed=rnd()
   })
   ps[rnd()]=last
   add(seq,last)
  end
 end
end

-------------------------------
-- 2. pastoral
-------------------------------

function waterfront()
 rectfill(0,0,128,3,12)
 palt(14,false)
 map(64,0,0,3,16,8)
end

function wave(ys,h)
 local saddr=0x6000+(vtop+ys)*64
 local rf={}
 rf[0]=0
 for y=1,h-1 do
  rf[y]=rf[y-1]+rnd(0.6)-0.3
 end
 return function(t,dx)
  memcpy(0x1800,saddr,0x800)
  if btnp(4) then cstore() end
  for y=0,h-1 do
   local xs,xe=sin(t*0.01+rf[y])*2*y/h
   for i=1,4 do
    xe=i*32+
     sin(t*0.01+rf[y])*2*y/h
    palt(3,false)
    sspr((i-1)*32-dx,96+y,32,1,
     xs,ys+y,xe-xs,1)
    xs=xe
   end
  end
 end
end

function watersurf()
 local ds={}
 local cs={1,1,5,5,13,6,7}
 for i=0,127 do
  add(ds,{x=i,o=rnd()})
 end
 return function(t)
--  rectfill(0,34,127,34,13)
  for d in all(ds) do
   local s=sin(t*0.01+d.o)
   local c=cs[flr(4.5+s*3.49)]
   pset(d.x,35,c)
  end
 end
end

function fisherman()
 local l,d=26,0
 return function()
  if rnd()<0.01 then
   local tl=rnd(30)+6
   d=tl-l
  end
  if d~=0 then
   l+=sgn(d)
   d-=sgn(d)
  end
  spr(42,64,9,2,3)
  rectfill(79,17,79,17+l,6)
 end
end

function fishes(n)
 local fs={}
 for i=1,n do
  add(fs,{
   x=i/n*128+rnd(10)-5,
   y=rnd(),
   vy=0,
   s=56+i%2,
   d=rnd()>0.5 and 1 or -1
  })
 end
 return function()
  for f in all(fs) do
   f.x+=f.d*(0.4+f.y*0.2)
   if (f.x<-8) f.x+=148
   if (f.x>140) f.x-=148
   f.y=mid(f.y+f.vy,0,1)
   f.vy+=rnd(0.002)-0.002*f.y
   spr(f.s,f.x,f.y*12+37,
    1,1,f.d==1)
  end
 end
end

-------------------------------
-- 3. sand
-------------------------------

function unpack(a)
 if (#a==1) return a[1]
 if (#a==2) return a[1],a[2]
 if (#a==3) return a[1],a[2],a[3]
 if (#a==4) return a[1],a[2],a[3],a[4]
 if (#a==5) return a[1],a[2],a[3],a[4],a[5]
 if (#a==6) return a[1],a[2],a[3],a[4],a[5],a[6]
end

function fix(fn,...)
 local args={...}
 return function()
  return fn(unpack(args))
 end
end

function terrain(spd,avgh,rng,v,clr,sprx)
 local h,sp,beg,en,dy={0.5},{0},0,1,0
 local frac=0
 return function()  
  palt(14,false)
  while en~=beg do
   local prv=h[en]

   dy+=(rnd()-dy^1-(prv-0.5)*0.03-0.5)*v
   en=band(en+1,0x7f)
   h[en]=prv+dy*0.5
   sp[en]=(dy>0.05 and 0 or dy<-0.05 and 4 or 2)+flr(rnd(2))
  end
  
  for x=0,127 do
   local hx=band(beg+x,0x7f)
   local ty=63-avgh-h[hx]*rng
   rectfill(x,63,
    x,ty,
    clr)
   sspr(sprx+sp[hx],0,1,8,
    x,ty)
  end

  frac+=spd
  if frac>=1 then
   local d=flr(frac)
   beg=band(beg+d,0x7f)
   frac-=d
  end
 end
end

-------------------------------
-- 4. space
-------------------------------

function stars(n)
 local cols={1,5,13}
 local ss={}
 for i=1,n do
  add(ss,{
   off=rnd(128),
   y=rnd(64),
   c=rnd(3)+1
  })
 end
 
 return function(t)
  for s in all(ss) do
   local x=(s.off+t*s.c)%128
   pset(x,s.y,cols[flr(s.c)])
  end
 end
end

-------------------------------
-- 5. ice
-------------------------------

function ice()
 local upcs={12,6,12}
 local dncs={1,1,1,1,1,1,1,1}
 return function()
  gradrect(0,0,128,32,upcs)
  gradrect(0,32,128,32,dncs)
 end
end

function gradrect(sx,sy,w,h,cs)
 local d,n=h-1,#cs
 local corr=0.0
 for y=0,d do
  local desired=1+y*(n-1)/d
	 local actual=flr(desired+corr+0.5)
	 corr+=desired-actual
  rectfill(sx,sy+y,sx+w-1,sy+y,cs[actual])
 end
end

function floe()
 local animals={
  {68,4,-14,1,2},
  {69,0,-6,2,1},
  {85,4,-6,1,1},
  {0,0,0,0,0}
 }
 local fs={}
 local newf=function(i)
  local tp=flr(rnd(2))
  return {x=rnd(128)+128,
   y=37+i*2.5,o=rnd(),
   a=rnd()<0.6 and 4 or flr(rnd(4))+1,
   sp=102+tp*16}
 end
 for i=1,7 do
  add(fs,newf(i))
  fs[i].x=fs[i].x*2-256
 end

 return function(t)
  for i=1,#fs do
   local f=fs[i]
   local d=(1+sin(t*0.01+f.o))*1.99
   palette(5+flr(d))
   spr(f.sp,f.x,f.y+d,2,1)
   reset_palette()
   local as,ax,ay,aw,ah=unpack(animals[f.a])
   spr(as,f.x+ax,f.y+ay+d,aw,ah)
   f.x-=f.y/128
   if f.x<-20 then
    fs[i]=newf(i)
   end
  end
 end
end

-------------------------------
-- 6. nostalgia
-------------------------------

function nostalgiabg()
 return function()
  gradrect(0,0,128,64,{13,12,12,12,13})
 end
end

function casette()
 local reels={
  {52,-4.5},{76,-4.5}
 }
 local spokes={
  {0.6,-2.6},{1.6,-2.6},
  {2.6,-1.6},{2.6,-0.6}
 }
 local tape={}
 for i=0,30 do
  add(tape,{
   a=rnd(),r=rnd(5)+7
  })
 end
 
 return function(t)
  local td=t*0.005
  local d=sin(td)*8
  local by=34+d
  
  local p=flr(t/10%4)+1
  
  rectfill(38,by-19,89,by+14,0)
  rectfill(37,by-18,90,by+13,0)
  map(66,10,40,by-16,6,4)
  
  for r in all(reels) do
   local rx,ry=unpack(r)
   ry+=by
   local sx,sy=unpack(spokes[p])
   pset(rx+sx,ry+sy,15)
   pset(rx+sy,ry-sx,15)
   pset(rx-sx,ry-sy,15)
   pset(rx-sy,ry+sx,15)
  end
  
  local rx,ry=unpack(reels[1])
  ry+=by
  for tp in all(tape) do
   local a,r=tp.a-t*0.005,tp.r
   local px,py=
    rx+cos(a)*r,ry+sin(a)*r
   if pget(px,py)==5 then
    pset(px,py,1)
   elseif pget(px,py)==1 then
    pset(px,py,0)
   end
  end
 end
end

function rpset(x,y,c)
 pset(flr(x),flr(y),c)
end

-------------------------------
-- 7. dungeon
-------------------------------

function pillar()
 return function(t)
  local td=t*0.016
  local d=(td*4)%8
  for y=1-d,41-d,8 do
   sspr(96+d,56,8,8, 58,y,3,8)
   sspr(96+d,56,10,8, 61,y+1,10,8)
   sspr(98+d,56,8,8, 71,y,2,8)
  end
 end
end

function stairs()
 local hole={xl=54,xr=77,
  yt=0,yb=63}
 return function(t)
  local td=t*0.001%0.0625
  local flp=band(t*0.001/0.0625,1)==1
  local ba=-td
  local bh=80-td*64
  local sp
  for i=1,15 do
   local h,a=
    bh-i*4,
    ba-i*0.0625
   local t,r=stair(h,a)
   local bck=t[1].z>30
   holed_ngon(t,fl_color(1),
    bck and hole or nil)
   line(t[3].x,round(t[3].y),
    t[4].x,round(t[4].y),0)
   if r[1].x<55 then    
    line(r[1].x,round(r[1].y),
     r[4].x,round(r[4].y),1)
   end
   if i==10 then
    sp=(t[1]+t[3])*0.5
   end
  end
  spr(76,sp.x-7,sp.y-21,2,3,flp)  
 end
end

function stair(h,a)
 local pts,ap={},a+0.0625
 local b,d1,d2=
  v(0,h,30),
  v(sin(a),0,cos(a)),
  v(sin(ap),0,cos(ap))
 local hc=v(0,4,0)
 local ln,lf,rf,rn=
  b+d1*50,b+d1*15,
  b+d2*15,b+d2*50  
 local bn,bf=rn+hc,rf+hc
 return 
  project({ln,lf,rf,rn},64,0),
  project({rn,rf,bf,bn},64,0)
end

-------------------------------
-- 8. boss
-------------------------------

function bossbg(n,plt,bgc,lmt,bias)
 if (not bias) bias=0.1
 return function(t,dx)
  if t<15 then
   rectfill(0,0,127,63,bgc)
  else
   rectfill(0,62,63,63,bgc)
   rectfill(64,0,127,1,bgc)
	  for i=0,n do
	   local x,y=rnd(128)-64,rnd(64)-32
	   local d=x*x+y*y
	   x+=64
	   y+=32
	   local c,r=pget(x,y),rnd()
	   if r>0.97 or d<lmt then
	    c=bgc
	   elseif r<d/12000-bias then
	    c=sget(plt,c)
	   end
	   local dx,dy=
	    -(y-32)*0.05,(x-64)*0.05
	   circ(x+dx,y+dy,1,c)
	  end
	 end
 end
end

function bossmon()
 local stks={
  {12,0,0,3,2},
  {-12,0,0.5,3,2},
  {5,8,0.875,2,2},
  {-5,8,0.625,2,2},
  {6,-10,0.15,2,2},
  {-6,-10,0.35,2,2},
  
  {8,-8,0.06,4,8},
  {-8,-8,0.44,4,8},
  {12,2,0.9,4,8},
  {-12,2,0.6,4,8},
  
  {4,-10,0.18,1.5,8,true},
  {-4,-10,0.32,1.5,8,true},
  {0,-11,0.25,1.5,8,true},
 }
 local blink,blc=0,0
 return function(t)
  local td=t*0.005
  local by=36+sin(td)*10
  -- body
  circfill(64,by,13,0)
  spr(128,52,by-12,3,3)
  -- blinking
  if (rnd()<blc) then
   blink,blc=0,0
  else
   blink+=0.6
   blc+=0.0001
  end
  -- stalks/tentacles
  local i=0
  for stk in all(stks) do
   local dx,dy,a,l,c,eye=
    unpack(stk)
   local fx,fy=stalk(t,64+dx,by+dy,
    a,l,c,i*0.23)
   i+=1
   if eye then
    palt(14,false)
    palt(3,true)
    spr(176,fx-4,fy-4)
    local td=t*0.01
    local lid=mid(0,4,6-abs(blink-6))
    if lid>0 then
     local rx,ry=fx-2,fy-2
     rectfill(rx,ry,rx+3,ry+lid-1,8)
    end
   end
  end
 end
end

function stalk(t,sx,sy,a,l,c,off)
 local w=1
 local pts={}
 for i=0,5 do
  a+=sin(t*0.01+i*0.1827+off)*0.08
  local al,ar=a+0.25,a-0.25
  add(pts,v(sx+cos(al)*w,sy+sin(al)*w))
  add(pts,v(sx+cos(ar)*w,sy+sin(ar)*w))
  sx+=cos(a)*l
  sy+=sin(a)*l
  w*=0.8  
 end
 quadstrip(pts,fl_color(c))
 return sx,sy
end

function quadstrip(pts,fl)
 for si=1,#pts-3,2 do
  holed_ngon({
   pts[si],pts[si+2],
   pts[si+3],pts[si+1]
  },fl)
 end
end


-------------------------------
-- 9. evil
-------------------------------

function evilsky(nstars)
 local ss={}
 for i=1,nstars do
  add(ss,{x=rnd(128),y=rnd(40)})
 end
 return function(t)
	 local moony=28+sin(t/1024)*10
	 
	 gradrect(0,0,128,40,{1,2})
	 for s in all(ss) do
	  pset(s.x,s.y,13)
	 end
	 circfill(64,moony,17,8)
	 circfill(64,moony-1,16,14)
	 circfill(64,moony-2,14,7)
	 rectfill(0,40,127,63,0)
	end
end

function reflect(sy,rh,basey,scale,squeeze,amp,plt)
 local saddr=0x6000+0x40*(vtop+sy)
 --random factors
 local rf,rm={},{}
 for y=0,rh-1 do
  rf[y],rm[y]=
   rnd(),rnd(0.4)+0.8
 end
 
 return function(t)
  palt(14,false)
  memcpy(0x1800,saddr,0x800)
  if (btnp(5)) cstore()
  local ascl=scale
  local segs={}
  palette(plt)
  for y=0,rh-1 do
   local srcy=flr(127-y*1.2)
   local scl=y%2==0 
    and ascl or ascl*0.75
   for i=0,4 do
    segs[i]=(i/2-1)*scl+
     sin(t*rm[y]*0.02+rf[y]*i)*scl*amp
   end
   for i=0,3 do
    local xl,xr=
     64+segs[i],64+segs[i+1]
    sspr(
     16+24*i,srcy,24,1,
    xl,basey+y,xr-xl+1,1)
   end
   ascl*=squeeze
  end
 end
end

-------------------------------
-- 10. travel
-------------------------------

function plane(t)
 local y,r=32+sin(t*0.003)*12
 spr(140,80,y-8,2,2)
 line(79,y,79,y+sin(t*0.6)*3,7)
end

-------------------------------
-- 11. puzzle
-------------------------------

function questions(n,m)
 local qs={}
 for i=0,n-1 do
  add(qs,{
   cm=(rnd()+1)*0.001,
   sm=(rnd()+1)*0.001,
   co=rnd(),so=rnd(),
   dx=rnd(80)-40,
   dy=rnd(20)-10,
   p=3-flr(i*4/n)
  })
 end
 return function(t)
  for q in all(qs) do
   local x,y=
    cos(q.cm*t+q.co)*40+q.dx,
    sin(q.sm*t+q.so)*40+q.dy
   local scale=16*
    (0.8+sin(t*0.006+q.co)*0.4)
   palette(q.p)
   sspr(112,64,16,16,
    64+x-scale*0.5,
    32+y-scale*0.5,
    scale,scale)
  end
  reset_palette()
 end
end

-------------------------------
-- 12. village
-------------------------------

function hills()
 local hs={}
 for i=1,20 do
  local h=hill:new()
  sorted_insert(hs,h,hill.order)
  h.x=(h.x-128)*2
 end
 for i=1,100 do
  local c=cloud:new()
  sorted_insert(hs,c,hill.order)
  c.x=(c.x-128)*2
 end
 return function(t,dx)
	 gradrect(0,40,128,24,{6,7})
	 for h in all(hs) do
	  h:update()
	  h:render(dx)
	 end
	 for _,h in pairs(hs) do
	  if h:done() then
	   del(hs,h)
	   local rep=h.kind==hill
	    and hill:new()
	    or cloud:new()
	   sorted_insert(hs,rep,hill.order) 	  
	  end
	 end
 end
end

function sorted_insert(a,e,fn)
 local i,n=1,#a
 local key=fn(e)
 while i<=n and fn(a[i])<key do
  i+=1
 end
 for j=n,i,-1 do
  a[j+1]=a[j]
 end
 a[i]=e
end


hill=object:extend()
 function hill:create()
  self.y=rnd(18)
  self.r=rnd(10)+15
  self.x=128+self.r+rnd(127)
  self.z=self.r*(rnd(0.3)+0.1)
  self.vx=0.25+self.y/17*0.25
  if rnd()<0.3 then
   self.h={
    a=rnd(0.15)+0.2,
    d=rnd(0.2)+0.7,
    s=28+flr(rnd(4))
   }  
  end
 end
 function hill:update()
  self.x-=self.vx
 end
 function hill:done()
  return self.x<-self.r
 end
 function hill:render(dx)
  local x,y,z,r=
   round(self.x),46+self.y,self.z,
   self.r
  clip(-dx,0,128,vtop+y)
  circfill(x,y+z,r,11)
  circfill(x+4,y+z-2,r-4,3)
  if self.h then
   local a,d=self.h.a,
    self.h.d*self.r
   local hx,hy=round(cos(a)*d),sin(a)*d
   spr(self.h.s,x+hx-4,y+z+hy-14,1,2)
  end
 end
 function hill:order()
  return self.y
 end

cloud=object:extend()
 function cloud:create()
  self.y=rnd(24)
  self.x=136+rnd(127)
  self.s=172+flr(rnd(2))*16
  self.vx=0.33+self.y/17*0.33
 end
 function cloud:update()
  self.x-=self.vx
 end
 function cloud:done()
  return self.x<-24
 end
 function cloud:render(dx)
  clip(-dx,vtop,128,64)
  spr(self.s,self.x,38+self.y,
   3,1)
 end

-------------------------------
-- the pieces
-------------------------------

setlist={
 {
  at=0,title="demented mario",clr=3,
  draws={
   blank(12),
   terrain(0.5,34,10,0.2,13,54),
   platforms()
  }    
 },{
  at=6,title="pastoral",clr=4,
  draws={   
   waterfront,
   mapwrap(96,18,16,1,-1/4,0,false,true),
   mapwrap(96,19,16,1,-1/8,0,false,true,0,8),
   fisherman(),
   watersurf(),
   fishes(6),
   wave(35,24)
  }
 },{
  at=14,title="sand",clr=9,
  draws={
   blank(12),
   fix(spr,15,108,8),
   terrain(1,34,12,0.3,13,114),
   terrain(2,29,10,0.08,9,108),--spd,avgh,rng,v,clr)
   terrain(4,24,8,0.2,10,102),
   terrain(6,9,6,0.1,15,96)
  }
 },{  
  at=18,title="space",
  draws={
   blank(0),
   stars(50),
   mapwrap(0,8,16,8)
  }
 },{
  at=24,title="ice",clr=13,
  draws={
   ice(),
   mapwrap(32,8,16,1,-1/32,0,false,true,0,25),
   reflect(0,8,34,64,0.84,0.1,9),
   floe()
  }
 },{
  at=30,title="nostalgia",clr=12,
  draws={
   nostalgiabg(),
   casette()
  }
 },{
  at=36,title="dungeon",clr=1,
  draws={
   blank(0),
   pillar(),
   stairs()
  }
 },{
  at=42,title="boss",clr=8,
  draws={
   bossbg(400,10,0,1000),
   bossmon()
  }
 },{
  at=46,title="evil",
  clr=2,
  draws={
   blank(0),
   evilsky(0),
   mapwrap(32,16,16,3,-1/8,0,
    false,true,0,16),
   reflect(8,23,41,60,0.91,0.15,0),
  }
 },{
  at=48,title="travel",
  clr=13,
  draws={
   mapwrap(64,16,32,8,0.5,0),
   plane,
   mapwrap(96,16,16,8,1,0)
  }
 },{
  at=55,title="puzzle",
  clr=2,
  draws={
   blank(2),
   questions(100),
  }
 },{
  at=59,title="village",clr=7,
  draws={
   blank(12),
   hills()
  }
 }
}

setlist[0]={
 draws={ 
  title(0), 
  bossbg(400,12,0,50,0.04),
  title(1)
 }
}

------------------------------
-- entity system
------------------------------

-- entity root type
entity=object:extend({
 t=0,state="s_default"
})

-- entities with some special
-- props are tracked separately
tracked_props={"render"}

-- used to add/remove objects
-- in the entities_with list
function update_with_table(e,fn)
 for prop in all(tracked_props) do
  if (e[prop]) fn(entities_with,prop,e)   
 end
end
function g_del(l,prop,e)
 del(l[prop],e)
end

-- all entities do common
-- stuff when created -
-- mostly register in lists
function entity:create()
 e_id+=1
 entities[e_id..""]=self 
 update_with_table(self,g_add)
end

function entity:become(state)
 self.state,self.t=state,0
end

-- this is the core of our
-- _update() method - update
-- each entity in turn
function update_entities()
 for n,e in pairs(entities) do
  local update_fn=e[e.state]  
  if update_fn and update_fn(e,e.t) then
   -- remove entity
   entities[n]=nil
   update_with_table(e,g_del)
  else
   -- bump timer
   e.t+=1
  end
 end
end

------------------------------
-- entity rendering
------------------------------

-- renders entities, sorted by
-- z to get proper occlusion
function render_entities()
 local zsorted={}
 for e in all(entities_with.render) do
  g_add(zsorted,
   e.z and flr(e.z) or 20,
   e)  
 end

 for z=0,20 do  
  for e in all(zsorted[z]) do   
   e:render(e.t)  
   reset_drawstate()
  end
 end
end

function reset_drawstate()
 camera()
 palt(0,false)
 palt(14,true)
end

-------------------------------
-- album text
-------------------------------

textdisp=entity:extend({
 fac=2
})
 function textdisp:create()
  self.x=self.no*256+128
  self.trk=setlist[self.no]
  self.txt=
   "#"..self.no.." - "..self.trk.title
 end
 
 function textdisp:render()
  if (not cm:sees(self)) return
  cm:apply(self)
  
  local pre="#"..self.no..". "
  local tit=self.trk.title
  local dx=(#(pre..tit))*2
  
  rectfill(10,79,118,82,self.trk.clr or 1)
  prints(pre,64-dx,76,15,0.0)
  prints(tit,64+dx,76,7,1.0)
 end

-------------------------------
-- palette
-------------------------------

function palette(no)
 for i=0,15 do
  pal(i,sget(no,i))
 end
end
function reset_palette()
 pal()
 palt(0,false)
 palt(14,true)
end

-------------------------------
-- logo
-------------------------------

logo=entity:extend({
 z=10
})
 function logo:render()
  spr(32,43,vtop-15,4,2)
  spr(2,75,vtop-15,2,2)
 end

-------------------------------
-- album pics
-------------------------------

pic=entity:extend({
 fac=1,z=1,
})
 function pic:create()
  local trk=setlist[self.no]
  self.draws=trk.draws
  self.x=self.no*128+64
 end
 
 function pic:render(t)
  if not cm:sees(self) then
   self.t=0
   return
  end
  local dx=cm:apply(self)
  for d in all(self.draws) do
   clip(self.x-round(cm.x),vtop,128,64)
   reset_palette()
   d(t,dx)
  end
  clip()
 end

-------------------------------
-- hud
-------------------------------

hud=entity:extend({
 fac=0,x=0,z=2,
})
 function hud:render()
  cm:apply(self)
  rectfill(0,-2,127,-2,1)
  rectfill(0,65,127,65,1)  
 end

instr=entity:extend({
 z=2
})
instructions=
"⬅️➡️ prev/next     ❎ pause/play"
 function instr:render()
  print(instructions,0,120,1)
 end
-------------------------------
-- camera
-------------------------------

cam=entity:extend({x=64})
 function cam:s_default()
  local tgt=ply.no*128+64
  lerpp(self,"x",tgt,0.1)
 end
 
 function cam:sees(e)
  local dist=abs(e.x-self.x*e.fac)
  return abs(dist)<128
 end
 
 function cam:apply(e)
  local dx,dy=
   round(self.x*e.fac-e.x),-vtop
  camera(dx,dy)
  return dx,dy
 end
 
-------------------------------
-- player - music manager
-------------------------------

switch_delay=30

player=entity:extend()
 function player:create()
  self:switch(0)
 end
 
 function player:s_play()
  self:do_controls()
 end
 
 function player:s_pause()
  self:do_controls()
 end
 
 function player:s_switch(t)
  if t==switch_delay then
   self:play()
  end
  self:do_controls()
 end
 
 function player:do_controls()
  local swd=nil
  -- forward/back
  if (btnp(1)) swd=1
  if (btnp(0)) then
   swd=self.t<switch_delay
    and -1 or 0
  end
  if swd then
   self:switch(swd)
  end
  -- play/stop
  if btnp(4) or btnp(5) then
   if self.state=="s_play" then
    self:pause()
   else
    self:play()
   end
  end
 end
 
 function player:play()
  if self.trk.at then
   music(self.trk.at)
   self:become("s_play")
  end
 end
 
 function player:pause()
  music(-1,100)
  self:become("s_pause")
 end
 
 function player:switch(d)
  self:pause()
  self.no=
   (self.no+d)%(#setlist+1)
  self.trk=setlist[self.no]
  self:become("s_switch")
 end
 
-------------------------------
-- cover
-------------------------------

function cover()
 local bg=
  coverbg(700,12,0,1500,0.1)
 return function(t)
  bg(t)
  reset_drawstate()  
  rectfill(15,38,100,72,0)
  sspr(0,16,32,16,19,42,64,32)
  sspr(16,0,16,16,83,42,32,32)
 end
end
 
function coverbg(n,plt,bgc,lmt,bias)
 if (not bias) bias=0.1
 return function(t,dx)
  for i=0,n do
   local x,y=rnd(128)-64,rnd(128)-64
   local d=x*x+y*y
   x+=64
   y+=64
   local c,r=pget(x,y),rnd()
   if r>0.97 or d<lmt then
    c=bgc
   elseif r<d/20000-bias then
    c=sget(plt,c)
   end
   local dx,dy=
    -(y-64)*0.05,(x-64)*0.05
   if c~=6 then
    circ(x+dx,y+dy,1,c)
   end
  end
 end
end


--[[
cov=cover()
t=0
function _draw()
 cov(t)
 t+=1
end]]

-------------------------------
-- main loop
-------------------------------

entities,entities_with,e_id=
 {},{},1

function _init() 
 cls()
 
 ply=player:new({no=0})
 cm=cam:new()
 
 hud:new()
 logo:new()
 
 for no=0,#setlist do
  if not setlist[no].draws then
   setlist[no].draws={blank(no)}
  end
  if setlist[no].title then
   textdisp:new({no=no})
  end
  pic:new({no=no})
 end
end

function _update60()
 update_entities()
end

function _draw()
 local saddr=0x6000+88*0x40
 local len=40*0x40
 
 memset(saddr,0,len)
 
 reset_drawstate()
 render_entities()
end

__gfx__
00000000001c100077794eeeeeeeeeeebb3b3bb33b3bb3b3dddddddddddd000011111111113013011111111142444424777fff777aaaaaa999cccccccccccccc
10000111112c211177ff9eeeeeeeeeee35335353353353536666d6ddcddd0000111111111330330111111301ee4ee4ee77fee477aa99999999ddddddcc6aa6cc
20000661dd4c82229ee79eeeeeeeeeee1351351513513515666d66ccdddd0000111111113350330101111130e999e99ef7ffeeaaaa99999999ccddddc677776c
300003333d0c03339eef9eeeeeeeeeee2114112121141121666666ccddcd0000111111113501133010130330f9ffff9f7ffffe7aaa9a999999ddddddca7777ac
400004444d8c044477ff9eeeeeeeeeee4220220024220421666666dddccc0000111111113500135001330350ffffffffffffefaaaaaa999999ddddddca7777ac
500005555d0c2555fff99eeeeeeeeeee4220000420000421666666dddddc0000111111113501035003301350fffffffff7ffffaaaaaa999999ddddddc677776c
600006661d0c06669eef9eeeeeeeeeee0440220220220420666666dddddd0000111111113301335003501350fef9ffeffffffeaaaaaa999999ddddddcc6aa6cc
7fe827777d0ca7779eef9eeeeeeeeeee0220110000110220666666dddddd0000111111111330350103501350ffffffff7fffffaaaaaa999999ddddddcccccccc
80000771dd8c949477ff9eeeeeeeeeee1022200000212100011110000011110010000001c242220ccccccccccccccccceee2eeeeeeeeeeeeeee94eeeeeeeeeee
900009999d0ca9a9fff94eeeeeeeeeee0001102220212102201102222001000210010001c244420cccccccccccccccccee922eeeeeeeeeeeee94250eeeeeeeee
a0000d111d0c7a7f22221eeeee00eeee0222102220211002200002222000020210000001c249940cccccccccccccccccee922eeee94eeeeee944250eeeeeeeee
b00001d11d0c0bbbeeee000ee090eeee0222001110211001122200111022010110000001c29f440ccccccccc44444424e94422ee9424eeee94479224eeeeeeee
c000071d1d0d0ccc0000090e0990eeee0111002110110002121101211011010110100001c29f940cccccccccfffffff2e77aa4ee4422eeee4477a922eeeeeeee
d000061d1d0d0ddd909909000090eeee0210101110000101100000211010000110000001c29f940ccccccccc00000000e7d7a4ee4772eeee4777aa92eeeeeeee
e0000eeeed8c0eee009909090090eeee1000000100000000102220011022010110010001c29f940ccccccccc4999e940eadca4ee7aa9e50e79999994eeeee50e
f0000ffffd0cafffe00000000000eeee0022200010222200002220000222200010000001c29f440ccccccccc00000000ea7aa4eeadd94504ad7d7d74ee99210e
ee7779ee7777e477794e477794eeeee9ee887eeeee887eeeee887eeeee887eeecdddd55c10111001ee22eeeeeeeeeeee9ad7a44eadc92222adcdcdc4e999421e
ee7777eef779e777ff9e777ff9eeeee7ee8822eeee8822eeee8822eeee8822eecdddd55c10111001e2940eeeeeeeeeee9adc944e7779aaa4777aaa9422222221
ee7f22f92792e792222e792279eeeee7e0ff99eee0ff9eeee0ff9eeee0ff9eeecdddd55c10111001e2f4000eeeeeeeee9a7a944e7229ddd47dda2294a77777a4
ee7feef9e79ee79eeeee79ee79eeeeefe0f90eeee0f949eee0f949eee0f949eecddddd5c10111001e244940eeeeeeeee9a2294447229d7c47dca2294a227dda4
ee7f7722ef9eef9eeeeef9eef9eff9efee99d2feee990eeeee990eeeee990eeecdddd55c1011100129ff00eeeeeeeeee9a24944ea2499994adc92494a247dc94
ee7ff9eeef9eef9eeeeef9eef9eff9e9e8cddeeeee8ddeeee8cdd2eee8cdd29ecdddd55c101110012000f0eeeeeeeeee9a24944e9249111199992494a24a9994
ee7922eeef9eef9eeeeef9eef9e222e7fecdddeeeecfdeeeefcdd9eefecddeeecddddd5c10111001e288f0eeeee0000011111115111155551111111111111111
ee79eeeeef9eef9eeeeef9eef9eeeeefeceeeeeeeceeedeeeecedeeeeeecdeeecdddd55c10111001ee000eeee0044444e5555555e555555ee5555555ee55555e
ee79ee0000000ff77f9efffff9eeeeefeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2eeeeeeeeeeeee24440ee044eeeee00000000000000000000000000000000
eef9e097798804fff94e4fff94eeeee9eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2290ee2eeeeeeee244440004eeeeeee00000000000000000000000000000000
ee22090090000002001e1000210000e1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2a9a9029e00000e0244042f0eeeeeeee00000000000000000000000000000000
eeeee0e090700900790e0798007980eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee94a999980c5ccc0d24420000eeeeeeee00000000000000000000000000000000
eeeeeee080900909008092280900000eeee33eeeeee3eeee3e3eeeeeee3ee3ee8a9a9882dccccdd2242220eeeeeeeeee00000000000000000000000000000000
eeeeeee08080080800808000002800903ee3b33eeee333e3b3b3e3e3e3b3e3e3088880080dddd00de1000000eeeeeeee00000000000000000000000000000000
eeeeeee0800880080080088808880e093b3b33bee333b33bb3b3e33b33b33b3be0000ee0e0000ee0e15511110eeeeeee00000000000000000000000000000000
eeeeeee000e00e000000e0000000eee03b3b3b33e3b33b3bbbb33b3b33bb3b3beeeeeeeeeeeeeeeeee0000010eeeeeee00000000000000000000000000000000
00000000000000000000000000000000eeeeeeeeee0000eeeeeeeeee77777eee00000000cc55510ceeeeee1d0eeeeeeeeeeeeeeeeeeeeeee0000000000000000
00000000000000000000000000000000eeeeeeeee0dd510eeeeeeeee7777777e00000000cc57650ceeeeee2f00eeeeeeeeeeee0000eeeeee0000000000000000
00000000000011111111110000000000eee00eee70d70510eeeeeeee7766666500000000cc57650ceeee2f2ff0eeeeeeeeeee000000eeeee0000000000000000
00000000011100000000001100000000ee0000ee00d0055d00ee00ee6655555d0000000044565104eeee000000eeeeeeeeeee080080eeeee0000000000000000
0000000110000ddd5555100000000000e05050ee7ddd7d5ddd00d0ee55666ddd00000000ff000002eeeeeeeeeeeeeeeeeeeee000000eeeee0000000000000000
0000001000331c7c5b35311000000000099900ee0717dd0d055510ee77666eee0000000000000000eeeeeeeeeeeeeeeeeeeee000000eeeee0000000000000000
0000010033bfb1cc5335551100000000ee00000e70117d055000d0ee77eeeeee000000004999e940eeeeeeeeeeeeeeeeeeeee000000eeeee0000000000000000
00001003bbfffb1cc03b355100000000ee0aa00eee00000000ee00eeeeeeeeee0000000000000000eeeeeeeeeeeeeeeeeeeeee0000eeeeee0000000000000000
0001003bb77f7b51c033335500000000e0aaa900ee771eeeeeeeee6666eeeeee04ffff40333333306666666603333333eeeee000000eeeee0000000000000000
000103bbfffbbf51cc03353500000000e0777600e85710eeeeeee688886eeeee4fccccf4333333006666666600333333eeee00000000eeee0000000000000000
001003bfff7fb51ccc53b55100000000e0777600891100eeeeeee586682eeeeefccccccf3303330066666666003bb3b3eee0000000000eee0000000000000000
00103bb77bbb11c7cc53b35100000000e07776000077111eeeeeed8888deeeeefccccccf303033003636363600333333eee0000000000eee0000000000000000
01003bfffbfb1c77c533355100000000e0777600e0777110eeeeebccccbeeeeefccccccf3000330066666666003b3bb3eee0000000000eee0000000000000000
0103bf7f7bb331ccc53bb53500000000ee077000ee066000eeeeeabbebaeeeeefccccccf303033006666666600333333eee0000000000eee0000000000000000
0103bfffbbbbb51cc533355100000000ee00000eeee000eeeeeeeeaeaaeeeeee4fccccf4333333003333333300333333eee0000000000eee0000000000000000
0103fbf7bffb311cc53bb35100000000e0000000ee08090eeeeeeeeeeeeeeeee04ffff40333333300000000003333333eeeee00000000eee0000000000000000
0103bff7bbb3b1cccd03b55500000000eeeeeeeeeeeeeeeeeee7777777777eee00000000000000000000000033333333eeeee00000000eee0000000000000000
0103f7ffb335331cdd03353500000000eeeeeeeeeeeeeeeee77777777777777e00000000000000000000000066666666eeeee00ee00eeeee0000000000000000
0103bffb355c351cd53b335100000000eeeeeeeeeeeeeeee677777777777777600555555555555555555510066666666eeeee00ee00eeeee0000000000000000
0103bfb3cccc51cdd533531100000000e77eeeeeeeeeeeee266676677766666200500000000000000000010066666666eeeee00ee00eeeee0000000000000000
01011b3c777cccdcd003550000000000776777ee77777eeec88862266622288d05000000000000000000001066666666eeeee00eeeeeeeee0000000000000000
0100d3c7777cccdcdd50005100000000776676777766667ebccc2dd888dddbbb05000c000000000000c00010ddddddddeeeee00eeeeeeeee0000000000000000
0010dcc7cccccdcddd555510000000007766767677676677abbcdbbcccbbbaaa500c0000000000000000c00100000000eeeee00eeeeeeeee0000000000000000
00100dccccccdcddd5551100000000006666666666666666eaabbaabbbaaaeee50000000000000000000000100000000eeeee00eeeeeeeee0000000000000000
00000000000000000000000000000000eeeeeeeeeeeeeeeeeee7777777777eee0015151cccccc100666666663333333311111100111111001111110000000000
00000000000000000000000000000000eeeeeeeeeeeeeeeee6777777777777ee00515151cccc1500666666666666666611000000110000001100000000000000
00000000000000000000000000000000eeeeeeeeeeeeeeeee67777777777776e00515151cccc1500666666666650506611000000110000001100000000000000
00000000000000000000000000000000eeeeeeeeeeee7777e86666666777662e00515151cccc1500363636366660506600000000000000000000000000000000
00000000000000000000000000000000eeee77776ee77667ec888222266622de00515151cccc1500666666666666666611001111110011111100111100000000
00000000000000000000000000000000ee77767666777667ebccddddd888cdbe00515151cccc150066666666dddddddd00001100000011000000110000000000
00000000000000000000000000000000e766767666777667eabbbbbbbcccbbae00515151cccc1500333333330000000000001100000011000000110000000000
000000000000000000000000000000006666666666666666eeaaaaaaabbbaaee0015151cccccc100333333330000000000000000000000000000000000000000
eeeeeeee22222222eeeeeeee00000000eeeeeeeeeeeeeeeeeeeeeeeeeeee0000ccccccccc7cc77c777cccccccccccccceeee0000eeeeeeeeeeeee777777eeeee
eeeeee228888888822eeeeee00000000eeeeeeeeeeeeeeeeeeeeeeeeeee00000cccccccc6cc7d5d55555d777ccccc76ceee0aa40eeeeeeeeeeee77777777eeee
eeeee28888888888882eeeee00000000eeee000eeeeeeeeeeeeeeeeeee000000ccccccccccd5f35fffff9555556ccccceee0aa40eeeeeeeeeee7777777777eee
eeee2888888288828882eeee00000000ee000000eeeeeeeeeeeeeeeee0000000ccccccccc5ff33333333399ff57765cceee09940eeeeeeeeeee7770000777eee
eee288828828888828882eee00000000000000000eeeeeeeeeee00ee00000000cccccccccdf33bbb333333333355590ceee0aa40eeee000eeee000eeee777eee
ee28882288888822288882ee0000000000000000000eeeeeeee0000000000000ccccccccc753bbbbb3333b33333ff907eee0aa40eeee090eeeeeeeeee7770eee
e2888888888888888888882e00000000000000000000eeeeee00000000000000ccccccccc7533bbbbbbbbbbbb333ff07e00099400000090eeeeeeeee7770eeee
e2882888222222228882882e0000000000000000000000eee000000000000000cccccccc7df33bbbbbbbbbbbbb333f070550aa404aa4040eeeeeeee7770eeeee
288288222222222222888882000000000eeeeeeeeeeeeeee00000000eeeeeeeebbbbbbbb75f333bbccccccccbb3339570510a9404944040eeeeeee7770eeeeee
28888222000000002228888200000000000eeeeeeeeeeeee00000000eeeeeeeebbbbbbbb759333bbccccc6ccbb33907c011094404400090eeeeeee777eeeeeee
288822001177177100228882000000000000eeeeee00eeee00000000eeeeeeeebbbbbbbb75933bbbcc76ccccbbb3f07ce000994000ee090eeeeeee000eeeeeee
2888201770770770770288820000000000000eeee0000eee00000000eeeeeeeebbbbbbbbcdf333bbccccccccbb33f07ceee09940eeee000eeeeeeeeeeeeeeeee
2888010770000000771088820000000000000eee00000ee0000000000000eee0bbbbbbbbcdf333bbccccc7ccbb333f5ceee00000eeeeeeeeeeeeee777eeeeeee
28880000700000007000888200000000000000ee000000000000000000000e00bbbbbbbbc75f33bbccccccccbb333f57eee02220eeeeeeeeeeeeee777eeeeeee
288800000022220000008882000000000000000e000000000000000000000000bbbbbbbbc75f33bbc7ccccccbb333f07eee04440eeeeeeeeeeeeee000eeeeeee
2288000002222220000088220000000000000000000000000000000000000000bbbbbbbb7df33bbbccccccccbb333f07eee00000eeeeeeeeeeeeeeeeeeeeeeee
e2888000000000000008882e00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccc75f3bbbbbbbbbbbbb333f0cceeeeeeeeeeeeeeeeeeeeeeee00000000
e2288800070707050088822e00000000eeee0eeeeeeeeeeeeeeeeeeee110eeeecc55cccc65ffbbbbbbbbbbbb333390cceeeee7777eeeee77eeeeeeee00000000
ee22888800000000888822ee00000000e0ee0ee0eeeeeeeee11100ee110000eec550ccccd54ffbbbbbb33333339990cceeee7777777ee6777766eeee00000000
eee228888888888888822eee00000000e0e000e0eeeeeeee11000110100000ee75007ccccd00f3333333333339000dccee777777777777667766eeee00000000
eeee2288882222888822eeee00000000e0000000eeeeeeee1000110000000110c777cccccd770ffff333399ff900dcccee777776777766ee766eeeee00000000
eeeee22288888888222eeeee00000000ee00000eeeeeeeee0000000000eee000ccccc50cccdd60000fff90000090dccceee6676676666eee6eeee77e00000000
eeeeee222222222222eeeeee00000000ee0a0a0e1eeeeeeee000e00eeeeeeeeeccc75507cccdddddd0055dddd000dccceeeee666eeeeeeeeeeee777600000000
eeeeeeee22222222eeeeeeee00000000ee0000011e0e0e0eeeeeeeeeeeeeeeeecccc777cccccccccddddddcccdddcccceeeeeeeeeeeeeeeeeeeee66e00000000
33000033000000000000000000000000ee0000011e00000eeeeeeeeeeeeeeeeebbbbbbbbbbbbbbbbbb33ff0775f3bbbbeeeeeeeeeeeeeeeeeee777ee00000000
30888803000000000000000000000000ee0000011ee000eeee1110eeeeeeeeeebbb33bbbbbbbbbbbbb33f90c5f33bbbbe777ee777eeeeeeeee77776e00000000
08e77e80000000000000000000000000ee0000011ee0a011e111100ee110eeeebb33333bbbbbbbbbbb33f0d5f33bbbbb77777777776ee7777777766e00000000
08700780000000000000000000000000ee000000000000111100000011100110b33333333bbbbbbbbb33f059333bbbbb77767777666e7777667666ee00000000
08700780000000000000000000000000ee000000000000010000110000000000b33333ff33bbbbbbbbb3ffff33bbbbbb666677666667777666666eee00000000
02e77e20000000000000000000000000e000000000000001e0000000ee00000ebb333ff993bbbbbbbbb33ff3bbbbbbbbe6677666eee77766eeeeeeee00000000
30222203000000000000000000000000e000000000000001ee0000eeeeeeeeeebbb33f90033bbbbbbbbb3333bbbbbbbbee6666eeeee66666eeeeeeee00000000
330000330000000000000000000000000000000000000000eeeeeeeeeeeeeeeebb33390d75933bbbbbbbbbbbbbbbbbbbeeeeeeeeeeee666eeeeeeeee00000000
0000000000000000000000000000000000000000eee2eeeeeeeeeeeeeee94eeeeeeeeeee00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ee922eeeeeeeeeeeee94250eeeeeeeee00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ee922eeee94eeeeee944250eeeeeeeee00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000e94422ee9424eeee94479224eeeeeeee00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000e77668ee4422eeee4477a922eeeeeeee00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000e7d768ee4772eeee4777aa92eeeeeeee00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000e6dc68ee7669e50e79999998eeeee50e00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000e67668ee6dd94504ad7d7d78ee99210e00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000096d7688e6dc92222adcdcdc8e999421e00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000096dc988e77796668777aaa982222222100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009676988e7229ddd87dda2298a77777a800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009622988e7229d7c87dca2298a227dda800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009624988e62499998adc92498a247dc9800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009624988e9249111199992498a24a999800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001111111511115555111111111111111100000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000e5555555e555555ee5555555ee55555e00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeeee0000eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeee000000eeeee000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeee080080eeeee000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeee000000eeeee000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeee000000eeeee000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeee000000eeeee000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeeee0000eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00110001101112201111101010122020212011288022220121112282a81a21aa08201010181828981a21a1818228200820800881000000000000000000000000
000001000101121200110100220022022021202882222112112228288a8aaaaaa282120181118282821218182228202082182001899100100000001001000000
01001010001121211012000200200222020202888022122120102288a8aaa8aa28222120211120022921728722a2822888080000991919011110010010000010
0000011001121111112120000002128010122208020820120000098a829a28882820212170180002289721217a2a22028880800101019a911101001000000101
00010001111110111102001000222111112220200001010100a0981999292982818201011721a0020a88021081a9aa21810882801010a989a120200000000010
0110002111210112120000001222001111222200000100800a919119999292900810101011727077a8088a08089aaaa0100018120102089a1202222000000101
0011121212201011200000022222212112222080001010007018191191211900000211021111a777708079008087aaa9000111218020288a0122120200111111
01010128210211010110802022721102228208080001001001018a1211110100012121212112707777070070080a789179111118120209008081222081111111
000010118000000011180802278710002828088000108000000810112000120012121111012101007a1027078007888987911991212020200810282828112111
00002118110000011110801212701000808080800088881000000001000220201111111111121011712202707020829278719111128202029201828282018211
0012020101100011112001072207020808000880080880000000001010202202120111111110010117172021090222202799197119882809a280881020181111
00002010101101111202001001200020808008080010000000000001000201212121010001000010717072120020220220189717111110889228080120918210
00010100010011112200a100a002028008080080a011000010120001000100000201100000000101000700201019010202270771717918888129800099192202
01110100011101112000071a002020081080001a0a10000111010010000000000000110000000010000000010102101022007007779091119891902919988101
0000101010112111000000702202800181000101a101000000101100000000010001110002000000010101101010210220000070770901111a89120891188010
000001010111121220000700222000001000091a100000000011101001101000010111000020012010100011010102222020070a77707a1128a1218281911102
010012111011982220a0a020120000010000101110000000010101011111010000000000020212110100000010101002020272111777a0a22100aa1819119920
0101210201181102000002011100101010111101010000001010101011101000000000000020212010100001010100011020011177770a011010aaa111199a92
000010200a9112100000022010000101010110101000000001010001010000000000000000020202212100001000001010000217177770018109a1911121a9a0
0000200010a1a19180902120100001000000000000000000000000000000000000000000000020010212220000001001011020011177707011921210111aaa22
00129211011a1a8808199211200000000000000000000000000000000000000000000000000000201012228000000201111110011107070701122108111aa282
012929091aa1a18880910112020000000000000000000000000000000000000000000000000000000101282800000011111121001070007011819789818a2a22
001291001a1a1880990010112000010000000000000000000000000000000000000000000000000000001280000000001111112202000227181979789808a2a8
01991010a1a1a919890101101000000000000000000000000000000000000000000000000000000000000000000000000110121222002070718897797081aa8a
11909101aa1a990898001101000000000000000000000000000000000000000000000000000000000000000000000000000101222020020708888892902a08a8
1109101a1aa99090801001000000000000000000000000000000000000000000000000000000000000000000000000000010112222002020988888982700808a
008181a1aa2a090000001000000000000000100000000000000000000000000000000000000000000000000000000000021111122002020211188989800008a2
990819aaa9901002001000000000000000000000000000000000000000000000000000000000000000000000000000002121111000002022911211989708082a
098097aa9999010a2101000000000000000000000000000000000000000000000000000000000000000000000000000002101011000001208191281909900171
08087a7a00901020a200000100000000000000000000000000000000000000000000000000000000000000000000000000221000000000080811818019091088
008027a0000002a1200000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000881118811190008a
9802a91990000a101200000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000018281122110800808
898791a1000000010000010000000001000000000000000000000000000000000000000000000000000000000000000000000000000000001881211218028082
022a2a10000001010001000000000010000000000000000000000000000000000000000000000000000000000000000000000100021000010192121121810808
2222a200001100101010110000000000000000000000000000000000000000000000000000000000000000000000000000000001212000001081211212109089
827121a0001001111101000000000000000000000000000000000000000000000000000000000000000000000000000000000010121000000088191911110898
282a1a10020000111010000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101000088989191111289
22a2a100000200120100000000000000000000000000000000000000000000000000000000000000000000000000000000000000101110110008881019212882
822a0000202111200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111101008888292921228
21100000101110100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111101010108080029021288
12100001111101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100011110111110800282212182
21020001112100200000000000000000000000000000000000000000000000000000000000000000000000000000000000000011001001101111001808221298
00201000121111000000000777777990000777777770044777777994400447777779944000000000099777777994400000000011000010110010110180802929
10010101111001000000000777777990000777777770044777777994400447777779944000000000099777777994400000000001000011101001001008020292
11111221111000000000000777777770000ff77779900777777ffff9900777777ffff990000000000777777ffff9900000000000000101010010100000202100
01102020120100000000000777777770000ff77779900777777ffff9900777777ffff990000000000777777ffff9900000000000000010100000010000022209
1001020101012000000000077ff2222ff99227799220077992222222200779922227799000000000077990000779900000000000000101000001010000020292
000a022010101100000000077ff2222ff99227799220077992222222200779922227799000000000077990000779900000000000000010101000101000102209
00a0a21208012200000000077ff0000ff990077990000779900000000007799000077990000000000ff990000ff9900000000000000001011000010001122220
070a022088822200000000077ff0000ff990077990000779900000000007799000077990000000000ff990000ff9900000000000000010111100000001810228
1970020088812010000000077ff7777222200ff990000ff990000000000ff990000ff9900ffff9900ff7777ffff9900000000000000001011100001010102222
00a0120008021200000000077ff7777222200ff990000ff990000000000ff990000ff9900ffff9900ff7777ffff9900000000000000001111100011101810222
7a0a222028212000000000077ffff99000000ff990000ff990000000000ff990000ff9900ffff990099ffffff999900000000000000010111112011110118028
a9a0220281820000000000077ffff99000000ff990000ff990000000000ff990000ff9900ffff990099ffffff999900000000000000001011100101801810280
9a91002028100000000000077992222000000ff990000ff990000000000ff990000ff99002222220077990000ff9900000000000000000011001018018108009
a9a0100221000000000000077992222000000ff990000ff990000000000ff990000ff99002222220077990000ff9900000000000000000111120110101820290
aa0a028218100000000000077990000000000ff990000ff990000000000ff990000ff990000000000ff990000ff9900000000000000000011021111010812829
aaa1102121010000000000077990000000000ff990000ff990000000000ff990000ff990000000000ff990000ff9900000000000000000010001110108121288
aa1111121110000000000007799000000000000000000ffff7777ff9900ffffffffff990000000000ff7777ffff9900000000000000000101011121088818808
80a112282011100000000007799000000000000000000ffff7777ff9900ffffffffff990000000000ff7777ffff9900000000000000000010001010108080029
28002122000110000000000ff9900009977779988880044ffffff99440044ffffff9944000000000099ffffff994400000000000000000000000201018801292
82a11011001000000000000ff9900009977779988880044ffffff99440044ffffff9944000000000099ffffff994400000000000000000000002020180811029
2a100112100100000000000222200990000990000000000002200001100110000002211000000000011222222221100000000000000000000000200008188182
82000011101100000000000222200990000990000000000002200001100110000002211000000000011222222221100000000000000000000002220000811008
20000221111100000000000000000000000990077000099000077990000007799880000779988000000000000000000000000009900000000002228001081100
02000001101100000000000000000000000990077000099000077990000007799880000779988000000000000000000000000009900000000000282110818008
80100010001110000000000000000000000880099000099009900008800992222880099000000000000000000000099000000999900000000000222211181780
28000001101100000000000000000000000880099000099009900008800992222880099000000000000000000000099000000999900000000000022111117008
80100011110100000000000000000000000880088000088008800008800880000000000228800009900990099990099000000009900000000000221111111700
22010011101010000000000000000000000880088000088008800008800880000000000228800009900990099990099000000009900000000002220110117102
92100000001100000000000000000000000880000888800008800008800008888880088888800000099000099990099009900009900000000012220101717720
28100000010100000000000000000000000880000888800008800008800008888880088888800000099000099990099009900009900000000101200000177172
11110001001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010010000017710
11110110100000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000102100000172702
11101901000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000009000000000121200000117229
01119090000801100010020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001011210001111112
10000911108081000001002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100211000111199
00101181110801100000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002120001121190
11011898111002100000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000210000111119
01120989111021210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001001111001021111
11102891111112110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000221101001812181
11011818111181810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002010110010112118
81011181111118101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000201100001022111
10121121111111010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121211
21212018101118101001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000001012118
01121102010111110000202000000000000000000000000000000000000000000000000000000000000000000000000000000000001121201000000010111292
2211012110011111000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000001211000001110a111a80
21221011210011110000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000118a1a818
222221011000011011010020200000000000000000000000000000000000000000000000000000000000000000000000000000001011101001000010a1a80082
08222011800000010011000200000000000000000000000000000000000000000000000000000000000000000000000000000000010111000000000a9a1a0000
228222182800000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000010a991a021
02822210811000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000212102000000010a09191202
2188212101110010000000000000110000000000000000000000000000000000000000000000000000000000000000000000000102100000000000a0a9910020
082812220810100008800001000111000000000000000000000000000000000000000000000000000000000000000000000100101100100000000a0a29009202
00812222808100008888000000001110000000000000000000000000000000000000000000000000000000000000000000000001101000000000a0a292988212
001812280880a00008800100000011100000000000000000000000000000000000000000000000000000000000000000101000010100000000000a0a29880121
29912220880a0a0a000010100000011100000000000000000000000000000000000000000000000000000000000000000100000110000001001000a2a8808011
111012220288a0aaa980810010010001000000000000000000000000000000000000000000000000000000000000000000000010000000001001092928282111
10020902218a8aaa9898000000100000011100000000000000000000000000000000000000000000000000000000000000000101000000110000099280821210
822020222218a10a8980880000010000111100000000000000000000000000000000000000000000000000000000000000000210110011111001078988212128
88222002122100a0a8a8880000000000010000000000000000000000000000000000000000000000000000000000000000002001001011111009977802121082
811220002220808a0aa8880000000001000001000000000000000000000000000000000000000000000000000000000000000210100101110090977000212800
2121220002222800aa08888000000110100010000000000000000000000000000000000000000010010100000001000000001011010110190009777001928820
881220000002120000a0888090000001001010000000000000000000000000000000000000000101101000000010101000100101201001000007771119188282
0881121000012aa0000aa9898900000001110100000000000000000000000000000001010100001101000000010101011101001012081010090a771011929820
882211000000aa00200aaa7898000000001111100000000000000000000000000001111010011001000000001101001010101001218180009891a01122290211
882221107000001002a0aa078a90000000111111000000000000000000000000001011000000101010000000100000010100010108180000890a110192202020
8082220707000101280aaaa8aaa98002000011101000000000000000000000000001000000000001000002010000001010010018888110099070001989821200
08089220712700aa8080aaaaaaa8a822200011110000000000000000000000000000000000000001000020100000000101011181811901998900000298910110
8080222201707a1a08820100aa82a222200001001000000000001000000000000000000000000010000002000001000010188181199190a89870102029101100
81020299900777a0a8282000002a2a02020000800000000000000100000000001000000000010100000000000010000101811818919909aa8701010201011010
188219999291777aaa82010000a2a0a000080000000000100000000000000000010000010100101000000000000000101911118119109711a100109110110100
1888811929291771aaa0100000022200208000000000010101001000000000000001011111010000000000000000000998111111199a71111101881901101000
818811180291071720a0000090072202020000000100001010110110000100000010101110100000000000000000009189811119999111101010110101010000
1212111080111072a2020209a1700020200002000100001011101101111010000001010101000000000100100900011918818999291911010181810000101000
202881020112192921202a0a98080000070020011010000101000811111110000000101000000100001209009099191111982792920108100808100001010000
00000020122191921212209909808800000000001201100011008188221010001000000000101000001190900971111111a27291211011801081010121000000
0001110101191919812202209a9aa980900000002021011001001882828221028000000001210100011119090a12111a172a2919110110122110181212111000
00121110111191989811220001aa1a900800200002001001000020082828282800000000121010102011019aa121a11112729190201021222222820121101000
0121001100111119891210201a11a177807021012000000080000000888281810080000101010111010a1aa1111a1a11a1291902010222102288281011010100
121201001101010198912820200a170777020220210000081880000010011018120010001100120110a1a2a11111a2221a119120002220080028810000021010
0121021102100010808282820202a070a77022a2022000008808a20011111111001000011010a010a21a1a211111222221211210212121808200111100000100
001111202020000000099821222111011a017aaa22020220028201110011111111001010201a0a221121a819111a202181120100181810812022011100000000
0011110101010000000990112211111900101aaaaa2012002000001101020111011102020201aa21211a7127a1a7220210090080818181181212011110000000
000111001010000000090191121112200101aaaaa7a071210000000000a0201202112222201aa9a21927977a7a72220190000808081818111121101010010110
00100000210000000000091921112211111a11a10a011711100000aa0aaa2a222221229922aaaa7a9a9272a7a802201099008080800721801111210001001000
000000000001000000000192121121111111a110a1a01101a0020aaaaaaaaa222a22299999aaaaa7a9aa02278080280008080878007282010010110001010000
00000000000000000000000018102111211811000a01a000000020aaa0a00a020222a2990a77aaaaaa2a22222809098000808287082221111101801002101000

__map__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000151615161516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000252626262525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b1b1b1b1b1b1b491b1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000035362535363500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000281a19281a1a19281a1a1a1a1a1a1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002635362526250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029081829080818290808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000036252636362600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000290818290a08182908080a0808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000036352526252500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000290a1829090a1829090a09090a080a08000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000074647564650000000074646500000000000000000000000000000000000000001a1a1a1a1a1a1a1a1a1a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a00000000000000001a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a007a5a5a5a5a7a001a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a0059587879585b001a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a006b6b6b6b7b6b001a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000004041420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a00006869696a00001a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000005051520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1a1a1a1a1a1a1a1a1a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000060616200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4a500000000000000000000000000000000000088888888888899989898989b8888889998989b888888888888889a88889a8888000000000000000000acbcbe0000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000868500000000000000b4b50000000000000000000000000000000000008b889aa88889bb989898b8ab888888999898ba8b889a888888a888888888898aae0000000000000000000000000000ac00000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000084978796969485000086848796969486000000000000000000000000000000009b88888889bbb8b998b8ab88a8a888a9b998989b888888898a8b88888888a9b9000000acadae00000000000000bcbe0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ba8b88889998babb989b888888a88888a9aaaaab88888899989b898b889a8899bcbe00000000bcbe00acae000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaab9a88a9b9989898ba8b898b88889a888888a8888888a9b9babb9b888888a90000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008888889a889998989898babb9b898b88888888889a8888889998b8ab8888888800000000bcbdbe00000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088a8888888a9b99898989898babb9b889a88888888888888a9aaab8888889a88be00000000000000000000000000bcbd00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888888888899989898989898b8ab88888888898b8888a88888888888888888000000000000000000bcbdae0000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1c1d1a1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a2c2d1c1d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1a1c1d1a1a1a1c1d1a1a2c2d2c2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c2d1a2c2d1a1c1d2c2d1a1a2c2d2c2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c3d3e3c3d3e3c3d3c3d3e3e3c3d3c3d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010f000005135051050c00005135091351c0150c1351d0150a1351501516015021350713500000051350000003135031350013500000021351b015031351a0150513504135000000713505135037153c7001b725
010f00000c03300000300152401524615200150c013210150c003190151a01500000246153c70029515295150c0332e5052e5150c60524615225150000022515297172b71529014297152461535015295151d015
010f000007135061350000009135071351f711000000510505135041350000007135051351c0151d0150313503135021350000005135031350a1050a135000000113502135031350413505135000000a13500000
010f00000c033225152e5153a515246152b7070a145350150c003290153200529005246152501526015220150c0331e0251f0252700524615225051a0152250522015225152201522515246150a7110a0001d005
0112000003744030250a7040a005137441302508744080251b7110a704037440302524615080240a7440a02508744087250a7040c0241674416025167251652527515140240c7440c025220152e015220150a525
011200000c033247151f5152271524615227151b5051b5151f5201f5201f5221f510225212252022522225150c0331b7151b5151b715246151b5151b5051b515275202752027522275151f5211f5201f5221f515
011200000c0330802508744080250872508044187151b7151b7000f0251174411025246150f0240c7440c0250c0330802508744080250872508044247152b715275020f0251174411025246150f0240c7440c025
011200002452024520245122451524615187151b7151f71527520275202751227515246151f7151b7151f715295202b5212b5122b5152461524715277152e715275002e715275022e715246152b7152771524715
011200002352023520235122351524615177151b7151f715275202752027512275152461523715277152e7152b5202c5212c5202c5202c5202c5222c5222c5222b5202b5202b5222b515225151f5151b51516515
011200000c0330802508744080250872508044177151b7151b7000f0251174411025246150f0240b7440b0250c0330802508744080250872524715277152e715080242e715080242e715246150f0240c7440c025
011600000042500415094250a4250042500415094250a42500425094253f2050a42508425094250a425074250c4250a42503425004150c4250a42503425004150c42500415186150042502425024250342504425
011600000c0330c4130f54510545186150c0330f545105450c0330f5450c41310545115450f545105450c0230c0330c4131554516545186150c03315545165450c0330c5450f4130f4130e5450e5450f54510545
0116000005425054150e4250f42505425054150e4250f425054250e4253f2050f4250d4250e4250f4250c4250a4250a42513425144150a4250a42513425144150a42509415086150741007410074120441101411
011600000c0330c4131454515545186150c03314545155450c033145450c413155451654514545155450c0230c0330c413195451a545186150c033195451a5451a520195201852017522175220c033186150c033
010b00200c03324510245102451024512245122751127510186151841516215184150c0031841516215134150c033114151321516415182151b4151d215224151861524415222151e4151d2151c4151b21518415
011400001051512515150151a5151051512515150151a5151051512515150151a5151051512515150151a5151051512515170151c5151051512515170151c5151051512515160151c5151051512515160151c515
011400000c0330253502525020450e6150252502045025250c0330253502525020450e6150252502045025250c0330252502045025350e6150204502535025250c0330253502525020450e615025250204502525
011400002c7252c0152c7152a0252a7152a0152a7152f0152c7252c0152c7152801525725250152a7252a0152072520715207151e7251e7151e7151e715217152072520715207151e7251e7151e7151e7151e715
011400000c0330653506525060450e6150652506045065250c0330653506525060450e6150652506045065250c0330952509045095350e6150904509535095250c0330953509525090450e615095250904509525
0114000020725200152071520015217252101521715210152c7252c0152c7152c0152a7252a0152a7152a015257252501525715250152672526015267153401532725310152d715280152672525015217151c015
010e000005145185111c725050250c12524515185150c04511045185151d515110250c0451d5151d0250c0450a0451a015190150a02505145190151a015050450c0451d0151c0150012502145187150414518715
010e000021745115152072521735186152072521735186052d7142b7142971426025240351151521035115151d0451c0051c0251d035186151c0251d035115151151530715247151871524716187160c70724717
010e000002145185111c72502125091452451518515090250e045185151d5150e025090451d5151d025090450a0451a015190150a02505045190151a015050450c0451d0151c0150012502145187150414518715
010e000029045000002802529035186152802529035000001a51515515115150e51518615000002603500000240450000023025240351861523025240350000015515185151c51521515186150c615280162d016
010e000002145185112072521025090452451518515090450e04521515265150e025090451d5151d01504045090451d01520015210250414520015210250404509045280152d0150702505145187150414518715
011a00000173401025117341102512734120250873408025127341202501734010251173411025087340802505734050250d7340d025147341402506734060250873408025127341202511734110250d7340d025
010d00200c0331b51119515195152071220712145151451518615317151d5151d515125050c03314515145150c0330150519515195150d517205161451514515186153171520515205150d5110c033145150c033
011a00000a7340a02511734110250d7340d02505734050250673406025147341402511734110250d7340d0250a7340a02511734110250d7340d02508734080250373403025127341202511734110250d7340d025
010d00200c0331b511295122951220712207122c5102c51018615315143151531514295150c03329515295150c0330150525515255150d517205162051520515186153171520515205150d5110c033145150c033
01180000021100211002110021120e1140e1100e1100e1120d1140d1100d1100d1120d1120940509110091120c1100c1100c1100c1120b1110b1100b1100b1120a1100a1100a1100a11209111091100911009112
01180000117201172011722117221d7201d7201d7221d7221c7211c7201c7201c7201c7221c72218720187221b7211b7201b7201b7201b7221b7221d7221d7221a7201a7201a7201a7201a7221a7221672016722
011800001972019720197221972218720187201872018720147201472015720157201f7211f7201d7201d7201c7201c7201c7221c7221a7201a7201a7221a7251a7201a7201a7221a72219721197201972219722
011800001a7201a7201a7221a7221c7201c7201c7221c7221e7201e7202172021720247212472023720237202272022720227202272022722227221f7201f7202272122720227202272221721217202172221722
0118000002114021100211002112091140911009110091120e1140e1100c1100c1120911209110081100811207110071100711007112061110611006110061120111101110011100111202111021100211002112
0118000020720207202072220722217202172021722217222b7212b72029720297202872128720267202672526720267202672026720267222672228721287202672026720267202672225721257202572225722
010e00000c0231951517516195150c0231751519516175150c0231951517516195150c0231751519516175150c023135151f0111f5110c0231751519516175150c0231e7111e7102a7100c023175151951617515
010e000000130070200c51000130070200a51000130070200c51000130070200a5200a5200a5120a5120a51200130070200c51000130070200a51000130070200c510001300b5200a5200a5200a5120a5120a512
010e00000c0231e5151c5161e5150c0231c5151e5161c5150c0231e5151c5161e5150c0231c5151e5161c5150c0230c51518011185110c0231c5151e5161c5150c0231e7111e7102a7100c023175151951617515
010e0000051300c02011010051300c0200f010051300c02011010051300c0200f0200f0200f0120f0120f012061300d02012010071300e02013010081300f0201503012020140101201015030120201401012010
010700000c5370f0370c5270f0270f537120370f527120271e537230371e527230272f537260372f52726027165371903716527190271c537190371c527210271c53621036245262102624536330362452633026
018800000074400730007320073200730007300073200732007300073200730007320073000732007320073200732007300073000730007320073000730007300073200732007300073000732007300073200732
01640020070140801107011060110701108011070110601100013080120701106511070110801707012060110c013080120701106011050110801008017005350053408010070110601100535080170701106011
018800000073000730007320073200730007300073200732007300073200730007320073000732007320073200732007300073000730007320073000730007300073200732007300073000732007300073200732
0164002006510075110851707512060110c0130801207011060110501108017070120801107011060110701108011075110651100523080120701108017005350053408012070110601100535080170701106511
011800001d5351f53516525275151d5351f53516525275151f5352053518525295151f5352053518525295151f5352053517525295151f5352053517525295151d5351f53516525275151d5351f5351652527515
010c00200c0330f13503130377140313533516337140c033306150c0330313003130031253e5153e5150c1430c043161340a1351b3130a1353a7143a7123a715306153e5150313003130031251b3130c0331b313
010c00200c0331413508130377140813533516337140c033306150c0330813008130081253e5153e5150c1330c0430f134031351b313031353a7143a7123a715306153e5150313003130031251b3130c0333e515
011800001f5452253527525295151f5452253527525295151f5452253527525295151f5452253527525295151f5452353527525295151f5452353527525295151f5452253527525295151f545225352752529515
010c002013035165351b0351d53513025165251b0251d52513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165251b0351d545
011200000843508435122150043530615014351221502435034351221508435084353061512215054250341508435084350043501435306150243512215034351221512215084350843530615122151221524615
011200000c033242352323524235202351d2352a5111b1350c0331b1351d1351b135201351d135171350c0330c0332423523235202351d2351b235202352a5110c03326125271162c11523135201351d13512215
0112000001435014352a5110543530615064352a5110743508435115152a5110d43530615014352a511084150d4350d4352a5110543530615064352a5110743508435014352a5110143530615115152a52124615
011200000c033115152823529235282352923511515292350c0332823529216282252923511515115150c0330c033115151c1351d1351c1351d135115151d1350c03323135115152213523116221352013522135
0112000001435014352a5110543530615064352a5110743508435115152a5110d435306150143502435034350443513135141350743516135171350a435191351a1350d4351c1351d1351c1351d1352a5001e131
011200000c033115152823529235282352923511515292350c0332823529216282252923511515115150c0330c033192351a235246151c2351d2350c0331f235202350c033222352323522235232352a50030011
0114001800140005351c7341c725247342472505140055352173421725287342872504140045351f7341f725247342472502140025351d7341d72524734247250000000000000000000000000000000000000000
011400180c043287252b0152f72534015377253061528725290152d72530015377250c0432f7253001534725370153c725306152b7252d01532725370153b7250000000000000000000000000000000000000000
0114001809140095351f7341f7252473424725091400953518734187251f7341f72505140055351f7341f7252473424725051400553518734187251f7341f7250000000000000000000000000000000000000000
0114001802140025351f7341f725247342472504140045351f7341f725247342472505140055352b7242b715307243071507140075352b7242b71534724347150000000000000000000000000000000000000000
011400180c0433772534015307252f0152d725306152d7252f0153072534015377250c0433772534015307252f0152d725306152d7252f0153072534015377250000000000000000000000000000000000000000
011400180c0433c7253701534725300152f725306152f7253001534725370153c7250c0433c7253701534725300152f725306152f7253001534725370153c7250000000000000000000000000000000000000000
011400180c043287252b0152f725340153772530615287252901530725370153c7250c043287252901530725370153c72530615287252901530725370153c7250000000000000000000000000000000000000000
011400180c003287052b0052f705340053770530605287052900530705370053c7050c0032f7053000534705370053c705306052b7052d00532705370053b7050000000000000000000000000000000000000000
000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00014344
00 00014344
01 00014344
00 00014344
00 02034344
02 02034344
00 04424344
00 04424344
00 04054344
00 04054344
01 04054344
00 04054344
00 06074344
02 08094344
01 0a0b4344
00 0c0d4344
00 0a0e4344
02 0c0e4344
00 10424344
01 100f4344
00 100f4344
00 10114344
00 12114344
02 12134344
01 14154344
00 14154344
00 16154344
00 16154344
00 18174344
02 16174344
00 19424344
01 191a4344
00 191a4344
00 1b1a4344
00 191c4344
02 1b1c4344
01 1d1e4344
00 1d1f4344
00 1d1e4344
00 1d1f4344
00 21204344
02 1d224344
00 27424344
01 24234344
00 24234344
02 26254344
01 28294344
03 2a2b4344
01 2d304344
00 2e304344
00 2d304344
00 2e304344
00 2d2c4344
00 2d2c4344
02 2e2f4344
01 31324344
00 31324344
00 33344344
02 35364344
01 3738433f
00 3738433f
00 393b433f
00 393c433f
02 3a3d433f

