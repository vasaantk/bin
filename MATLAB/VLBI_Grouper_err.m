function [Group]=VLBI_Grouper_err(RA,RA_err, Dec, Dec_err, Vel,Amp, maxvel)
% Usage [Group]=VLBI_Grouper(RA, Dec, Vel,Amp,maxvel)
% Now using err estimates to search for emission within 3-sigma globally and 2-sigma in either direction where sigma is the sum of the errors.


RA=RA(:);
RA_err=RA(:);
Dec=Dec(:);
Dec_err=Dec_err(:);
Vel=Vel(:);
Amp=Amp(:);
Group=struct('index', [], 'RA', [], 'Dec', [], 'Vel', [], 'summ', [], 'Amp', []);
b=struct('neighbours',[]);
for i=1:length(RA)
    b(i).neighbours=find( sqrt( ((RA-RA(i))./(RA_err(i)+RA_err)).^2 + ((Dec-Dec(i))./(Dec_err(i)+Dec_err)).^2) < 4 & ((RA-RA(i))./(RA_err(i)+RA_err))<3 & ((Dec-Dec(i))./(Dec_err(i)+Dec_err))<3 & abs(Vel-Vel(i))<maxvel)';
end

Checked=[];
k=0; % Counter for the Group structure.
jj=0;
CurrentGroup=[];
for i=1:length(b)
    %i
    if any(Checked==i)

    else
        m=0;
        temp=[];
        for j=1:length(b)
            if any(b(j).neighbours==i);
                % Group member
                m=m+1;
                temp(m)=j;
            end
        end
        temp2=sort(unique([b([temp]).neighbours]));
        CurrentGroup=temp2;
        Checked(length(Checked)+1)=i;
        temp=[];
        temp2=[];
    end

    %d=setdiff(Permagroup, f);
    while ~isempty(setdiff(CurrentGroup,Checked))
        f=setdiff(CurrentGroup,Checked);
        for mm=1:length(f)
            qq=f(mm);
            if any(Checked==qq)
                break
            else
                m=0;
                temp=[];
                temp2=[];
                for j=1:length(b)
                   if any(b(j).neighbours==qq);
                        % Group member
                        m=m+1;
                        temp(m)=qq;
                   end
                end
                temp2=sort(unique([b([temp]).neighbours]));
                CurrentGroup(length(CurrentGroup)+(1:length(temp2)))=temp2;
                CurrentGroup=unique(CurrentGroup);
                Checked(length(Checked)+1)=qq;
            end
        end
    end
    Group(k+1).index=CurrentGroup;
    Group(k+1).RA=RA(CurrentGroup)';
    Group(k+1).Dec=Dec(CurrentGroup)';
    Group(k+1).Vel=Vel(CurrentGroup)';
    Group(k+1).Amp=Amp(CurrentGroup)';
    [WRA,WRARMS]=WeightedMean(RA(CurrentGroup),Amp(CurrentGroup));
    [WDec,WDecRMS]=WeightedMean(Dec(CurrentGroup),Amp(CurrentGroup));
    [WVel,WVelRMS]=WeightedMean(Vel(CurrentGroup),Amp(CurrentGroup));   % Vasaant addition on 13 Oct 2014

    %Group(k+1).summ=[max(Amp(CurrentGroup)), mean(RA(CurrentGroup)), mean(Dec(CurrentGroup)), WRA, WDec, std(RA(CurrentGroup)), std(Dec(CurrentGroup)), WRARMS, WDecRMS, mean(Vel(CurrentGroup)), std(Vel(CurrentGroup))];

    Group(k+1).summ=[max(Amp(CurrentGroup)), mean(RA(CurrentGroup)), mean(Dec(CurrentGroup)), WRA, WDec, std(RA(CurrentGroup)), std(Dec(CurrentGroup)), WRARMS, WDecRMS, WVel, WVelRMS]; % Vasaant addition on 13 Oct 2014
    k=k+1;

    CurrentGroup=[];
end
k=0;
for i=1:length(RA)
    if isempty(Group(i).index)
        k=k+1;
        Duds(k)=i;
    end
end
Group(Duds)=[];
