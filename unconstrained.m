
clear;
clc;

Pp=130;         % in MW
Pg=100;         % in MW
Prs=130;        % in MW spinning reserve during pumping
Prn=100;        % in MW non spinning reserve when not in generation and not in pumping mode
Brs=0;          % in $/MWh spinning reserve during pumping
Brn=0;        % in $/MWh non spinning reserve when not in generation and not in pumping mode
eta=2/3;        % efficiency
Emax=2500;      % in MWh max energy storage capacity
Emin=0;         % in MWh min energy storage capacity


Ti=readtable('jan_week1_Day-Ahead_Market_Zonal_LBMP.csv');
%Ti=readtable('one_day_OASIS_Day-Ahead_Market_Zonal_LBMP.csv');

LMP=table2array(Ti(:,5));
LMP=str2double(LMP);
MCP=sort(LMP);


total=length(MCP);
T=total;

E(1)=Emax;       % Initial stored energy
tp=1;          
tpmax=T/(1+Pp*eta/Pg);
tpmax=floor(tpmax);     % maximum pumping time given time period T


decision=zeros(1,(length(LMP)));    % Gives status of the storage pump (-1,0,1)
eps=0.001;                            % optimality variable

if(E(1)<300)
    E0=0;
elseif(E(1)>2300)
    E0=2500;
end
while(tp<=tpmax)
    
    
    tg=((Pp*eta*tp-2500+E0)/Pg);      % calculate tg
    Bp=MCP(tp);             % Pumping price or buying price
    Bg=MCP(T-floor(tg));    % generating price or selling price
      
    profit(tp)=Pg*(sum(MCP(T-floor(tg):T))+(tg-floor(tg))*MCP(T-floor(tg)))+Prs*Brs*tp+Pg*Brn*(T-tp-tg)-Pp*sum(MCP(1:tp));
    y2=tp;
    if (abs(Bg/Bp-(1/eta)) <= eps) % condition for optimality
        tp=tpmax+1;
    end
    
    if(abs(Bg/Bp-(1/eta)) > eps)        
        tp=tp+1;
    end
    
    
end

%[max_profit,y2]=max(profit)


for i=1:T
    for j=1:y2
        if(LMP(i)==MCP(j))
            decision(i)=-1;  % Pumping mode
        end
    end
    
    
        
end

for i=1:T
    for j=T-floor(tg)+1:T
        if(LMP(i)==MCP(j))
            decision(i)=1;  % Generating mode
        end
    end
        
end


for i=(2:T)
    E(i)=E(i-1)+abs(decision(i))*((1-decision(i))*0.5*eta*Pp-(1+decision(i))*0.5*Pg);  % calculating energy at each hour of the week
end


y1=Pp*eta*y2/Pg;        % returning tg
y3=profit(y2)          % profit
y4=decision(1:T);      % Status of the pupmped storage at each hour (-1,0,1)
y5=E(1:(T));           % Energy stored at each hour each hour
y6=MCP(y2);             % Bp
y7=MCP(T-floor(tg));    % Bg



            
plot(E)
plot(profit)

T=table(y1,y2,y3,y6,y7)
