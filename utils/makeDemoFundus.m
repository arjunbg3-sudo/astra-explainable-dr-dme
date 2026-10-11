function I=makeDemoFundus(H,W,seed)
% MAKEDEMOFUNDUS Generate a synthetic fundus-like image for software testing.
rng(seed);
[x,y]=meshgrid(linspace(-1,1,W),linspace(-1,1,H));
r=sqrt(x.^2+y.^2);
fov=double(r<0.92);
illum=0.25+0.75*exp(-1.8*r.^2);
base=0.15+0.55*illum;
R=base.*(0.9+0.12*rand(H,W));
G=base.*(0.55+0.10*rand(H,W));
B=base.*(0.42+0.08*rand(H,W));

% Vessels.
for k=1:26
    x0=rand*1.4-0.7; y0=rand*1.4-0.7; ang=rand*2*pi;
    len=0.4+0.6*rand; width=0.004+0.006*rand;
    d=abs((x-x0)*sin(ang)-(y-y0)*cos(ang));
    along=(x-x0)*cos(ang)+(y-y0)*sin(ang);
    m=(d<width)&(abs(along)<len)&(r<0.9);
    R(m)=R(m)*0.45; G(m)=G(m)*0.50; B(m)=B(m)*0.55;
end

% Optic disc.
dc=[-0.48,-0.05];
disc=((x-dc(1)).^2+(y-dc(2)).^2)<0.055^2;
R(disc)=0.95; G(disc)=0.88; B(disc)=0.72;

% Foveal darkening.
fovc=[0.12,0.03];
fovspot=exp(-((x-fovc(1)).^2+(y-fovc(2)).^2)/(2*0.018^2));
R=R.*(1-0.45*fovspot); G=G.*(1-0.45*fovspot); B=B.*(1-0.35*fovspot);

% A few synthetic lesions for pipeline visualization.
for k=1:22
    cx=rand*1.1-0.4; cy=rand*1.1-0.55; rr=0.003+0.006*rand;
    lesion=((x-cx).^2+(y-cy).^2)<rr^2;
    if rand<0.6
        R(lesion)=0.15; G(lesion)=0.04; B(lesion)=0.04;
    else
        R(lesion)=0.95; G(lesion)=0.90; B(lesion)=0.65;
    end
end

I=uint8(255*cat(3,R,G,B).*fov);
end
