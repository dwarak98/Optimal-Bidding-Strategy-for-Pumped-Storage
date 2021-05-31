clear;
delete('dispatch results.xlsx');


clc;
Pp=130;         % in MW
Pg=100;         % in MW
Prs=130;        % in MW spinning reserve during pumping
Prn=100;        % in MW non spinning reserve when not in generation and not in pumping mode
Brs=0;          % in $/MWh spinning reserve during pumping
Brn=0;          % in $/MWh non spinning reserve when not in generation and not in pumping mode
eta=2/3;        % efficiency
Emax=2500;      % in MWh max energy storage capacity
Emin=0;         % in MWh min energy storage capacity


% Data processing

%Ti=readtable('OASIS_Day-Ahead_Market_Zonal_LBMP.csv');
%Ti=readtable('jan_week1_Day-Ahead_Market_Zonal_LBMP.csv');
%Ti=readtable('march_week3_OASIS_Day-Ahead_Market_Zonal_LBMP (1).csv');
Ti=readtable('jan_week3_Day-Ahead_Market_Zonal_LBMP.csv');
%Ti=readtable('real_jan_week1_OASIS_Real_Time_Dispatch_Zonal_LBMP.csv');


LMP=table2array(Ti(:,5));
LMP=str2double(LMP);
MCP=sort(LMP);


total=length(MCP);
T=total;

figure(1)
x=1:T;

plot(x,MCP(1:T),x,LMP(1:T))
xlabel('Time in hours');
legend('Composite market clearing price','Market clearing price');
ylabel('Day-ahead marginal prices in $/MWh');
title('Market Clearing Price vs time');

tpmax=T/(1+Pp*eta/Pg);
tpmax=floor(tpmax);



%----------------reserve constraint------------


r=1;
profit=0;
energy=Emax;

status=0;
t0=1;
T=total;
q=1;
start_time=0;
end_time=0;
Bp=0;
Bg=0;
tp=0;
tg=0;
while(t0 < total && q>0)
    q=0;
    
    LMP=table2array(Ti(:,5));
    LMP=LMP(t0:T);
    LMP=str2double(LMP);
    MCP=sort(LMP);
    disp('Entered step 1');
    disp('Unconstrained interval becomes ')
    disp(t0);
    disp(T);
    E_init=zeros(length(MCP),1);
    if(r==1)
        E_init(1)=Emax;
    else
        E_init(1)=y5(length(y5)-1);
        
        
    end
    values=[LMP MCP E_init];
    [y1,y2,y3,y4,y5,y6,y7]=optimization(values);
    
    E(r,1:length(y5))=y5;
    
    i=1;
    k=1;
    %
    
    while(i>0 && k<=length(y5))
        
    
        if((E(r,k) < Emin  || E(r,k) > Emax) && k>1 && t0~=total)
            disp('Entered step 3');
            q=1;
            disp(E(r,k-1));
            if(E(r,k) < Emin)
                E(r,k) = Emin;
            end
            
            if(E(r,k) > Emax)
                E(r,k) = Emax;
            end
            
            
            T=k-1+t0-1;                      % upper limit
            if(T>total)
                T=total;
                q=0;
            end
            disp('length of the unconstrained interval is ');
            disp(t0);
            disp(T);  % upper limit
            LMP=table2array(Ti(:,5));
            LMP=LMP(t0:T);
            LMP=str2double(LMP);
            MCP=sort(LMP);
            E_init=zeros(length(MCP),1);
            
            E_init(1)=E(r,k);
            if(r==1)
                E_init(1)=Emax;
            end       
            
            
            if(t0==T)
                i=0;
                last=E(r,k-1);
                
               
            end
            
            if(t0~=T)
                values=[LMP MCP E_init];
                [y1,y2,y3,y4,y5,y6,y7]=optimization(values);
                E(r,1:total)=0;
                E(r,1:length(y5))=y5;
                
                
                %last=E(r,length(y5));
            end
           
            
            k=0;
            
        
        end
        
    
        k=k+1;
    
    end
    
    
    %}
    if(t0==T)
         
         %y5=max([Emax,last])+min([Emin,last]);
         y5=[last last];
         y4=[0 0];
         y3=[0 0];
         y1=0;
         y2=0;
         y6=0;
         y7=0;
         t0=T+1;
         
        
    else
        
        start_time=[start_time t0];
        end_time=[end_time T];
        Bp=[Bp y6];
        Bg=[Bg y7];
        tg=[tg y1];
        tp=[tp y2];
        profit=[profit y3];
        t0=T;
        
    end
    
    
    T=total;
    
    status=[status y4(1:(length(y4)-1))];
    energy=[energy y5(1:(length(y5)-1))];
    r=r+1;
end

gen_count=0;
pump_count=0;
for i=1:length(status)
    if(status(i)==1)
        gen_count=gen_count+1;
    end
    if(status(i)==-1)
        pump_count=pump_count+1;
    end
end
gen_count
pump_count
       
figure(2)
x=1:T;

plot(status)
ylim([-2 2]);
xlabel('Time in hours');
ylabel('Status (0,1,-1)');
title('Status of the Generator vs time');
%}

figure(3)

x=1:(T);

plot(energy);
xlabel('Time in hours');
ylabel('Energy in MWh');
title('Energy vs time');

u=1;
%
decision=status;
Monday=transpose(decision(24*(u-1)+1:24*u));
Tuesday=transpose(decision(24*u+1:24*(u+1)));
Wednesday=transpose(decision(24*(u+1)+1:24*(u+2)));
Thursday=transpose(decision(24*(u+2)+1:24*(u+3)));
Friday=transpose(decision(24*(u+3)+1:24*(u+4)));
Saturday=transpose(decision(24*(u+4)+1:24*(u+5)));
Sunday=transpose(decision(24*(u+5)+1:24*(u+6)));


hour=transpose(1:24);


dispatch_table_week1=table(hour,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday)
writetable(dispatch_table_week1,'dispatch results.xlsx','Sheet',1,'Range','A1')
Start_time=transpose(start_time(2:length(start_time)));
End_time=transpose(end_time(2:length(end_time)));
Bp=transpose(Bp(2:length(Bp)));
Bg=transpose(Bg(2:length(Bg)));
tp=transpose(tp(2:length(tp)));
tg=transpose(tg(2:length(tg)));
Profit=transpose(profit(2:length(profit)));
Iterations=transpose(1:length(tp));
T=table(Iterations,Start_time,End_time,Bp,Bg,tp,tg,Profit)
writetable(T,'dispatch results.xlsx','Sheet',1,'Range','A30')

total_profit=sum(profit)
%}






% unconstrained optimization

function [y1,y2,y3,y4,y5,y6,y7]= optimization(values)


Pp=130;         % in MW
Pg=100;         % in MW
Prs=130;        % in MW spinning reserve during pumping
Prn=100;        % in MW non spinning reserve when not in generation and not in pumping mode
Brs=5;          % in $/MWh spinning reserve during pumping
Brn=0.5;        % in $/MWh non spinning reserve when not in generation and not in pumping mode
eta=2/3;        % efficiency
Emax=2500;      % in MWh max energy storage capacity
Emin=0;         % in MWh min energy storage capacity

T=length(values(:,2));  % length of the period T
LMP=values(:,1);        
MCP=values(:,2);
E(1)=values(1,3);       % Initial stored energy
tp=1;          
tpmax=T/(1+Pp*eta/Pg);
tpmax=floor(tpmax);     % maximum pumping time given time period T


decision=zeros(1,(length(LMP)));    % Gives status of the storage pump (-1,0,1)
eps=.1;                            % optimality variable



while(tp<=tpmax && tp>=1)
    
    
    tg=((Pp*eta*tp)/Pg);      % calculate tg
    Bp=MCP(tp);             % Pumping price or buying price
    Bg=MCP(T-floor(tg));    % generating price or selling price
      
    %abs(Bg-Bp*(1/eta+Brs/(eta*Bp)-(Brn*Pg)/(eta*Bp*Pp)+Brn/Bp)
    profit(tp)=Pg*(sum(MCP(T-floor(tg):T))+(tg-floor(tg))*MCP(T-floor(tg)))+Prs*Brs*tp+Pg*Brn*(T-tp-tg)-Pp*sum(MCP(1:tp));
    y2=tp;
    if (abs(Bg/Bp-(1/eta+Brs/(eta*Bp)-(Brn*Pg)/(eta*Bp*Pp)+Brn/Bp)) <= eps) % condition for optimality
        
        
        tp=tpmax+1;
    end
    
    if(abs(Bg/Bp-(1/eta+Brs/(eta*Bp)-(Brn*Pg)/(eta*Bp*Pp)+Brn/Bp)) > eps)
                
        
        tp=tp+1;
    end
    
    
end
%[max_profit,y2]=max(profit);


    

for i=1:T
    for j=1:(y2)
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
y3=profit(y2);          % profit
y4=decision(1:T);      % Status of the pupmped storage at each hour (-1,0,1)
y5=E(1:(T));           % Energy stored at each hour each hour
y6=MCP(y2);             % Bp
y7=MCP(T-floor(tg));    % Bg

end

            

