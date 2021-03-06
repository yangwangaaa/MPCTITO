%SISO example of GPC simulation with constraints
%%  ay = bu is the model
a=[1 -0.8];
b=[0.1,0];
Tfilt=[1 -0.8];
ny=10;  %% prediction horizon
nu=2;   %% input horizon
Wu=1; %%% weights on input
Wy=1;  %% weights on output
Dumax=0.5;  %% input rate limit
umax=3;   %% max input
umin=-2;
ymax=4;
ymin=-0.4;
sizeu=1; 
ref=[zeros(1,10),ones(1,25)];  %% target
dist=ref*0;   %%% output disturbane signal
noise=ref*0;  %% measurement noise

[y,u,Du,r] = mpc_simulate_tfilt(b,a,Tfilt,nu,ny,Wu,Wy,Dumax,umax,umin,ref,dist,noise);


