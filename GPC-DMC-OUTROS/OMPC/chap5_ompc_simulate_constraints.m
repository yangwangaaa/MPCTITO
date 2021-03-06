%%% Simulation of dual mode optimal predictive control
%%%
%%  [J,x,y,u,c,KSOMPC] = chap5_ompc_simulate_constraints(A,B,C,D,nc,Q,R,Q2,R2,x0,runtime,umin,umax,Kxmax,xmax)
%%
%%   Q, R denote the weights in the actual cost function
%%   Q2, R2 are the weights used to find the terminal mode LQR feedback
%%   nc is the control horizon
%%   A, B,C,D are the state space model parameters
%%   x0 is the initial condition for the simulation
%%   J is the predicted cost at each sample
%%   c is the optimised perturbation at each sample
%%   x,y,u are states, outputs and inputs
%%   KSOMPC unconstrained feedback law
%%
%%  Adds in constraint handling with constraints
%%  umin<u < umax   and    Kxmax*x < xmax

function [J,x,y,u,c,Ksompc] = chap5_ompc_simulate_constraints(A,B,C,D,nc,Q,R,Q2,R2,x0,runtime,umin,umax,Kxmax,xmax)

%%%%%%%%%% Initial Conditions 
nu=size(B,2);
nx=size(A,1);
c = zeros(nu*nc,2); u =zeros(nu,2);  
x=[x0,x0];
y=C*x;
runtime;
J=0;

%%%%% The optimal predicted cost at any point 
%%%%%     J = c'*SC*c + 2*c'*SCX*x + x'*Sx*x
%%%%  Builds an autonomous model Z= Psi Z, u = -Kz Z  Z=[x;cfut];
%%%%
%%%% Control law parameters
[SX,SC,SXC,Spsi,K,Psi,Kz]=chap4_suboptcost(A,B,C,D,Q,R,Q2,R2,nc);
if norm(SXC)<1e-10; SXC=SXC*0;end
KK=inv(SC)*SXC';
Ksompc=[K+KK(1:nu,:)];

%%%%% Define constraint matrices using invariant set methods on
%%%%%  Z= Psi Z  u=-Kz Z  umin<u<umax   Kxmax *x <xmax
%%%%%
%%%%% First define constraints at each sample as G*x<f
%%%%%
%%%%%  Find MAS as M x + N cfut <= f
G=[-Kz;Kz;[Kxmax,zeros(size(Kxmax,1),nc*nu)]];
f=[umax;-umin;xmax]; 
[F,t]=findmas(Psi,G,f);
N=F(:,nx+1:end);
M=F(:,1:nx);

%%%%% Settings for quadratic program
opt = optimset('quadprog');
opt.Diagnostics='off';    %%%%% Switches of unwanted MATLAB displays
opt.LargeScale='off';     %%%%% However no warning of infeasibility
opt.Display='off';
opt.Algorithm='active-set';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%   SIMULATION

for i=2:runtime;

%%%%% Unconstrained control law
cfast(:,i) = KK*x(:,i);  
ufast(:,i) = -Ksompc*x(:,i);

%%%% constrained control law
%%%%  N c + Mx <=t
%%%%  J = c'*SC*c + 2*c'*SCX*x 
[cfut,vv,exitflag] = quadprog(SC,SXC'*x(:,i),N,t-M*x(:,i),[],[],[],[],[],opt);
if exitflag==-2;disp('No feasible solution');
    cfut=cfast(:,i);
end
c(:,i)=cfut;
u(:,i)=-K*x(:,i)+c(1:nu,i);

%%%% Simulate model      
     x(:,i+1) = A*x(:,i) + B*u(:,i) ;
     y(:,i+1) = C*x(:,i+1);

%%% update cost
     J(i)=x(:,i)'*SX*x(:,i)+2*c(:,i)'*SXC'*x(:,i)+c(:,i)'*SC*c(:,i);
end

%%%% Ensure all variables have conformal lengths
u(:,i+1) = u(:,i);  
c(:,i+1)=c(:,i);
J(:,i+1)=J(:,i);
J(1)=J(2);


