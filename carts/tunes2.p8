pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--pico-8 tunes #2    @grubermusic
--      @krajzeg   @castpixel
object={}
function object:extend(kob)if type(kob)=="string" then
kob=ob(kob)end
kob=kob or {}
kob.extends,kob.meta=
self,{__index=kob}
return setmetatable(kob,{__index=self,__call=function(self,ob)ob=setmetatable(ob or {},kob.meta)
if (kob.init)kob.init(ob)
return ob
end
})end
vector={}
vector.__index=vector
function vector:__add(b)
return v(self.x+b.x,self.y+b.y,self.z+b.z)end
function vector:__sub(b)
return v(self.x-b.x,self.y-b.y,self.z+b.z)end
function vector:__mul(m)
return v(self.x*m,self.y*m,self.z*m)end
function vector:__div(d)
return v(self.x/d,self.y/d)end
function vector:__unm()
return v(-self.x,-self.y)end
function vector:dot(v2)
return self.x*v2.x+self.y*v2.y
end
function vector:norm()
return self/sqrt(#self)end
function vector:rotr()
return v(-self.y,self.x)end
function vector:len()
return sqrt(#self)end
function vector:__len()
return self.x^2+self.y^2
end
function vector:str()
return self.x..","..self.y
end
function v(x,y,z)
return setmetatable({x=x,y=y,z=z or 0,},vector)end
function mav(magnitude,angle)
return v(cos(angle),sin(angle))*magnitude
end
function call(fn,a)
return fn
and fn(a[1],a[2],a[3],a[4],a[5])or a
end
function set(o,props)for k,v in pairs(props or {})do
o[k]=v
end
return o
end
function ob(str,props)local result,s,n,inpar=
{},1,1,0
each_char(str,function(c,i)local sc,nxt=sub(str,s,s),i+1
if c=="(" then
inpar+=1
elseif c==")" then
inpar-=1
elseif inpar==0 then
if c=="=" then
n,s=sub(str,s,i-1),nxt
elseif c=="," and s<i then
result[n]=sc=='"'and sub(str,s+1,i-2)or sub(str,s+1,s+1)=="("and call(obfn[sc],ob(sub(str,s+2,i-2)..","))or sc!="f"and band(sub(str,s,i-1)+0,0xffff.fffe)s=nxt
if (type(n)=="number")n+=1
elseif sc!='"'and c==" " or c=="\n" then
s=nxt
end
end
end)
return set(result,props)end
function each_char(str,fn)local rs={}
for i=1,#str do
add(rs,fn(sub(str,i,i),i))end
return rs
end
obfn={v=v}
function init_palettes(n)local a=0x5000
for p=0,n do
for c=0,15 do
local v=sget(p,c)
if (c==sget(p,16))v+=0x80
poke(a,v)
a+=1
end
end
end
function set_palette(no)memcpy(0x5f00,0x5000+shl(flr(no),4),16)end
function bg(clr)rectfill(0,0,128,72,clr)end
function rndf(l,h)
return l+rnd(h-l)end
function rndpick(seq)
return seq[flr(rnd(#seq)+1)]
end
function lerp(a,b,t)
return a+(b-a)*t
end
function round(n)
return flr(n+0.5)end
psh=ob([[
o(x=-1,y=-1,c=0),
o(x=0,y=-1,c=0),
o(x=1,y=-1,c=0),
o(x=-1,y=0,c=0),
o(x=1,y=0,c=0),
o(x=-1,y=1,c=0),
o(x=0,y=1,c=0),
o(x=1,y=1,c=0),
o(x=0,y=0,c=1),
]])function printsh(t,x,y,c,a)
if (a)x-=a*4*#t
for d in all(psh)do
print(t,x+d.x,y+d.y,c*d.c)end
end
function each(seq,fn)local mapped={}
for i,e in pairs(seq)do
mapped[i]=fn(e,i)end
return mapped
end
function rng(a,b)
if (not b)a,b=1,a
local r={}
for i=a,b do
add(r,i)end
return r
end
function screengrab(yt,yb)memcpy(0x1800,0x6000+0x40*(yt+cam.y),(yb-yt+1)*0x40)end
function ngon(pts,c)local xls,xrs,npts={},{},#pts
for i=1,npts do
ngon_edge(pts[i],pts[i%npts+1],xls,xrs
)end
for y,xl in pairs(xls)do
rectfill(xl,y,xrs[y],y,c)end
end
function ngon_edge(a,b,xls,xrs)local ax,ay=a.x,round(a.y)local bx,by=b.x,round(b.y)
if (ay==by)return
local x,dx,stp=
ax,(bx-ax)/abs(by-ay),1
if by<ay then
xrs,stp=xls,-1
end
for y=ay,by,stp do
xrs[y]=x
x+=dx
end
end
function init_noise()srand(123)for addr=0x4300,0x4aff do
poke(addr,rnd(256))end
end
function noise(x,y)local ix,iy=band(x,0x3f),band(y,0x1f)local a=0x4300+shl(iy,6)+ix
local fx,fy=band(x,0x0.ffff),band(y,0x0.ffff)local ifx=1-fx
return (1-fy)*(peek(a)*ifx+peek(a+1)*fx)+
fy*(peek(a+64)*ifx+peek(a+65)*fx)end
function moving_noise(h,nx,nxm,nym,y_persp,fade,colors
)
nx-=nxm*256
local bps,lut={},{}
local first=0
for c in all(colors)do
for i=first,c[2]do
lut[i]=c[1]
end
first=c[2]
end
for y=1,h do
bps[y]={{x=127,c=12}}
end
local mnoise={}
function mnoise:move(d)
nx+=nxm*d
local dp,dpstep=d,d*y_persp
for y=1,h do
local ny,ln=y*nym,bps[y]
for _,b in pairs(ln)do
b.x+=dp
end
if ln[2]and ln[2].x>127 then
del(ln,ln[1])end
local nc=lut[flr(mid(noise(nx,ny)+fade*y,0,255))]
if nc~=ln[#ln].c then
add(ln,{x=0,c=nc})end
dp+=dpstep
end
end
function mnoise:render(base_y,rf)for y=1,h do
local sy,ln=base_y+y-1,bps[y]
for i=1,#ln do
local f,t=ln[i],ln[i+1]
if (f.c)rf(f.x,sy,t and t.x or 0,sy,f.c)
end
end
end
for i=1,256 do
mnoise:move(1)end
return mnoise
end
function waterfall_scene()local brefl=bumprefl()local w1,w2=
waterfall(36,12,17,56,3,brefl),waterfall(88,8,25,56,2,brefl)
return function(t)bg(12)w1.body(t)w2.body(t)map(0,0,0,0,16,8)set_palette(7)brefl:update()brefl:draw(t)set_palette()w1.foam(t)w2.foam(t)screengrab(28,59)end
end
bumprefl=object:extend()function bumprefl:init()self.b,self.v={},{}
for i=-65,832 do
self.b[i]=0
self.v[i]=0
end
end
function bumprefl:update()local i=0
local ba,va=self.b,self.v
for i=0,767 do
local b,v=ba[i],va[i]
v=(ba[i-64]+ba[i-1]+ba[i+1]-b*3)*0.018+
(ba[i+64]-b)*0.016+
v-b*0.02
b+=v
v*=0.955
ba[i],va[i]=b,v
end
end
function bumprefl:draw(t)local i=0
for y=60,71 do
local shy=296.09-y*2.8181
for x=0,127,2 do
local b=flr(self.b[i])if abs(b)>15 then
rectfill(x,y,x+1,y,b>0 and 7 or 0)else
sspr(x+b,shy,2,1,x,y)end
i+=1
end
end
end
function waterfall(c,w,top,bottom,flow,brefl)local xl,xr=c-w,c+w-1
local flows,foam={},{}
local gravity,foam_c,foam_p=
v(0,0.08),ob([[6,7,7,7,]]),
ob([[-23130.5,23130.5,0.5,0.5,]])
local rects={bottom,12,top+1,7,top,5}
return {
body=function(t)
t/=8
for i=1,5,2 do
rectfill(xl,top,xr,rects[i],rects[i+1])
end
for m=1.1,2.1 do
rectfill(c+sin(t*m)*w,top+1,
c+sin(t*m+0.05)*w,bottom,
13)
end
for i=1,flow do
add(flows,{
x=rndf(xl,xr),
y=top+1,v=rndf(1,3),
c=rndf(6,8)
})
end
for f in all(flows)do
local x,y,vel=f.x,f.y,f.v
f.y+=vel
rectfill(x,y,x,f.y+vel,f.c)
if y>bottom then
del(flows,f)
add(foam,{
p=v(x,y),
v=mav(vel*rndf(0.1,0.2),rndf(0.15,0.35)),
l=vel*2.5
})
brefl.v[flr(x*0.5)]+=vel*5
end
end
end,
foam=function(t)
for f in all(foam)do
local i=flr(f.l/3)+1
local size=5.5-abs(f.l-4)
fillp(foam_p[i])
circfill(f.p.x,f.p.y,size,foam_c[i])
circfill(f.p.x+2,f.p.y+2,size,6)
f.p+=f.v
f.v+=gravity
f.v*=0.985
f.l-=0.4
if (f.l<=0)del(foam,f)
end
fillp()
end
}
end
function clockwork_scene()
local beat,trans=48,20
local panel_pos=ob([[
v(5,32),
v(39,20),
v(72,21),
v(103,28),
]])local gear_draws=ob([[
o(v=v(2,2),c=0),
o(v=v(0,-1),c=13),
o(v=v(0,0),c=5),
]])local fggears=each(ob([[
o(v(25,7),10,7,0.4,1),
o(v(53,32),20,10,0.2),
o(v(61,75),16,8,0.28,1),
o(v(14,46),15,8,0.25,1),
o(v(90,19),12,8,0.4,1),
o(v(114,44),15,8,0.25),
]]),function(d)return call(gear,d)end)local bggears=each(ob([[
o(v(13,15),15,6,0.24,1),
o(v(71,6),8,6,0.25,1),
o(v(82,66),25,18,0.15),
o(v(33,66),18,14,0.2,1),
o(v(120,10),12,10,0.2,1),
]]),function(d)return call(gear,d)end)local panels=each(panel_pos,panel)local bt,phase=0
return function(t)local on_beat=t-bt>trans and stat(20)%8==0
if (on_beat)bt=t
phase=(t-bt)/trans
if (phase>1)phase=0
bg(0)for g in all(bggears)do
local c,s=g(phase,v(0,0),1)circfill(c.x,c.y,s*0.8,0)circfill(c.x,c.y,2,1)end
for g in all(fggears)do
for d in all(gear_draws)do
g(phase,d.v,d.c)end
end
for p in all(panels)do
p(on_beat)end
end
end
panel_words=ob([[
o(2,4,14,6),
o(0,1,2,3),
o(9,6,6,10),
o(11,12,13,7),
o(2,6,14,15),
o(1,5,6,7),
]])function slat_coords(w,i)local sprn=panel_words[w][i]
return v(72+sprn%4*6,flr(sprn/4)*8)end
function panel(bpos,d)local move_dir=ob([[-1,-1,-1,1,1,1,]])
local slats=ob([[0,0,0,0,]])
local word,order,moving,turning=0,5,0
local s1,s2
local pos,vdown=bpos,v(0,1)
return function(beat)
if beat and not turning or not s1 then
moving=8
order+=1
if order==6 then
order=0
word=word%#panel_words+1
s1,s2,slats=
slat_coords(word,d),
slat_coords(word%#panel_words+1,d),
ob([[0,0,0,0,]])
elseif order<5 then
repeat
turning=flr(rndf(1,5))
until slats[turning]==0
end
end
if turning then
slats[turning]+=0.0625
if slats[turning]==1 then
turning=nil
end
end
if moving>0 then
pos.y+=0.5*move_dir[(order+shl(1,d))%6+1]
moving-=1
end
map(32,0,pos.x-8,pos.y-11,4,5)
for y=0,3 do
slat(pos+vdown*y*6,
s1+vdown*y*2,s2+vdown*y*2,
slats[y+1])
end
end
end
function slat(p,s1,s2,turn)
local x,y,h=p.x,p.y,abs(cos(turn/2))*6
local half_h=h/2
local yb=y-half_h
set_palette(5-abs(0.5-turn)*10)
rectfill(x,yb,x+19,y+half_h-1,0)
local s=turn>0.5 and s2 or s1
sspr(s.x,s.y,6,2,x+1,yb,18,h)
set_palette(8)
sspr(s.x,s.y,6,1,x+1,yb,18,1)
set_palette()
end
function gear(c,size,count,height,cw)
local pitch,width=1/count,0.5/count
if (cw)pitch*=-1
local spokes=each(rng(count),function(i)
local b=i*pitch
return rotgon({
{0.95,b-width*0.2},
{0.95,b+width*1.2},
{1+height,b+width*0.8},
{1+height,b+width*0.2}
})
end)
return function(seq,d,clr)
local ctr=c+d
for s in all(spokes)do
s:update(ctr,size,seq*pitch):draw(ngon,clr)
end
circfill(ctr.x,ctr.y,size,clr)
return c,size
end
end
function rotgon(pts)
local rpts=each(pts,function()return v(0,0)end)
return {
update=function(self,c,s,a,sx)
sx=sx or 1
for i,p in pairs(pts)do
local a,as,rp=
p[2]+a,p[1]*s,
rpts[i]
rp.x,rp.y=
c.x+cos(a)*as*sx,
c.y+sin(a)*as
end
return self
end,
draw=function(self,fn,clr)
fn(rpts,clr)
return self
end,
pts=rpts,
opts=pts
}
end
function extrude_and_outline(pts,depth,clr,outline)
local npts,dv=#pts,v(depth,0)
for i,p in pairs(pts)do
local n=pts[i%npts+1]
if p.y<n.y then
ngon({p,p+dv,n+dv,n},clr)
line(p.x+outline,p.y,n.x+outline,n.y,0)
end
end
end
function gate_scene()
local glow=circs(ob([[
o(x=0,y=0,r=13,clr=2),
o(x=-1,y=0,r=11,clr=4),
o(x=-2,y=0,r=10,clr=9),
o(x=-3,y=0,r=9,clr=10),
o(x=-4,y=0,r=7,clr=7),
]]),2)local segs=ob([[
o(s=0,as=0.01,ae=0.115),
o(s=0,as=0.1975,ae=0.265),
o(s=0,as=0.285,ae=0.365),
o(s=0,as=0.4475,ae=0.5525),
o(s=0,as=0.6975,ae=0.8025),
o(s=0,as=0.8225,ae=0.865),
o(s=0,as=0.885,ae=0.99,h=3),
o(s=0.05,as=0.135,ae=0.1775,h=2),
o(s=0.05,as=0.385,ae=0.4275,h=2),
o(s=0.05,as=0.5725,ae=0.615,h=3),
o(s=0.05,as=0.635,ae=0.6775,h=3),
]])for s in all(segs)do
local inner,outer=23*(1-s.s),30*(1+s.s)s.rg=rotgon({{inner,s.as},{inner,s.ae},{outer,s.ae},{outer,s.as}
})s.c=v(58-(s.h or 0),36)end
local stars=starfield(ob([[
origin=v(128,36),
spread=36,n=100,
left=0,right=128,
spd=1,spdf=1,flip=-1,
colors=o(1),
]]))local tunnel=starfield(ob([[
origin=v(74,36),
spread=6,n=200,
left=74,right=128,
spd=3,spdf=-2,flip=1,
colors=o(7,7,10,9,4,2,1),
]]))local tunnel_rects=ob([[
o(y1=32,y2=40,c=1),
o(y1=33,y2=39,c=4),
o(y1=34,y2=38,c=9),
o(y1=35,y2=37,c=10),
]])local ships,ship_p={},0.1
local anim,g1a,g2a=0,0,0.5
return function(t,cam)anim=lerp(anim,0,0.1)local pull=min(-anim*7,0)local rot_speed=1-anim
g1a-=rot_speed/240
g2a+=rot_speed/360
stars:draw()function draw_gates(front_parts)draw_gate(segs,0.8,v(20+pull,0),g1a,5,13,1,front_parts)draw_gate(segs,1,v(-pull,0),g2a,13,6,1,front_parts)end
draw_gates(false)glow(v(64,36),1+anim*0.75)for r in all(tunnel_rects)do
rectfill(tunnel.left,r.y1,128,r.y2,r.c)end
tunnel:draw()for s in all(ships)do
if s:update(ships)then
anim=2
g1a+=0.05
g2a-=0.05
end
s:render()end
set_palette()draw_gates(true)if rnd()<ship_p then
local bv=rndf(0.25,0.4)add(ships,ship({p=v(-16,rndf(28,44)),base_v=bv,v=v(bv,0),m=rndpick(ship.models)}))ship_p=-0.015
else
ship_p+=0.0005
end
end
end
ship=object:extend(ob([[
models=o(
o(sx=0,sy=40,sw=8),
o(sx=0,sy=32,sw=16),
o(sx=8,sy=40,sw=8),
o(sx=0,sy=48,sw=16),
),
]]))function ship:update(ships)local d=64-self.p.x
if d<50 then
self.v.x+=0.25/d*d
end
self.p+=self.v
if self.p.x>=128 then
del(ships,self)end
if d<22 and not self.boom then
self.boom=true
return true
end
end
function ship:render()local m,v_factor=self.m,self.v.x^2
local w=(1+v_factor*0.125)*m.sw
local plt=16+v_factor*0.3
for n=4,0,-1 do
set_palette(mid(plt-n*3,16,21))palt(0,true)sspr(m.sx,m.sy,m.sw,8,self.p.x-(self.v.x-self.base_v)*n,self.p.y,w,8)end
end
function draw_gate(segs,size,d,a,fg,hl,bg,front)for s in all(segs)do
s.front=(s.rg.opts[1][2]+a+0.75)%1>0.5
if s.front==front then
s.rg:update(s.c+d-v(1,1),size,a,0.5)extrude_and_outline(s.rg.pts,5+(s.h or 0),bg,2)end
end
for s in all(segs)do
if s.front==front then
s.rg:draw(ngon,hl):update(s.c+d,size,a,0.5):draw(ngon,fg)end
end
end
function circs(cs,r,cr)
return function(ctr,scl)for c in all(cs)do
circfill(ctr.x+c.x*scl+(cr or 2)*rnd(),ctr.y+c.y*scl+(cr or 2)*rnd(),c.r*scl+rnd(r),c.clr
)end
end
end
starfield=object:extend()function starfield:init()self.stars=each(rng(self.n),function()local s=self:new()s.x=rndf(self.left,self.right)
return s
end)end
function starfield:new()local ny=rndf(-0.99,0.99)local y=self.origin.y+ny*self.spread
local vx=self.spd+ny^2*self.spdf
local c=self.colors[flr(1+abs(ny)*(#self.colors))]
return {x=self.origin.x,y=y,vx=vx*self.flip,c=c
}
end
function starfield:draw()for i,s in pairs(self.stars)do
local x=s.x
rectfill(x,s.y,x-s.vx+self.flip,s.y,s.c)
s.x+=s.vx
if x<self.left or x>self.right then
self.stars[i]=self:new()end
end
end
function autumn_scene(wind_s)local tree=branch(19,0,4)local wind=0
local gust,delay=wind_s,120
local sky=moving_noise(58,1,0.05,1,-0.01,2,ob([[o(7,100),o(6,150),o(12,256),o(13,256),]])
)
local ground=moving_noise(
27,18.80,0.02,0.04,0,0,
ob([[o(f,135),o(6,145),o(10,170),o(9,180),o(10,190),o(9,210),o(4,256),]])
)
return function(t)
sky:render(0,rectfill)
ground:render(46,rectfill)
tree(v(27,66),0.25,wind,t/120)
set_palette(9)
spr(112,19,62,2,1)
wind=lerp(wind,gust,0.01)
delay-=1
if delay<=0 then
gust,delay=
max(wind_s-gust+rndf(0.0,0.2)*wind_s,wind_s*0.1),
rndf(60,240)
end
sky:move(wind*30)
end
end
depth_base_w,depth_tip_a=
0.03,0.004
function branch(m,a,depth)
local children
if depth>0 then
function fork(length,turn,depth)
return branch(length*0.8*rndf(0.9,1.1),turn*rndf(0.6,1.5),depth-1)
end
children={fork(m,-0.1,depth),fork(m,0.1,depth)}
else
children={clump()}
end
local base_w=0.15+depth_base_w*depth
local tip_a=0.01+depth_tip_a*depth
function shape(wl,wr,as)
return rotgon({
{base_w*wl,-0.25},{base_w*wr,0.25},
{1,tip_a*as},{1,-tip_a*as}
})
end
local back,front=
shape(1,1,1),shape(0.15,0.65,0.5)
local right,off,twist=v(1,0),rndf(-0.1,0.1),0
return function(base,ang,wind,t)
ang+=a
local wind_s=wind/(depth+1)
wind_s*=right:dot(mav(1,ang-0.25))
wind_s=mid(wind_s,-0.05,0.05)
twist+=wind_s*0.07
twist*=0.95+sin(t+off)*0.01
ang-=twist
back:update(base,m,ang):draw(ngon,0)
front:update(base,m,ang):draw(ngon,2)
local tip=base+mav(m,ang)
for child in all(children)do
child(tip,ang,wind,t*(1+off))
end
end
end
local leaf_s=ob([[13,14,15,29,30,31,]])
function clump()
local leaves=each(rng(10),function()
return {
p=mav(rndf(0,8),rnd())-v(4,4),
s=rndpick(leaf_s)
}
end)
return function(base,_,wind)
local windf=min(wind*5+0.5,2)
for _,l in pairs(leaves)do
local lx,ly=
base.x+l.p.x+rnd(windf),
base.y+l.p.y+rnd(windf)
spr(l.s,lx,ly)
if l.v then
l.p+=l.v
l.v.x+=wind*rndf(-0.2,2)
l.v.y+=rndf(0,0.04)
l.v*=0.95
if lx>128 or ly>72 then
del(leaves,l)
end
end
end
if rnd(20)<wind then
add(leaves,{
p=mav(4,rnd()),
v=v(0,0),
s=rndpick(leaf_s)
})
end
end
end
function flame_scene()
local sprs=ob([[
moon=o(82,104,3,2,2),
bonfire1=o(66,33,43,2,1),
bonfire2=o(66,41,44,2,1),
aragorn=o(68,65,26,4,4),
]])local light=ob([[
o(1,54,-23131),
o(1,50),
o(18,42,-23131),
o(2,34),
o(36,27,-23131),
o(4,20),
o(9,11)
]])light[0]={0,54}
for i=1,#light do
local l=light[i]
l.extent,l.clr={},{}
local radius=l[2]
for a=0,0.24,0.008 do
local x,y=
cos(a)*radius,flr(-sin(a)*0.3*radius)l.extent[y],l.clr[y]=
x,noise(y*0.7,2)<128 and i-1 or i
end
end
local lighting=flamelight(45,53,light)local flames=each(ob([[
o(45,47,5,0.8),
o(43,46,3,0.4),
o(47,48,4,0.6),
]]),function(fd)
return call(flame,fd)end)
return function(t)
t*=0.1
local wind=noise(t,3)/1024
for i=1,20 do
pset(noise(i,10)/2,noise(i,8)/8,1)end
call(spr,sprs.moon)lighting(t)set_palette(5)sspr(32,32,32,32,63,51,64+wind*64,11,false,true)set_palette(10+noise(t*5,3)/80)call(spr,sprs.aragorn)set_palette()call(spr,sprs.bonfire1)call(spr,sprs.bonfire2)for f in all(flames)do
f(t,wind)end
set_palette()end
end
function flame(cx,cy,gen,sz)local sparks={}
return function(t,wind)local m=1+noise(t,4)/512
for i=1,gen*m do
add(sparks,{x=cx-4+noise(t*3,4)/32+rndf(-sz,sz),y=cy,vx=rndf(-sz,sz),vy=-0.5,age=0,swing=rndf(0.04,0.07)})end
set_palette(15)for i,s in pairs(sparks)do
s.age+=0.015
s.x+=s.vx+wind
s.y+=s.vy
s.vx-=(s.x-cx)*s.swing*s.age
local x,y=s.x,s.y
if rnd()>s.age then
pset(x,y,pget(x,y))pset(x,y+1,pget(x,y+1))end
if s.age>1 then
sparks[i]=nil
end
end
end
end
function flamelight(cx,cy,light)
return function(t)local by=cy
for l in all(light)do
local flicker=1+noise(t,l[2])*0.001
for y=-18,18 do
local yi=abs(y)local ext,clr=l.extent[yi],l.clr[yi]
if ext then
fillp(light[clr][3])
ext*=flicker
ext+=rndf(-2,2)
rectfill(cx-ext,by+y,cx+ext,by+y,light[clr][1])end
end
by-=1
end
end
end
function eyes_scene()local left_wall=brickwall(56,-40,-1,8)local right_wall=brickwall(64,168,1,4)local mons=monsters(10,69,37)
return function(t)bg(0)mons(t)stairs(left_wall(t),right_wall(t))end
end
function raycast(screen_x,origin,radius)local ray=v((screen_x-64)*0.0234,-1):norm()local dot=ray:dot(-origin)local s=radius^2+dot^2-#origin
if (s<0.0)return nil
s=sqrt(s)if dot<s and dot+s>=0 then
s=-s
end
return origin+ray*(dot-s)end
function monsters(n,cx,cy)local mons=each(rng(n),function()
return {mx=rndf(1,3),my=rndf(1,3),ox=rnd(),oy=rnd(),s=rndf(2,6),e=0,espr=rndpick(ob([[106,107,122,123,]]))
}
end)
return function(t)
t*=0.001
for m in all(mons)do
local x,y=
cos(m.mx*t+m.ox)*12,
sin(m.my*t+m.oy)*10
if m.e==0 then
if (rnd()<0.003)m.e=11
else
set_palette(abs(m.e-6))
spr(m.espr,cx+x,cy+y)
m.e-=0.125
end
end
set_palette()
end
end
function stairs(lst,rst,i)
while lst[i]do
if rst[i-2]then
local l,r=lst[i],rst[i-2]
ngon({l,r,r+v(0,5),l+v(0,5)},0)
line(l.x,l.y,r.x,r.y,1)
end
i-=1
end
end
function brickwall(sx,ex,dx,r)
local eye=v(-6,4)
local intersection={}
for x=sx,ex,dx do
local ip=raycast(x,eye,r)
if ip then
ip.a=atan2(ip.x,ip.y)
intersection[x]=ip
end
end
return function(t)
local steps,pstep,fstep={}
local tf=t*0.5%32
for screen_x=sx,ex,dx do
local ip=intersection[screen_x]
if ip then
local angle=ip.a
local tex_x=-angle*1200+tf
local z=eye.y-ip.y
if z<7.14 then
local step=flr(tex_x/16+42)
local h=72/z
local screen_y=24-h+z*1.5+abs(sin(tf/32))*2
local screen_h=h*2+(step-tf/16)*2
if screen_x>=0 and screen_x<=127 then
texcol(64,32,tex_x,7+(step-tf/16)*0.25,
screen_x,screen_y,screen_h,
z*0.7)
end
if step~=pstep then
steps[step]=v(screen_x,flr(screen_y+screen_h))
pstep,fstep=step,fstep or step
end
end
end
end
set_palette()
return steps,fstep
end
end
function texcol(tox,toy,tx,trep,
sx,sy,sh,plt)
local tsx,tsy=tox+band(tx,0xf),toy
local sreph=sh/trep
for rep=1,trep do
if sy+sreph>0 and sy<128 then
set_palette(plt+rnd(0.2))
sspr(tsx,tsy,1,8,
sx,sy,1,sreph+1)
tsy=toy+rep%2*8
end
sy+=sreph
end
local f=trep%1
if f>0 then
sspr(tsx,tsy,1,8*f+1,
sx,sy,1,sreph*f+1)
end
end
function icarus_scene()
local sun=circs(ob[[
o(x=0,y=0,r=9,clr=9),
o(x=0,y=0,r=8,clr=10),
o(x=0,y=0,r=6,clr=7),
]],0,0)local icarus=make_icarus()local clouds=moving_noise(40,10,0.05,1,0,0.3,ob[[
o(7,10),o(6,20),o(false,256),o(13,256),
]])local sink,map_x=0,0
return function(t)bg(12)for d=0,256,256 do
map(0,8,d-map_x,36+sink/5,32,5)end
sun(v(110,12+sink/5),1)clouds:render(3,inv_rectfill)draw_terrain(t*0.0293,150-sink*0.85,40,9.5,1.1,7.4)sink=icarus(t)draw_terrain(t*0.039125,150-sink,10,9,2.2,5.5)map_x=(map_x+0.1)%256
clouds:move(4)end
end
function inv_rectfill(x1,y1,x2,...)rectfill(127-x1,y1,127-x2,...)end
function make_icarus()local y_pos,fall_v,wings=0,0.02,1
local frm=ob([[128,130,130,130,132,132,132,132,132,130,134,160,162,164,164,164,164,164,162,162,160,160,]])
local gravity=ob([[1,2,2,2,3,3,3,3,3,2,1,-1,-4,-12,-8,-4,-3,-3,-2,-2,-1,0,]])
return function(t)
if wings==1 and rnd()<y_pos*0.06 then
wings=2
end
local ind=flr(max(wings,1))
spr(frm[ind],30,10+y_pos*10,2,2)
y_pos+=fall_v
fall_v+=gravity[ind]*0.001
if wings~=1 then
wings=wings%#frm+0.5
else
fall_v=min(fall_v,0.01)
end
fall_v=max(fall_v,-0.04)
return y_pos*8
end
end
function draw_terrain(t,horiz,x_base,z_base,slp,zs)
memset(0x1800,72,0x90)
set_palette(22)
local prev_h=0
local z,zstep=zs,0.18
x_base+=t
while z<8 do
local xstep,nz=z*0.0094,z
local sx,addr=-4,0x1800
local base_y,h_mul=horiz-z*z_base,8/z
for x=x_base-z*0.3-xstep*2,x_base+z*0.3,xstep do
local h=noise(x,nz)*0.08+sin(x)
local slope=mid(3+(h-prev_h)*slp,0,6)
local yproj=base_y-h*h_mul
local limit=peek(addr)
if yproj<limit then
rectfill(sx,yproj,sx+1,limit,slope)
poke(addr,yproj)
end
prev_h=h
sx+=2
addr+=1
end
z+=zstep
zstep+=0.015
end
local addr=0x1800
for sx=-4,127,2 do
rectfill(sx,peek(addr),sx+1,peek(addr),1)
addr+=1
end
set_palette()
end
ohpts=ob([[
v(0,5,0),
v(5,0,0),v(0,0,5),v(-5,0,0),v(0,0,-5),
v(0,-5,0),
]])ohfcs=ob([[
o(1,2,3,n=v(0.57,-0.57,0.57)),
o(1,3,4,n=v(-0.57,-0.57,0.57)),
o(1,4,5,n=v(-0.57,-0.57,-0.57)),
o(1,5,2,n=v(0.57,-0.57,-0.57)),
o(6,3,2,n=v(0.57,0.57,0.57)),
o(6,4,3,n=v(-0.57,0.57,0.57)),
o(6,5,4,n=v(-0.57,0.57,-0.57)),
o(6,2,5,n=v(0.57,0.57,-0.57)),
]])lpts=ob([[
v(0,0,0),
v(0,0,30),
]])lfcs=ob([[
o(1,2,n=v(0,0,-1)),
]])function asteroid_scene()local r3d=threed()local objects={}
local ship=smallship()
return function(t)
t*=0.001
if rnd()<0.6 then
local p=mav(210,rnd())add(objects,{pos=v(p.x*2,p.y*0.6,400),spd=rndf(6,10),model=new_model(ohpts,ohfcs,rndf(1,5)),rotates=true
})add(objects,{pos=v(-p.x*1.3,-p.y*0.4,400),spd=rndf(10,40),model=new_model(lpts,lfcs,rndf(0.2,2)),})end
bg(0)for k,ob in pairs(objects)do
local pos=ob.pos
pos.z-=ob.spd
if pos.z<3 then
del(objects,ob)else
if ob.rotates then
for _,pt in pairs(ob.model.points)do
rotate_vec(pt)end
end
for _,face in pairs(ob.model.faces)do
if (ob.rotates)rotate_vec(face.n)
local px,py=r3d.draw(face,pos)if abs(px)>74 or abs(py)>46 then
del(objects,ob)end
end
end
end
set_palette(22)r3d.render()set_palette()ship()end
end
function new_model(pts,fcs,scl)local points=each(pts,function(p)
return p*(rndf(1,1.3)*scl)end)local faces=each(fcs,function(f)
local face=each(f,function(i)return points[i]end)face.n=f.n*1
return face
end)
return {points=points,faces=faces
}
end
function rotate_vec(pt)local x,y,z=pt.x,pt.y,pt.z
pt.x,pt.y,pt.z=
0.9987*x-0.0493*y+0.0012*z,0.0493*x+0.9975*y-0.0493*z,0.0012*x+0.0493*y+0.9987*z
end
function threed()local faces={}
return {draw=function(face,off)local face_z=0
local projx,projy
local p={}
for i,pt in pairs(face)do
if i~="n" then
local x,y,z=pt.x+off.x,pt.y+off.y,(pt.z+off.z+1)
face_z+=z
local pz=z*0.04
projx,projy=x/pz,y/pz
p[i]={x=64+projx,y=36+projy}
else
if (pt.z>0)return 0,0
p.l=abs(pt.z)*5
end
end
p.l=max(0,p.l-face_z*0.003)if p[3]then
local x1,y1,x2,y2=
p[2].x-p[1].x,p[2].y-p[1].y,p[3].x-p[2].x,p[3].y-p[2].y
if (x1*y2-x2*y1<0)return 0,0
else
face_z=1500
end
face_z=flr(shr(face_z,3))
if (not faces[face_z])faces[face_z]={}
add(faces[face_z],p)
return projx,projy
end,render=function()for z=200,0,-1 do
for _,f in pairs(faces[z]or {})do
if f[3]then
ngon(f,f.l)else
line(f[1].x,f[1].y,f[2].x,f[2].y,0)end
end
end
faces={}
end
}
end
ssfrms=ob([[76,78,108,110,166,]])
function smallship()
local engine=circs(ob([[
o(x=0,y=3,r=4,clr=2),
o(x=0,y=2,r=2.5,clr=8),
o(x=0,y=1,r=2,clr=9),
o(x=0,y=0,r=1.5,clr=10),
]]),1)local pos,tilt=v(56,40),0
local tpos,ttilt=pos,tilt
local prob=0
return function(t)if rnd()<prob then
tpos=v(rndf(26,86),rndf(16,61))repeat
ttilt=rndf(-4.45,4.45)until round(ttilt)~=round(tilt)prob=0
else
prob+=0.001
end
tilt=lerp(tilt,ttilt,0.05)pos=lerp(pos,tpos,0.03)local frm=abs(round(tilt))spr(ssfrms[flr(frm+1)],pos.x,pos.y,2,2,tilt<0)engine(pos+v(6,8),1)end
end
function ski_scene()local slp=72/128
local skiv=v(4,4*slp)local front=hill(slp,36,4,7,0.5)local back=hill(slp,24,2,6,0.25)local b2=hill(slp,16,1,5,0.06)local snows=snow(4,slp)local bgpines=pines(v(2,2*slp),141,1,2,-9,20,0.14)local midpines=pines(skiv,142,2,3,-15,-5,0.08)local fgpines=pines(v(6,6*slp),142,2,3,24,60,0.12)local trails={}
for o in all({v(2,6),v(0,8)})do
add(trails,trail({6,6,6,7,7},16,skiv,o
))end
local sy=37
return function(t)bg(12)b2()local hy,piney=back()bgpines(piney)local py=sy
hy,piney=front()sy=lerp(sy,hy+16,0.3)local dy=sy-py
midpines(piney)snows()for t in all(trails)do
t(v(35,sy))end
spr(136,35,sy,3,2)spr(139,38,sy-dy/0.5,2,2)fgpines(piney)end
end
function hill(slp,cy,spd,c,hld)local y,iy={},cy-64*slp
local refy=cy+64*slp
for x=0,135 do
y[x]=iy+slp*x
end
local cslp,spring=slp
return function()for x=0,127 do
rectfill(x,y[x],x,71,c)y[x]=y[x+spd]-slp*spd
end
local rndd=
rndf(-0.01,0.01)+
(slp-cslp)*0.02*hld+
(refy-y[127])*0.001*hld
for x=128,128+spd do
y[x]=y[x-1]+cslp
cslp+=rndd/hld
end
return y[35],y[128]
end
end
function snow(spd,slp)local s={}
for x=0,127,2 do
add(s,{p=v(x,rnd(x*slp)),v=v(-spd+rndf(-0.2,0.2),-slp+rndf(-0.2,0.2))})end
return function()for _,s in pairs(s)do
if (s.pp)line(s.p.x,s.p.y,s.pp.x,s.pp.y,7)
s.pp=s.p+s.v*0.5
s.p+=s.v
s.v.x+=rndf(-0.01,0.01)
if s.p.y<0 then
s.p,s.pp=v(128+rnd(spd),rndf(0,84))s.v=v(-spd+rndf(-0.2,0.2),-slp*spd+rndf(-0.2,0.2))end
end
end
end
function pines(vel,sp,sw,sh,h,l,prob)local ps={}
return function(y)if rnd()<prob then
add(ps,{p=v(128,y+rndf(h,l)),v=vel+v(0,0)})end
for p in all(ps)do
spr(sp,p.p.x,p.p.y,sw,sh)
p.p-=p.v
if p.p.x<-5 then
del(ps,p)end
end
end
end
function trail(cs,l,d,o)local ps={}
return function(p)add(ps,{p=p,c=cs[flr(rnd(#cs)+1)]})if #ps>l then
del(ps,ps[1])end
for i=1,#ps-1 do
local a,b=ps[i].p+o,ps[i+1].p+o
line(a.x,a.y,b.x,b.y,ps[i].c)
ps[i].p-=d
end
end
end
function robot_scene()local bones=ob[[
o(p=-1,a=0.25,l=0),
o(p=1,a=0,l=13),
o(p=2,a=0.25,l=5),
o(p=2,a=-0.25,l=5),
o(p=3,a=0,l=7),
o(p=4,a=0,l=7),
o(p=1,a=0.35,l=4),
o(p=1,a=-0.35,l=4),
o(p=7,a=0.15,l=8),
o(p=8,a=-0.15,l=8),
o(p=5,a=0,l=6),
o(p=6,a=0,l=6),
o(p=2,a=0,l=5),
o(p=9,a=0,l=8),
o(p=10,a=0,l=8),
]]
local poses=ob[[
o(0),
o(0,0.1,0,0,
0.06,0.06,0.05,0.05,
-0.05,0.2,-0.125,0.125),
o(0,0,0,0,
0.25,-0.25,0,0,
0,0,0.2,-0.2,),
o(0,-0.1,0,0,
-0.06,-0.06,-0.05,-0.05,
0.05,-0.2,0.125,-0.125),
o(0),
o(0,0,0,0,
-0.25,0.25,0.05,-0.05,
-0.05,0.05,-0.25,0.25),
o(0,0,0,0,
0,0,0,0,
-0.2,0.2,-0.2,0.2,
0,0.1,-0.1,),
o(0,0,0,0,
0,0,0,0,
-0.2,0.2,0.2,-0.2,
0,0.1,-0.1,),
o(0),
o(0,-0.1,0,0,
-0.06,-0.06,-0.05,-0.05,
-0.2,0.05,0.125,-0.125),
o(0,0,0,0,
0.25,-0.25,0,0,
0,0,0.2,-0.2,),
o(0,0.1,0,0,
0.06,0.06,0.05,0.05,
0.2,-0.05,-0.125,0.125),
o(0),
o(0,0,0,0,
0.1,-0.1,-0.1,0.1,
-0.15,0.15,-0.2,0.2),
o(0,0,0,0,
-0.25,0.25,-0.1,0.1,
-0.15,0.15,0,0),
o(0,0,0,0,
0.3,-0.3,0,0,
-0.25,0.25,0.3,-0.3),
]]
local sprs=ob[[
o(b=13),
o(b=13,s=169,dy=12),
o(b=12,s=170),
o(b=11,s=168),
o(b=14,s=184),
o(b=15,s=184),
]]
local rbts=ob[[
o(d=v(-32,7),plt=2,f=185),
o(d=v(32,7),plt=2,f=185),
o(d=v(0,0),plt=0,f=185),
]]
local shadowed=ob[[5,6,14,15,]]
local current=ob[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,]]
local spds=set({},current)
local pi=1
local psw=1
return function(t,cam)
draw_dancefloor(pi%2+1)
local sw=stat(20)%8
if sw==0 and psw~=0 then
pi=pi%#poses+1
end
psw=sw
local k=0.02
for i=1,#current do
spds[i]+=((poses[pi][i]or 0)-current[i])*k
current[i]+=spds[i]
spds[i]*=0.88
end
local pts=bones_to_points(v(64,36),bones,current)
feet_plant(pts,62)
local sl,sr=127,0
for i in all(shadowed)do
local px=pts[i].p.x
if (px<sl)sl=px
if (px>sr)sr=px
end
for r in all(rbts)do
local c=r.d+cam
camera(c.x,c.y)
set_palette(r.plt)
rectfill(sl,60,sr,66,0)
spr(190,sl-8,59)
spr(191,sr,59)
ngon({pts[3].p,pts[4].p,pts[8].p,pts[7].p},5)
ngon({pts[1].p,pts[3].p,pts[4].p},13)
draw_bones(bones,pts)
for s in all(sprs)do
local ap=pts[s.b].p
spr(s.s or r.f,ap.x-4,ap.y-(s.dy or 4))
end
end
end
end
function bones_to_points(ctr,bs,pose)
local pts={}
for i=1,#bs do
local b=bs[i]
local parent=pts[b.p]or {p=ctr,a=0}
local ba=parent.a+b.a+pose[i]
pts[i]={
p=parent.p+mav(b.l,ba),
a=ba
}
end
return pts
end
bloffs=ob[[
o(d=v(1,0),c=5),
o(d=v(0,1),c=5),
o(d=v(-1,0),c=13),
o(d=v(0,-1),c=6),
o(d=v(0,0),c=13),
]]
function draw_bones(bs,pts)for i=3,#bs do
local f,t=pts[bs[i].p].p,pts[i].p
for o in all(bloffs)do
line(f.x+o.d.x,f.y+o.d.y,t.x+o.d.x,t.y+o.d.y,o.c)end
end
end
function feet_plant(pts,y)local cy=max(pts[14].p.y,pts[15].p.y)local d=v(0,y-cy)for p in all(pts)do
p.p+=d
end
end
function draw_dancefloor(c)for z=2,0,-0.25 do
for x=-200,216,16 do
floorline(x,36,z,x,36,z-0.2,c)floorline(x,36,z,x+14,36,z,c)c=c%2+1
end
end
end
function floorline(x1,y1,z1,x2,y2,z2,c)local xs1=64+x1/(z1+1)local ys1=30+y1/(z1+1)local xs2=64+x2/(z2+1)local ys2=30+y2/(z2+1)line(xs1,ys1-1,xs2,ys2-1,0)line(xs1,ys1,xs2,ys2,c)line(xs1,ys1+1,xs2,ys2+1,c)pset(xs1-1,ys1,0)end
function title_scene()local n1=moving_noise(58,1,0.05,0.1,-0.01,1,ob([[o(2,50),o(2,100),o(1,150),o(f,256),o(13,256),]])
)
local n2=moving_noise(
58,6,0.05,0.1,-0.01,1,
ob([[o(2,50),o(2,100),o(1,150),o(f,256),o(13,256),]])
)
local n3=moving_noise(
36,11,0.05,0.2,-0.012,1,
ob([[o(5,170),o(f,256),o(5,256),]])
)
local n4=moving_noise(
36,16,0.05,0.2,-0.012,1,
ob([[o(5,170),o(f,256),o(5,256),]])
)
local texts=ob[[
o("music:",32,25,9,0),
o("@gruber_music",96,31,15,1),
o("cover art:",32,39,9,0),
o("@castpixel",96,45,15,1),
o("odds and ends:",32,53,9,0),
o("@krajzeg",96,59,15,1),
o("⬅️ ➡️               ",64,91,13,0.5),
o("  /   switch songs",64,91,5,0.5),
]]
local logo=ob[[
o(3,44,-13,1,3),
o(4,76,-13,1,3),
o(45,52,-13,3,2),
o(171,52,3,3,2),
]]
return function(t)n1:move(1)n2:move(2)n3:move(1)n4:move(1)n1:render(0,inv_rectfill)n2:render(0,dinv_rectfill)set_palette(14)n3:render(0,lrect)n4:render(0,ilrect)set_palette(6)clip()for l in all(logo)do
call(spr,l)end
set_palette()for t in all(texts)do
call(printsh,t)end
end
end
function dinv_rectfill(x1,y1,x2,y2,c)rectfill(127-x1,75-y1,127-x2,75-y2,c)end
function lrect(x2,y1,x1)local d=band(x1,1)local addr=0x6400+shl(y1,6)+band(shr(x1,1),0xffff)local len=band(shr(x2-x1,1),0xffff)+2
memcpy(0x1800,addr,len)sspr(d,96,x2-x1+1,1,x1,y1)end
function ilrect(x2,y1,x1)y1=75-y1
local d=band(x1,1)local addr=0x6400+shl(y1,6)+band(shr(x1,1),0xffff)local len=band(shr(x2-x1,1),0xffff)+2
memcpy(0x1800,addr,len)sspr(d,96,x2-x1+1,1,x1,y1)end
selector=object:extend({pos=1,tgt=1
})function selector:update()self.pos=lerp(self.pos,self.tgt,0.2)if abs(self.tgt-self.pos)<0.005 then
self.pos=self.tgt
end
for btn=0,1 do
if (btnp(btn))self:switch_to(self.tgt+btn*2-1)
end
end
function selector:switch_to(p)p=(p-1)%#screens+1
self.tgt=p
music(screens[p].pat)end
function selector:render()local pos=self.pos
local pi,pf=flr(pos),pos-flr(pos)local left,right=
screens[pi],screens[pi%#screens+1]
local off=flr(-pf*256)local pane_cam=v(-cam.x-off,-cam.y)camera(pane_cam.x,pane_cam.y)clip(off,cam.y,128,72)if off>-128 then
left.fn(t,pane_cam)end
pane_cam.x-=256
camera(pane_cam.x,pane_cam.y)clip(off+256,cam.y,128,72)if off<=-128 then
right.fn(t,pane_cam)end
clip()camera()if pf~=0 then
scene_label(128,pf*128,167-pf*60,right.name)end
scene_label(0,pf*128,107+pf*60,left.name)end
function scene_label(x,dx,dy,name)
if (not name)return
rectfill(16+x-dx,108,111+x-dx,110,1)printsh(name,64,dy,6,0.5)end
function empty_scene(c)
return function(t)bg(c)end
end
cam=v(0,16)function _init()init_palettes(32)init_noise()local scenes=ob([[
o(name=f,pat=63),
o(name="1. into the belt",pat=6),
o(name="2. need for speed",pat=56),
o(name="3. like clockwork",pat=21),
o(name="4. morning shower",pat=0),
o(name="5. robot dance",pat=31),
o(name="6. eyes in the dark",pat=43),
o(name="7. flight of icarus",pat=49),
o(name="8. fickle flame",pat=40),
o(name="9. autumn wind",pat=39),
o(name="10. dimensional gate",pat=13),
]])local fns={title_scene(),asteroid_scene(),ski_scene(),clockwork_scene(),waterfall_scene(),robot_scene(),eyes_scene(),icarus_scene(),flame_scene(),autumn_scene(0.4),gate_scene(),}
screens=each(scenes,function(s,i)s.fn = fns[i]
return s
end)sel=selector()sel:switch_to(1)end
t=0
function _update60()
t+=1
sel:update()end
function _draw()cls()rectfill(0,cam.y-2,127,cam.y-2,1)rectfill(0,cam.y+73,127,cam.y+73,1)sel:render()camera()clip()end
__gfx__
00000000100000110115d711ddddddddddddddddeeeeeeeeeeeeeeee60eeeeeeeeeeeeeea900090a9990a99990a90099eeeee0504aa943334e88233339a93333
1110001051111122115d6721ddddddddddddddddeeeeeeeeeeeeeeee500eeeeeeeeeeeeea90009a90099a90099a90099eeeee050aa992333e88223339a7a9333
22110022422222442249a742ddddddddddd1111deeeeeeeeeeeeeeee0650eeeeeeeeeeeea90009a90099a90099a90990eeeee05049a92333482813339a7aa333
333110353311003e33bbf794d1111dddd111771deeeeeeeeeeeee00e6650eeeeeeeeee00a90009a90099a90099a99900eeeee05049923333482133334a443333
4221104444442298449aa7f9d17711111177711d0000eeeeeeee06606d50eeeeeeeee0dda90a09a90099a99990a99990eeeee050322333333213333334333333
5511105155dd555e5dd9997fd11777711771111d56650eeeeee066d5d510eeeeeeeee0d0a9a999a90099a90099a90999eeeee050333333333333333333333333
6dd5106d6651116e67777777d11177777771111d66dd500eee066ddd5110eeeeeeeee050a99099a90099a90099a90099eeeee050333333333333333333333333
776d10767777777777777777d0111777777711dddddd55100066dddd110eeeeeeeeee050990009099990990099990099eeeee050333333333333333333333333
88221088888888898eee7777dd0111771777711d00eeeeee5dddddddddddddddeeeeeeee0a9990a99990a99999a900990000060e494233333333333333942333
94221099a99999aa9aa77707ddd0111711177711650eeeeed5510ddddddd15d6eeeeeeee00a900a90099a90000a900990000060e4e4423333ffe333333942333
a94210aa7aaaaa77a7777700dddd011711117771d10eeeeedd5d50ddddd066ddeeeeeeee00a900a90099a90000a900990000060e44e42333feeee33399444233
bb3310b3bb1000bebff77700ddddd01a11111aa1110eeeeeddddd50ddd166ddd000000ee00a900a99990a999000999900000060e324423338888223334442133
ccd510cd7ccccccecc777700dddddd1a11111aa100deeeeeddddd51dd566dddd5555550e00a900a90099a9000000a9000000060e332233333822333332421133
d55110d1dd5511dedd66aa00dddddd1a11111aa160eeeeeeddddd55dd566dddd00000d0e00a900a90099a9000000a9000000060e333333333333333333223333
ee8210eeeeeeeeeeeffaa700dddddd199111991150eeeeeedddddd5dd666dddd5555060e00a900a90099a9000000a9000000060e333333333333333333333333
f94210f77ffffffefaa77700dddddd119919991105eeeeeeddddddd56d6ddddd1111060e099990a99990a9999900a9000000060e333333333333333333333333
eeeeeedee3eeee00eeeeee00dddddd111999911005ddddddd55dd00ddddd5ddd0000060ea90099a99999a99900a99990eeeeeeeedddddddddddddddddd11111d
000000000000000000000000dddddd1111111110b050dddd166dd551ddd561dd0000060ea90099a90000a90990a90099eeeeeeeedddd111111111111111eee1d
000000000000000000000000ddddddd11111110d300b05dd66dddd551dd665d10000060ea90099a90000a90099a90099eeeeeeeedddd1eee1e1eee1eee1e1e1d
000000000000000000000000ddddddd1100000dd0b3055dd66dddddd51d6dd5666666d0ea90099a99900a90099a9009900000000dddd1e1e1e1e111e1e18881d
000000000000000000000000ddddddd00dddddddb305055d6dddddddd5ddd5660000001ea90099a90000a90099a9999055555555dddd1888181811181818181d
000000000000000000000000dddddddddddddddd3000b005ddd500dddddddd6d111101ee099099a90000a90099a900000000000011dd18111818881888188811
000000000000000000000000dddddddddddddddd0bb03030dd16651ddddddddd00001eee009999a90000a90099a9000055555555711111111111111111111111
000000000000000000000000dddddddddddddddd300b0050ddd6d5dddddddddd1111eeee000999a90000a99990a9000011111111777717711111111111117771
000eeeeedddddddddddddddd00000000b30b00300b00303beeeeeee0eeeee110eeeee050a900000a99900a9990a9999900000000777717717711111177117711
6550eeeedddddddddddddddd000000003b030b0b30b000b0eeeeee07eeee076deeeee050a90000a90099a9009900a90000000000717717717711771777717711
dd510eeedddddddddddddddd00000000500300035030b030eeeee07deeee0dd6eeeee050a90000a90099a9000000a90000000000711117717711777777717711
dd55000edddddddddddddddd00000000003050b00b303050eeeee06deeee050deeeee05da90000a9009909999000a90066666666a1111aa1aa11aaa11aa1aaaa
ddd55650dddddddddddd0dd000000000b0b5030bb0500305eeeeee0deeee0076eeeeee00a90000a9999900009900a90000000000aa111aa1aa11aa111aa1aa11
ddd55dd5ddddddddd000b00b000000000b00300b300b0000eeeeeee0eeeee06deeeeee10a90000a9009900009900a90011111111aa111aa1aaa1a1111a11aa11
dddd5ddddddddddd0bb030b000000000b00b050000b0b030eeeeee07eeeee06deeeeeee1a90000a90099a9009900a90000000000991119999991911199119911
dddddddddddddddd300b0050000000000b03050350303050eeeeee06eeeeee05eeeeeeeea99999a900990a999000a90011111111999111999911111191119991
eeee5eee000eeeeeeeeeeeeeeeee22eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22100019944444420000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee5000a940eeeeee222200022200eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22210199444222220000000011111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee006609940eeeeee0000220000000eeeeeeeeeeeeee51eeeeeeeeeeeeeeeee22210194442222220000000011111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00065dd1d550eeeeeeeee0002220eeeeeeeeeeeeeeeeed01eeeeeeeeeeeeeeee22210144422222220000000011111111eeeeeee00eeeeeeeeeeeeee00eeeeeee
070dd5651000eeeeeee220000000eeeeeeeeeeeeeeee61000eeeeeeeeeeeeeee11111144222222220000000011111111eeeeee0550eeeeeeeeeeee0550e0000e
060551d11055eeeeee0000e200e000eeeeeeeeeeeeed100000eeeeeeeeeeeeee11110111111111110000000001010101ee0000d10d0000eeeeeee0d10d022200
00e000500eeeeeeeeeeeeee0eeeeeeeeeeeeeeeeee510000001eeeeeeeeeeeee0000000000000000000000000000000000122d6666d22100ee000d6666288880
eeeee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee510000001eeeeeeeeeeeee00000000000000000000000000000000288866655666888200222665566d200e
eeee000eee000eee0000000000000000eeeee41eeed10000001eeeeeeeeeeeee9944442222210001eeeeeeeeeeeeeeee2222d650056d22228888665005d00eee
eee0a9400006000e0000000000000000eeeee10110610000001eeeeeeeeeeeee9442222222221019eeeeeeeeeeeeeeee00000d5005d000002222dd5005d0eeee
000044200715a9400000044442000000eeeeeeeeee011000001eeeeeeeeeeeee4422222222221019eeeeeeeeeeeeeeeeeeeee0d55d0eeeee000000d55d0eeeee
071500000616000000009777ff400000eeeeeeeeeee011000000eeeeeeeeeeee4222222222221014eeeeeeeeeeeeeeeeeeeeee0000eeeeeeeeeeee0000eeeeee
06165d0e001d110e00097f77ff940000eeeeeeeeeeee0000000011eeeeeeeeee2222222211111012eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000d10eeee0d00ee0047ff7fff992000eeeeeeeee5d111000000001eeeeeeeee1111111111111001eeeeff9ff99eefffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee000eeeee000eee0047fffffff94000eeeeeee55111110000000001eeeeeeee0000000000000000eeeffff9ff999fffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee004777ff7f994000eeeeeed111110000000000000eeeeeee0000000000000000effffffffff999ffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee00000eeeeeeeee004fffff7f994000eeeeee6000000000010000000eeeeeeeeeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0776600000eeee002ff77ff7f92000eeeeee00000001000010000000eeeeeeeeeeeeeeeeef99ef080080000a0a0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0dd55d0aa90eee0004f77f7f940000eeeeee000000111000110000000eeeeeeeeeeeeeeefff99f0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeee0ee
00076dd11a990eee00004ff999400000eeeee02000100111000100000000eeeeeeeeeeeeefffff990000000000000000eeeeee00eeee000eeeeee00eee00080e
0706ddd514420eee0000024442000000eeeee020001000110001000011000eeeeeeeeeeeffffffff0000000000000000eeeee05500002880eeee05500028820e
060555110d6d0eee0000000000000000eeee020000d1001100010000010000eef9eeeeeeffffffff0000000000000000eeee0d10d6288220eee0511d6d82200e
e0d0dd550550eeee0000000000000000eeee04000051001100010000001000eef999eeeeffffffff0000000000000000eeee0d6666dd200eeee055666d200eee
ee000000000eeeee0000000000000000eee0400002051001000000000010000efff99f99ffffffff0000000000000000ee0026655dd00eeeeee0d6655d0eeeee
33333333333333330000000000000000ee020000e0051001000000000010000eeeeeeeee000000000000000000000000e0226650050eeeeeee006650050eeeee
33a2223333422243000000000000000000000000e000d0100000100000100000999eeeee1111111109a0a900080008000288dd50050eeeeee0228d50050eeeee
3aaaaa4444aaaaa300000000000000000000000eeeee01000000100000010000f999eeee111111110090900000808000882200d550eeeeee028820d550eeeeee
aa9999aaaa9999990000000000000000eeeeeeeeeee000000000010000000000fff99eee1111111100000000000000000000ee000eeeeeee082000000eeeeeee
99999999999999990000000000000000eeeeeeeeeeee00000000000000000000f9ff99ee111111110000000000000000eeeeeeeeeeeeeeee000eeeeeeeeeeeee
39999999999999990000000000000000eeeeeeeeeeeeeee000000000000000eeff9ff999111111110000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
33339999993999930000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef9ffffff010101010000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
33333333333333330000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeff99ffff000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee666deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeddeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeee66deeeeeeeeeeeee66d6deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8899eeeeeeeeeeeeeeeddeeeeeeeeeeeeeeeeeee
eeeeeee66eeeeeeeeeeeeee666deeeeeeeeeeee666ddeeeeeeeeeee66eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee9988ee88eeeeeeeddddddeeeeeeeee5eeeeeee
eeeeeeee66deeeeeeeeeeeee6d6deeeeeeeeeeee6d6deeeeeeeeeeee66deeeeeeeeeeeeeeeeeeeeeeeeeeeeeedee899e899eeeeeeeddddeeeeeeeee771eeeeee
eeeeeeee666de210eeeeeeee666de210eeeee77e666de210eeeeeeee666de210eeeeeeeeeeeeeeeeeeeeeeeeeedd33983888eeeeeddddddeeeeeee576d1eeeee
eeeeeed11111014411111011111101441111177766110144eeeeeed111110144eeeeeeeeeeeeeeeeeeeeeeeedde333883fffeeeeddddddddeeeeee576d1eeeee
1111101100000144eeee001100000144eeee0077777001441111101100000144eee22eeeeeeeeeeeeeeeeeeeeed533383fffeeeeeddddddeeeeee576dd11eeee
0000000077770022000000007776002200000007776d0022eeee000077770022eeee222deeeeeeeeeeeeeeeeeee35533eeeeeeeeeddddddeeeee566dd1111eee
eeeeeeee767deeeeeeeeeee7776deeeeeeeeeeeedddeeeee000000ee7767eeee22eeed23333eeeeeeeeeeeeeeee333335eeeeeeeddddddddeeeddd5d1d1111ee
eeeeeee766deeeeeeeeee766dddeeeeeeeeeeeeeeeeeeeeeeeeeeeee767deeeee222eee33233eeeeeeeeeeeeeeee33eeeeeeeeeeddddddddeeeee5d77651eeee
eeeeee766deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee766deeeeeeed2223332112eeeeeeeeeeeeeeeeeeeeeeeeeeeeed55deeeeee577766dd1eee
eeeeeeeddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee766deeeeeeeeeed211eed2222eeeeeeeeeeeeeeeeeeeeeeeeeeee55eeeeed5666665dd11ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeeeeeeeeeeeed222eed2222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedd656dd11111e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedd76611eeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee57766dd11eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5776d1d1111ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeeeeeeeee00ee999111111111111111111991eeddd6d11111111e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeee0661eeeeeeeeeeeeee16d0e999101111eeeeeeeee111199eeeed65761111eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0080ee06dd51eeeeeeeeeeee16d5501991d00011eee1eee1111111eeedd77666dd11ee
eeeeeee66ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee02820ee000dd51eeeeeeeeee16d50001111dddd11eee1eee1110111eed6766dd5d1111e
eeeeeeee666de210eeeeeeee666de210eeeeeeee666de210eeee0000028200ee0006d51eeeeeeeeee1dd50001110d111114441444111d000eedd11dd1d11111e
eeeeeed111110144eeeeeed111110144eeeeeed111110144eee05116d8200eee066d51eeeeeeeeeeee1ddd500000d1aa1aa4aaaa4aa1ddddeee1111111111eee
111110110000014411111011000001441111101100000144eee051666d00eeeee0551eeee5eeee5eeee1550eddddd1aa1aa4aa4a4aa1ddddeeeeee4410eeeeee
eeee000077770022eeee000077770022eeee000077770022eee0d6655d0eeeeeee00eeeee1eeee1eeeee00eeddddd11aaa44aa4a4aa111ddeeeeee1110eeeeee
000000ee7767eeee000000ee7767eeee000000ee7767eeeeeee06650050eeeeeeeeeeeeee066d50e00000000ddddd111a144aaaa4aaaa1ddeeeeeeeeeeeeeeee
eeeeeeee776deeeeeeeeeeee776deeeeeeeeeeee776deeeeeee0d650050eeeeeeeeeeeee060d505000000000ddddd01111e44144411111ddeeeee000000eeeee
eeeeeeee767deeeeeeeeeeee767deeeeeeeeeeee767deeeeee028dd550eeeeeeee1111ee5090090500000000dddddd0111ee414ee11111ddeee0000000000eee
eeeeeee766deeeeeeeeeeee7676deeeeeeeeeeee777deeeee02820000eeeeeeeee66ddee5116d11500000000ddddddd011eee1eee11000ddee000000000000ee
eeeeeee76deeeeeeeeeeeee7766deeeeeeeeeeee767deeee008200eeeeeeeeeee6dd555e1d6d5d5100000000dddddddd1eeeeeeeee1dddddee000000000000ee
eeeeeeeddeeeeeeeeeeeeee766deeeeeeeeeeee7776deeee08200eeeeeeeeeeee555555e0d6ddd5000000000dddddddd11111111111dddddeee0000000000eee
eeeeeeeeeeeeeeeeeeeeeee66deeeeeeeeeeeee7766deeeee00eeeeeeeeeeeeeeeeeeeee0500005000000000ddddddddd011111110ddddddeeeee000000eeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee666deeeeeeeeeeeeeeeeeeeeeeeeeeeeee055550e00000000dddddddddd0000000dddddddeeeeeeeeeeeeeeee
4aa944434aa944434aa9444300000000000000004aa94443337aa333337a7a330000000000000000000000000000000000000000000000000000000000000000
aa9929a4aa9929a4aa9929a40000000000000000aa9929a437ee4ae33a779aa30000000000000000000000000000000000000000000000000000000000000000
49a9222149a9222149a92221000000000000000049a92221aea82822a777aa990000000000000000000000000000000000000000000000000000000000000000
49a2a82149a2a82149a2a821000000000000000049a2a821ae242421797a94940000000000000000000000000000000000000000000000000000000000000000
222a9211222a9211222a92110000000000000000222a921134424221a9a449420000000000000000000000000000000000000000000000000000000000000000
2949212129492121294921210000000000000000294921213e8222103a9494420000000000000000000000000000000000000000000000000000000000000000
32442113324421133244211300000000000000003244211333211103394444230000000000000000000000000000000000000000000000000000000000000000
33221333332213333322133300000000000000003322133333330033332442330000000000000000000000000000000000000000000000000000000000000000
4aa944434aa944430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa9929a4aa9929a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49a9222149a922210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49a2a82149a2a8210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222a9211222a92110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
29492121294921210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
32442113324421130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33221333332213330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
33333333333333333333333333333333333333333333333333333333333333333333333333332333333333222222222222222222222222222222222222222222
33333333333333333333333333333333333311111111133333333333333333333333333333332333333333d22222222222222222222222222222222222222222
3333333333333333333333333333333333111dddd111111333333333333333333333333333332333333333d22222222222222222222222221111122222222222
33333333333333333333333333333333111ddddddddd111113333333333333333333333333332233333333dd2222222222111111111111111eee122222222222
333333333333333333333333333333311ddddddddddddd111133333333333333333333333333323333333dddd2222222221eee1e1eee1eee1e1e122221111222
33333333333333333333333333333311dddddddddddddddd111333333333333333333333333332233333ddd111122222221e1e1e1e111e1e1eee122111771222
3333333333333333333333333333331ddccccdddddddddd111113333333333333333333333333322ddddddd177111122221eee1e1e111e1e1e1e121177711222
3333333333333333333333333333311dccccddddddddddddd11113333333333333333cc3333d33322dddddd117777111221e111e1eee1eee1eee111771111222
3333333ddddd333333333333333331ddffccdddddddddddddd1113333333333333333ccc333dd33322ddddd11177777111111111111111111111117771111222
3333dd33ddddd33333333333333311dcffcdddddddddddddddd113333333333333333ccccc33dd33322dddc11117777777177111111111111177717777112222
333dddd333dddddd333333333331111ccccdddddddddddddddd11333333333333333333cccc3ddd3332dddcc1111777777177177111111771177111777711222
333dccddd333ddddd333333333111111ccccddddddddddddddd11133333333333333333ccccccddd3322dddcc111177177177177117717777177111117771122
333dccccddd3333333333333311cddd111ccddddddddddddddd1113333333ccccc33333333cccdddd332dddccc11177111177177117777777177111111777122
3333ccccddddd3333333333311bcddccc111ddddddddddddddd111333333ccccccccc33333ccccdddd322dddccc11aa1111aa1aa11aaa11aa1aaaa11111aa122
bbb33bbcdddddddddd3333311dbdd11cccc111ddddddddddddd11133333ccccccccccc333333ccdddddd2dddcccb1aaa111aa1aa11aa111aa1aa1111111aa122
bbbb33bbddddddddd3333311dddd1111cccccc111ddddddddd111133333cccccccccccccc33333dddddd22ddcccb1aaa111aa1aaa1a1111a11aa1111111aa122
bbbbb333ddddddd333333311ddd111111cccfffdd111ddddd1111133333cccccccccccccccdd333dddddd2ddddbb199911199999919111991199119111991122
bbbbbbb33dddd333d333333111111111111cfffffddd1111111111555555cccccccccccccccdddddccddd222ddbb119991119999111111911199919919991122
bbbbbbbb333333ddd3333333331d111111111fffffdddd111111115dddd55522ccccccccccccddcccccddd222ddb119991111111111111111119911999911122
bbbbbbbbccc3dddd33333333311611111111111dddddddddd11dd14ddddd4dd222ccccccccccd3ccccccdd2322dd11999111111bbbbbbbbb1111991111111222
bbbbbbbbc33ddd33333333333166141111111111111ddddddd1111444dd44444433cccccccccd33cccccdd23322dd11991c11111bbb1bbb11111111111111222
3baabbb333dddd3dddd3333331661441111111111111111111111144444444444433ccccccbbdd33ccccdd22332dd11111ccdd11bbb1bbb11111111111112222
333aa333aabdddddd3333333311114911991111111111111122221444444444444433cccccbbbd333333ddd23322d11111d11111333133311121111222222222
bb3333cccbbdddd3333ddd333116149911114441111111112222144444444444444422cccccbbdd3333dddd2ccc2dd1111d1aa1aa3aaaa3aa122222222222222
bbaa3333cccc3333ddddd33331161499444444441111114121121444444444444444222333333dddddddddd2ccc22dddddd1aa1aa3aa3a3aa122222222222222
bbbaacc333333dddddd33333311114994449944441444411112214444444444444444223333333dddcccccd22ccc2dddddd11aaa33aa3a3aa111222222222222
cbbbbbcbbbbbbcccc3333333311114494449444444444411111214444422444444444422cc33333cccccccdd2ccc22ddddd111a133aaaa3aaaa1222222222222
cbbbbbcccbbbcccc33333333331111444411444444444411221114444442244444444422ccc33333cccccccd2ccbb2ddccc11111b33133311111222222222222
33bbbbcccccccc33333333333313314444414411444444122112444224444444444444225ccccc33cccccccd2ccbb2dccbbc1111bb313bb11111222222222222
3333333ccccc33333bbbcc333311314444444444444444122122444222444444444444225ccccc333ccccc3d2cccc22cbbbcd111bbb1bbb11111222222222222
ccc333333333333bbbbcc33333311144441114444444411211222244224224422444442253cccc333333333d2cccc32cbbbcdd1bbbbbbbbb1332222222222222
cbaaaac33333cccccccc3333333311144441111444444122122222244444224224222222533cc2223333333d2dccc32ccccddd11111111111333222222222222
cbbbbcccccccc33333333333333331141444441444441121122222244444444422255222533cccc223333ddd2dddd322cccddd11111111111333222222222222
cbbbbccc333333333333333333333311111444444411111122222444555444222222522253333cbb22233ddd2dddd332ccddd211111111111332222222222222
ccccccc333333331111113333333331116111444411991122225552222222222244222225333333bb322ddd22dddd332ccddd222222222223322222222222222
3cccc33333331111dddd11113333333116661111119911122222222222224442442222215333333333322dd2dddddd322cdd2222222222333322222222222222
3ccc333333111dddddddddd11133333171166ccc11111112222222222552244222222231cccbbb3333332d22dddddd332dd22222222233333222222222222222
33333ccc111dddddddddddddd1133311771111111c555122222244422255244422222235ccbbbccc3333222ddddddd3322222222222333333222222222222222
b333ccc111ddd11ddddddddddd11111777716611cc555122222222222222222222222255cbbcccccc33332233ddddd3322222222222333333222222222222222
bbcccc1111dd11ddddddddddddd1661177716ccccc55512222222222222222244422221ccccccccccccc332333dddd3322222222222333333222222222222222
3bbccc11111ddddddddddd11ddd1166117716ccccccc511222222222222222224422211cccccccaaaaccc32233dddd3322222222222333333332222222222222
333331111111ddcddddd111ddddd1666117166cccccc51112222222222222222222221ccccaaaaaaaaaacc3233dddd3322222222222333333333222222222222
c3333111111111ccdddddddddddd16666111666ccc1111111122222222222222222511cccaabbbbbbbbccc3223ddd33322222222222333333ddddd2222222222
ccc33111111ff11c99dddddddddd166667711111111ccc11111222222222222222555ccccbbbbcccccccccc32dddd3322222222222222dddddddd55222222222
33cc311111fff11cccccccccddd11116677777ccccccccccb1111112222222252211333cccccccccccc3333322dd333222222222222222ddddddddddd2222222
833333111ffff111ccccccddd222d1116777777ccccccccbbb1ddd1112222225555ccccc33aaaaaabbcccc3332d3332222222222222222222ddddddddd222222
8833311fffffff11ddddccd222ddddd111177777cccccccbbb1ddddd11222211133cccc33aaabbbbbbbbccc332d3322222222222222222222222dddddddd2222
888811fffff66f1111111111ddd11cc166111111cccccc999b122dddd111111333cccc33aabbbbbbbbbbbcc332232222222222222222222222ddddddddddd222
88811ffffff6fff111111111cccccc116666666111111111111ccccddd113333bbbcc33cbbbbbb3332bbbbb3332222222222222222222222ddd2222ddddddd22
8811ffffff666fff6666666111ccc11d6666666666ccccccc1cc11cdddd1133bb33333ccbbbbb33aa22bbbbb3322222222222222222222ddd222222dddddddd2
811f777fff66666f666666666111117ddd66666666666cccd1cccccddddd13333333bbccbbbb33aabb2bbbbcc3222222222222222222dddd22222dddddddddd2
117777777666666666661666667777777ddd66666666666dd11dddddcdd51133333bbccccbbb3aabbb2bbbcc33222222222222222222ddd22222ddddddd22222
1777777776666d66ddd11666777777711111111166666ddd6611111ccdd511333bbbcccc33b33aacaa2bbbcc33c2222222222bb22222dd22222ddddddd222222
777777dd66776ddddd11666777777711ddddddd11ddddd666666661ccd1511333bccc33333b3bbccaa2bbbcc33c222222222bbbb2222ee2222eeddddd2222222
7777fffdddd7dddd111566677777711dddddddd1116666666666661cc5151133cc3333ccccc3bbcaac22bbcc33c2222222233bbb2222eee222eeeeeee2222222
77fffffffddddd1115556677777771ddd11dddd1111666111111661cc555113333333cccccc3bbbbbcc2bcc3333222222233bbbb22222eeeeefffffeeee22222
777fffffff11d11d55566677777711dd11dd11d11111661aaae1111cc15111333333ccccccc3bbbbbbc22ccccc32222222bbbfb222222222eeffffffeeeeeee2
77777777777111dd5556667777771dd11cc11dd11111111aeeeee111c111113333ccccccccc3bbbbbbba2cccccc2222222bbaab222222222222eeeefffeeeeee
77777777777711d55566667777711d11cc11ddd1ffeeeeaaeeeeeaa111111333333cccccc3333bbbbbba22ccccc2222222333aa2222222222222eee2222eeeee
7777777777777111556666777771dddcc11dddd1111eeeeeeeeeeaaaa11133333333333333c33bbbcc33222cccc22222233c33c2222222222222eee222222eee
7777777777777771156666777771dddddddddddddd11eeeeeeee4444444111333333333333c33bbb333fff2cccc22222233cbbcc2222222222222ee2222222ee
7777777777777777111666677771ddddddddddddddd1eeeeeeee44444442e1113333333333333bb33bbbf322cccc22222b333bbc2222222222222e99222222ee
77777777777777776611116667711ddd222222ddddd11eeeeeeaaaaaaa22eee11133333333333333bb3333f2cccc22222bbb3b3c22222222222222999222222e
ffffffff7777777666f66222222222222444422ddddd1eeeeeeaaaaaaa2eee44d1133aac3333333bb33bbff22cccc2222bb33333222222222222222299222222
fffffffffff77ff66fffdd44444422244444442211dd11eeee444444422eee4ddd13caacc333323333bbbf22222332222b35ccc3222222222222222229922222
222ffffffffffffddffdd444444444444111122211ddd1eeee44444442eee44ddd11ccaaccccc233b3bbb22222ff33325335cbbb222222222222222222992222
88222fffffffffdddffd44444444444442ddd62211ddd14eeaaaaaaa22eee4ddddd1cccbbccbc23bb3bb22b22fffff333355cbbb222222222222222222292222
8888222fffffffddffdd444444444444422d661111ddd14eeaaaaaaa2eeeddd1111133ccccbb322bb3bb2bb2bb22222ff3333bb2222222222222222222292222
888888222fffffddffd4444444444444442211111ddd114e444444422eee4d11ccc11333ccb33b2233333b32222f22ffcc333332222222222222222222992222
888888882222ffddffd4444444444444444251111ddd144e44444442eee44d1777111c333333bbc2c3333b322fff2cbbcc22222222222277777aa99999922222
88888888888222222fd444444444444442415555ddd114eeaaaaaa22eee4d11771181cc3ccc3bbc3cbb333323cc22cbb222ffffa222227722222222222222222
8888888888888888222444444444441142211155ddd144ee444aaa2eee44d15551281cc3ccc33bb3ccc3a33333c2ccb22c99f77aaa2277222222222222222222
88888888888888822d222224444444411221111111114eeeee44422eee4dd15551211cc3cc22222222c3aa3333323332cccccb7aaa2277222222222222222222
88888888888888223ddddd22224444441111d11144444eeeeeeeeeeee44dd11661111cc2cc2cc33332233aabb2222222ccccbbbaaaa272222222222222222299
888888888888822333dddd11111111221dddd111eeeeeeeeeeeeeeeee4dddd111111ccc2cc223334333323bbbb333322ccc3bbbbaaa27c222222222222299999
888888888888823333dddd112dd111111dddddd122eeeeaaeeeeeeee66dddddd111cccc22ccbbc941111222bbbb333322cc222222222ac22222222777aaa9222
8888888888222233336ddd12222211ddddddddd14222eaaeeeeee99e4dddddd1111ccbbb33c2bc911a1322222bcc23cc233cc99999aaaccc2222277222222222
88888882222b33333366dd1111111dddddddddd1444222eeeeeeee444dddddd1111ccbbaa332acc811132322cbcc2cccc33cccfffaa7a99c2222272222222222
88882222c33bb3333336ddddddddddddddddddd114444222eeee4441dddddd11111ccbbbaa32abc8ceee233cccc22222cc3bbccc9977aa9c3322272222222222
88222bbccc3bbb3333366dddddd222222222d2221114444222224551dddddd111111ccccccc22bbbccc223ccccc299933c3bbbccc33aa3333cc2277222222222
822bbb33cc33bb333336ffffdd22ddddddd222dddd111444442555511dddb11111111cccccc2222222222cecccc229aa333bbbc333aa93333ccc227222222222
223bbbb33bb3bb333336ffffdd2dd4114d224ddddddd1114442155551ddbb11111111cccbbca222222bbbeeecccc22aaab333bb3aaa99aabbbcc227222222222
9933aabc3bbc33333333fffffd2d44114d224dddd11ddd111441555511bb1111111155cbbaaaaa3bbaaaeeeeeecc222aabbb33bbaab997aabbb3227222222222
99733aac3cccc3333133ffffff2444444d224dddd11ddd141111155551111111555555cbaaaaac33bbb9993333ccc22222bbbbb77bbb977aabb3277222222222
77773aacccccc3333133ffffff99422222222222dddddd1444441111111111155555551bbbbbccc333bbb33bb33cc3222222ccb7bbbb99aaab33222222222222
fff439ccccccc33311336fffff22222444422dd222222114411442dd1111111555555111bbbbccccc33333bbbb3333a2211222b7bbbbb99a9b32222222222222
444439333333331113366fffff29994444422ddddd444412222222dd3b1111155555ddd1bbbbbbbbccbbbbbbbbb333aa229992273bbbb999923e222222222222
21111333111111111336ffffff22994444dd2ddddd44441ddddddddd3b1111155555ddd11bbbbbbbbbbbbbbbbbbbabbaaeee7722339999ee22eeb22222222222
118811311111111133d6fffffff29994dddd2dddddd44ccccccddddd3bb1111555555dd51cbbccccbbbbbbbbbbbbaabbbbb77aa22339eeee2eeeb22222222222
888881111111111333d6fffffff2999999dd2dddccccccdddddd11dd3bb11115555555551ccccccccccccccbbbbbbaaa77aaaaaaaa33eee82eebb22222222222
8888888888882233332222222222299999dd66cccdddddddddddd11d33bb1115555555511ccccccccccccccbbbbaaaaaa77aa9999bbb88e82eebbb2222222222
94444444888223ccc32ddddddddd222222266dddddddd2222222dd1dd3cc1115555d51111ccccccccccccccbbbbbaaaaaaaaaaa9999bb888eeebbb2222222222
777ff44448223333cc2ddffdddddddddd1ccdddddd2222ddddd22d11d3ccc11155dd111dddccccccccccccccccbbbbaaaaaaaaaaa999bbbbeeebbb2222222222
77777444222bccc33c2dfffdddddddddd1dddddd222ddddddddd2dd1d33bcb11111111ddd1ccccccccccccccbbbbbbbbbbbaaaaaaaa9aaaaeeeebb2222222222
777777422cbbbbcc3c2dffddddddddddd1ddddd22ddddddddddd22d1dd3bbbc1111115dd111ccccccccccccbbbbbbbbbbbbbbbbaaaaaaaaaaaeebb2222222222
77777722bbbbbbcc332dffddddddddd441dccdd2ddddddddddddd2d11d33ccca11115551122444cccccccccbbbbbbbbbbbbbbbbbaaaaa77aaaeebbb222222222
77777223bbb33acc332dddddddddddd441dccdd2ddddddddddddd2dd1dd3bbaaa1115511222444444cccccccbbbbbbbbbbbbbbbbbbaaa777aaaebbb222222222
77777233b9aa33cc33111dddddddddd441dccdd2ddddddddddddd2dd1dd3bbaaaa11111222244444444c4442bb5555bbbbbbbbbbbbbbaa77aaabbbb222222222
7777722229aaa3cc3211111111111dd441dccdd22dddddddddddd2dd1112bbaaaab111222224444444444422cb55555bbbbbbbbbbbbbbb77aabbbbb222222222
7777229922aaabc3321ccddddddd111111ddcddd2ddddddddddd22dd1dd22bbbbbb11222222244444444422ccc55bb55bbbbbbbbabbbbbbbbbbbbbb222222222
7777299992299bc3221ccdddddddddddd11dcddd22dddddddd222ddd1ddd2bbbbccccc244222244442222222211555555bbbbbaaabbbbbbbbbbbbaaa22222222
777229ffff299cc3211cdddddddddddddd11ccddd222ddd2222ddddd1ddd22bbbcccca244442222211dd2ddd221155555cbbbaaabbbbbbbbbbbbbaaaa2222222
777299777f29ccc321ccddddddddddddddd11cddddd22222dddddd111dddd22bccbbaa22444421111dd2222c222115555cccbbbbbbbbbaaaaabbaaaaaa222222
77229777442ccc2321cddddddddddddddddd11ddddddddddddd1111ddddddd2cccbbb332244421122222cc2c222211c55cccbbbccbbbbaaaaabbbaaaaa222222
77299744442cc2212ccdddddddddddddddddd111ddddddd11111dddddddddd22ccccc332222221222d2dcc2ddd222cc55cccbbccbbbbbbbbbbbbbbbaaaa22222
77294444112cc2112ccdddddddddddddddddddd111111111ddddddddddddddd2ccccc33322222222dd2dd2222d224c555ccccbbbbbbbbbbbbbbb22bbaaa22222
77294111112331192dd222222222ddddddddddddddddddddddddddddddddddd22cccc33332222222cd2d22d22d244c55ccccbbbbbabbbbbbbbbbb22bbabb2222
77291111f223119922222dddddd2222ddddddddddddddddddddddddddddddddd2cccc33333222d22c2222dd2222ccccccccbbbbbaaabbbaabbabba2bbbbc2222
772911ffff11199222dddddddddddd222ddddddddddddddddddddddddddddddd2ccccc3333332d2222dd2dd224333cccccbbbbbaaaabbbaabbabba22cccc2222
77221ffffff99992dddddddddddddddd222ddddddddddddddddddddd222ddddd2888ccc3333322222ddd2d224423333ccbbbbbba77bbbbaabba2baa2cc222222
77722fffffff9992dddddddddddddddddd222dddddddddddddddd22222dddddd28888ccc333322222d222224422cc222222ccbbb77bbbba7bba2bbb22c222222
77777777ffff9992dddddddddddddddddddd22dddddddddd222222222ddddddd188888cc333332222222242222cccc334422cccbbbbbbaa7bba2bb2222222222
77777777fffff992ddddddddddddddddddddd2222222222222222222dddddddd1188888cc33333244424442ccccccc33f9922222bbbbbaacbbc2cc2222222222
777777777ffffff2ddddddddddddddddddddd552222222222222222ddddddddd51888888cc3333222222222ccccccc3fff22cc32222bbbcc2cc2222292222222
777777777ffffff2ddddddddddddddddddddd55522222222222222dddddddddd5118888888333333333ccccccccccc3ff22ccc3f992222222222c22992222222
7777777777fffff2dddddddddddddddddddddd555112222222222ddddddddddd5518888888833333333ccccccccccc3322ccc33f922cc2222cccc29922222222
777777777777fff2dddddddddddddddddddddd5555111122111ddddddddddddd5518888888833333333cccccccccccccccccc3ff22ccccccccccc24444222222
777777777777fff2ddddddddddddddddddddddd55511111111dddddddddddddd55118888888333333333ccc33cccccccccccc3322cccccccccccc24444444222
777777777777fff2ddddddddddddddddddddddd5551111111dddddddddddddd555118888883333333333ccc333ccc33cccccccccccccccccccccc24444444442
777777777777fff2ddddddddddddddddddddddd5551111111dddddddddddddd551111888883333333333cc333ccc333cccccccccccccccccc3ccc28444444444
77777777777ffff2ddddddddddddddddddddddd555111111dddddddddddddd55111118888333333ccc33c3333333333cccccccccccccccccc3ccc28844444444
7777777777fffff2ddddddddddddddddddddddd555111155dddddddddddddd111ddd11888333cc33c33333333333333cccccccccc3ccccccc3ccc28884444444
7777777777ffffff2dddddddddddddddddddddd555111155dddddddddddd111ddddd118888888883333333333333333cccccccccc3ccccccc3ccc28888444444
777777777fffffff2dddddddddddddddddddddd555111155ddddddddd1111ddddddd118888888883333c33333333333cccccccccc3cccccc33ccc28888844444
777777777fffffff22222222221111dddddddd5555111115dddddd1111dddddddddd11888888888833cc3333333333cc33ccccccc3cccccc3cccc28888884444
777777777ffffffff22ccdddddddd1111dddd555551111111111111dddddddddddd11199999998888cc33333333333c33ccccccc33cccccc3cccc28888884444
77777777fffffffff2cccddddddddddd111dd555551111111ddddddddddddddd11111199999999988823333333333333cccccccc3cccccc33ccc228888884444
7777777ffffffffff2cccddddddddddddd111555551111ddddddddddddddd1111dd11199999999988822333333333333ccccccc33cccccc3cccc288888888444

__map__
0500000000000000000000000000000000000000000000000000000000000000082c2c180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26300500000006050000000000000000000000000000000000000000000000000c00001c0000000000bc0000000000ac0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16262715003616313005000006050000000000000000000000000000000000000c00001c0000bcacbcbbbcac00bcacbb00bcac00bcac0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
27171607003717162627153727263005000000000000000000000000000000000c00001c0000bbbbbbbbbbbbacbbbbbbbcbbbbbcbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1716261500362732322607361716262700000000000000000000000000000000383c3c280000abababababababababababababababab0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3232271500373234342515373232321700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3435250700363435353415363435342500000000000000000000000000000000000000000000bdbfbfbe0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535341500363435343507363535343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005a69786800000000005a68000000000000000000005a5b69785b5b6800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b797979794b4b797979794b7979794b4b797979794b4b794b4b4b794b797979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
013d00200a6100f611156111c6112c6113161131611236111b6110d6110d6110c6110b6110a621096110861107611096110b6110161106611076110f611186111c61125611256111c61116611126110d61109611
0108080a1307014070180701806018050180401803018020180141801500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b0809245701d5701c5701c5601c5501c5401c5301c5201c5100050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010200280c31500000000000000000000000000f2250000000000000000c3000c415000000000000000000000c3000000000000000000c30000000000000741500000000000c2150000000000000000c30000000
010300280000000000246250000000000000000000000000246150000000000000000c30018625000000000018000180002430018000180001800024300180001800018000000000000000000000000000000000
011000010017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01090004180701a07015070160700c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c000000000000000000000000000000000
0109000418070160701307011070295052650529505265052d505295052950526505225051f5051d505215052e5052b50528505245052d5052d5052850528505265052e5052b5052850524505215051d50521505
0114000020734200351c7341c0351973419535157343952520734200351c7341c0351953219035147341503121734210351c7341c0261973419035237341703521734395251c7341c03519734195351773717035
011400000c043090552072409055246151972315555090550c053090651972309565207242461509065155650c053060652072406065246151672306065125650c05306065167230656520724246150606515555
011400000c053021651e7240206524615197450e7650c05302165020651e7341e7350256524615020650e56501165010651e7240c05324615167230b0450d0650c05301165197440b56520724246150106515555
0114000020724200251c7241c02525742287421572439525207242a7422c7412c7322c72219025147242a74228742287451c7341e7421e7421e735237241702521724395251c7341c03519734195351773617035
0014000020724200251c7241c02525742287421572439525207242a7422c7412c7322c72219025147242f7422d7422d7452d734217422174221735237241702521724395251c7341c03519734195351773617035
0116002006055061550d055061550d547061550d055061550d055060550615501155065470d15504055041550b055041550b547041550b055041550b0550b155040550b155045460b1550b055041550b0550b155
010b00201e4421e4321f4261e4261c4321c4221e4421e4321e4221e4221f4261e4261c4421c4321c4221c4221c4221c4221c4221c4221c4221c4221c4221c4221c4221c4221c4221c42510125101051012510105
011600001e4401e4321e4221e4250653500505065351a0241a025065351a0250653500505065351902419025045351702404535005050453500505045351e0241e025045351e0240453504535005050453504535
010b00201e4421e4361f4261e4261c4421c4421a4451c4451e4451f44521445234452644528445254422543219442194322544225432264362543623442234322144221432234472343625440234402144520445
01160000190241902506535135000653500505065351a0241a025065351a0250653506404065351902419025045351702404535005050453500505045351e0241e025045351e0240453504535005050453504535
010e000005455054553f52511435111250f4350c43511125034550345511125182551b255182551d2551112501455014552025511125111252025511125202550345520255224552325522455202461d4551b255
010e00000c0530c4451112518455306251425511255054450c0530a4353f52513435306251343518435054450c053111251b4353f525306251b4353f5251b4350c0331b4451d2451e445306251d2451844516245
010e00000145520255224552325522445202551d45503455034050345503455182551b455182551d455111250045520255224552325522455202461d4551b255014550145511125182551b455182551d45511125
010e00000c0531b4451d2451e445306251d245184450c05317200131253f52513435306251343518435014450c0431b4451d2451e445306251d245184451624511125111253f5251343530625134351843500455
010e0000004550045520455111251d125204551d1252912501455014552c455111251d1252c4551d12529125034552c2552e4552f2552e4552c2552945503455044552c2552e4552f2552e4552c246294551b221
010e00000c0530c0531b4551b225306251b4551b2250f4250c0530c05327455272253062527455272251b4250c0531b4451d2451e445306251d245184450c0530c0531b4451d2451e445306251d2451844500455
010d00000c0530445504255134453f6150445513245044550c0531344513245044553f6150445513245134450c0530445504255134453f6150445513245044550c0531344513245044553f615044551324513445
010d000028555234452d2352b5552a4452b2352f55532245395303725536540374353b2503954537430342553654034235325552f2402d5352b2502a4452b530284552624623530214551f24023535284302a245
010d00002b5552a4452823523555214451f2351e5551c4452b235235552a445232352d5552b4452a2352b555284452a235285552644523235215551f4451c2351a555174451e2351a5551c4451e2351f55523235
010d00000c0530045500255104453f6150045510245004550c0530044500245104553f6150045510245104450c0530045500255104453f6150045510245004550c0531044510245004553f615004551024500455
010d00000c0530245502255124453f6150245512245024550c0531244512245024553f6150245502255124450c0530245502255124453f6150245512245024550c0530244512245024553f615124550224512445
010d00002b5552a45528255235552b5452a44528545235452b5352a03528535235352b0352a03528735237352b0352a03528735237351f7251e7251c725177251f7151e7151c715177151371512715107150b715
010c00200c0530c235004303a324004453c3253c3240c0533c6150c0530044000440002353e5253e5250c1530c0530f244034451b323034453702437522370253c6153e5250334003440032351b3230c0531b323
010c00200c05312235064303a324064453c3253c3240c0533c6150c0530644006440062353e5253e5250c1530c05311244054451b323054453a0242e5223a0253c6153e52503345054451323605436033451b323
010c00202202524225244202432422425243252432422325223252402522420242242222524425245252422522325222242442524326224252402424522220252452524524223252442522227244262432522325
010c0000224002b4202e42030420304203042033420304203042030222294202b2202e420302202b420272202a4202a4222a42227420274202742025421274212742027420274202722027422272222742227222
010c00002a4202a4222a422274202742027422272222742527400254202a2202e4202b2202a426252202a4202742027422274222442024222244222242124421244202442024420244202422024422182210c421
011100000c3430035500345003353c6150a3300a4320a3320c3430335503345033353c6151333013432133320c3430735507345073353c6151633016432163320c3430335503345033353c6151b3301b4321b332
01110000162251b425222253751227425375122b5112e2251b4352b2402944027240224471f440244422443224422244253a512222253a523274252e2253a425162351b4352e4302e23222431222302243222232
011100000c3430535505345053353c6150f3301f4260f3320c3430335503345033353c6151332616325133320c3430735507345073353c6151633026426163320c3430335503345033353c6150f3261b3150f322
011100001d22522425272253f51227425375122b5112e225322403323133222304403043030422375112e44237442372322c2412c2322c2222c4202c4153a425162351b4352b4402b4322b220224402243222222
011100001f2401f4301f2201f21527425375122b5112e225162251b5112e2253a5122b425375122b5112e225162251b425225133021033410375223341027221162251b425222253751227425373112b3112e325
01110000182251f511242233c5122b425335122b5112e225162251b5112e2253a5122b425375122b5112e225162251b425225133021033410375223341027221162251b425222253751227425373112b3112e325
011100000f22522425272253f51227425375122b5112e2252724027232272222444024430244222b511224422b4422b23220241202322023220420204153a425162351b4351f4401f4321f2201d4401d4321d222
007800000c8410c8410c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c84018841188401884018840188401884018840188402483124830248302483024830248302483024830
01780000269542694026930185351870007525075240752507534000002495424940249301d5241d7000c5250c5242952500000000002b525000001d5241d5250a5440a5450a5440a5201a7341a7350a0350a024
017800000072400735007440075500744007350072400715007340072500000057440575505744057350572405735057440575503744037350372403735037440375503744037350372403735037440373503704
017800000a0041f734219442194224a5424a5224a45265351a5341a5350000026934269421ba541ba501ba550c5340c5450c5540c555000001f9541f9501f955225251f5341f52522a2022a3222a452b7342b725
0110002005b4008b3009b200ab3009b4008b3006b2002b3001b4006b3006b2003b3002b4003b3005b2007b3008b4009b300ab200ab300ab4009b3008b2007b3005b4003b3002b2002b3002b4002b3004b2007b30
0118042000c260cc260cc2600c2600c2600c260cc260cc260cc2600c2600c260cc260cc260cc2600c2600c260cc2600c2600c2600c260cc260cc260cc2600c260cc2600c260cc260cc2600c260cc260cc2605c26
012000200cb200fb3010b4011b5010b400fb300db2009b3008b400db500db400ab3009b200ab300cb400eb500fb4010b3011b2011b3011b4010b500fb400eb300cb200ab3015b4015b5015b4015b300bb200eb30
012c002000000000000000000000000000000000000000001372413720137201372015724157201572015722137241872418720187201872018720187201872018725187021a7241c7211c7201c7201c7201c720
012800001c7201f7241f7201f7201f7201f720157241572015720157201572015720157201572215725000001c7241c7201c7201c7201c7201f7241f7201f7201f7201f722157241572015720157201572015720
012800001572015725000001f7241c7241c7201c7201c7201c7201c72215724137211372013720137201372013720137221872418720187201872018720187201872018720187201872218725187001870018705
012000000dd650dd550dd450dd351075510745107351072500c5517d5517d4517d3517d2517d2510755107450dd650dd550dd450dd351075510745107351072500c5417d5517d4517d3517d2517d250dd250dd35
011d0c201072519d5519d4519d3519d251005510045100351002517d550f7350f7350f7250f72510725107251072519d3519d3519d2519d250b0250b0350b7350b0250b7250b72517d3517d350f7350f7350f725
0120000012d6512d5512d4512d351575515745157351572500c5510d5510d4510d3510d2510d25157551574512d6512d5512d4512d35157551574500c54157351572519d5519d4519d3519d2519d250dd250dd35
011d0c20107251ed351ed351ed351ed251503515035150251502517d35147351472514725147251572515725157251ed351ed351ed251ed2515025150351573515025157251572519d3519d350f7350f7350f725
0120000019d5519d450dd3501d551405014040147321472223d3523d450bd350bd551505015040157321572219d5519d450dd3501d551705019040197321972223d3523d450bd350bd551c0501e0401e7321e722
012000001ed551ed4512d3506d552105021040217322172228d4528d3528d2520050200521e0401e7321e7221ed551ed4512d3506d552105021040257322572228d5528d4528d3528d251c0401e0301e7221e722
0112000024e4524e3521f251ff351ff451de3524f2524f3518e451de351fe251d73018e251de351fe451d7321ff4521f3524f252973029e252be352ee4524e3524e2524e3521f451ff351ff251de352473224f35
0112000024e2524e35219451ff352192524e3524e4524f3526f2526f351fe451d73232f4532f352be25297322bf252bf352df253573235e2537e353ae4530e3530e2530e352df452bf352bf2529e253073230f35
011200002de252de352af4528f3528f2526e352df452df3521e2526e3528e452673221e3526e2528e352673228f252af352df253273232e3534e2537e352de252de352de252af3528f2528f3526e252d7322df35
011200000a0550a0350a0250a0550a0350a0250a0550a0350a0250a0550a035050250a0550a0350a0250a0550a035050250a0550a0350a0250a0550a035050250a0550a035050250a0550a035050250a0550a035
011200000505505035050250505505035050250505505035050250505505035000250505505035050250505505035000250505505035050250505505035000250505505035000250505505035000250505505035
011200000705507035070250705507035070250705507035070250705507035020250705507035070250705502035020550205502035020250205502035090250205502035090250205502035090250205502035
__music__
00 08094344
00 080a4344
00 0b094344
00 0c0a4344
00 0b094344
02 0c0a4344
01 12134344
00 12134344
00 12134344
00 12134344
00 14154344
00 14154344
02 16174344
01 18424344
00 1b424344
00 1c424344
00 18424344
00 181a4344
00 1b1a4344
00 1c194344
02 181d4344
00 1e424344
00 1f424344
01 1e204344
00 1f204344
00 1e204344
00 1f204344
00 1e214344
00 1f224344
00 1e214344
02 1f224344
00 23424344
00 23424344
01 23244344
00 23244344
00 25294344
00 25264344
00 23274344
02 23284344
03 2a2b2c2d
01 2e2f3031
00 2e2f3032
02 2e2f3033
01 34354344
00 34354344
00 36374344
00 34384344
00 34384344
02 36394344
00 0d117f44
01 0d117f44
00 0d0e7f44
00 0d0e7f44
00 0d107f44
00 0d107f44
02 0d0f7f44
01 3d3a4344
00 3e3a4344
00 3d3b4344
00 3e3a4344
00 3f3c5344
02 3f3c5344
00 7e7f5344
00 7e7f5344

