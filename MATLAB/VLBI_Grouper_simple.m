function [Group]=VLBI_Grouper_simple(RA,Dec, Vel,Amp, PosErr, maxvel)
% Usage [Group]=VLBI_Grouper_simple(RA, Dec, Vel,Amp,PosErr,maxvel)
% RA - array of RA offsets
% Dec - array of Declination offsets
% Vel - array of velocities
% Amp - array of fluxes for each channel
% PosErr - maximum position difference between points to be grouped
% maxvel - maximum velocity difference between points to be grouped


RA=RA(:);

Dec=Dec(:);

Vel=Vel(:);
Amp=Amp(:);
Group=struct('index', [], 'RA', [], 'Dec', [], 'Vel', [], 'Amp', [], 'WRA', [], 'WDec', [], 'RAdev', [], 'Decdev', [], 'MAmp', [], 'MVel', []);
b=struct('neighbours',[]);
for i=1:length(RA)
    b(i).neighbours=find(sqrt((RA-RA(i)).^2 + (Dec-Dec(i)).^2)<PosErr & abs(Vel-Vel(i))<maxvel)';
end

Checked=[];
k=0; % Counter for the Group structure.
jj=0;
CurrentGroup=[];
for i=1:length(b)
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
    [Group(k+1).WRA,Group(k+1).WRARMS]=WeightedMean(RA(CurrentGroup),Amp(CurrentGroup));
    [Group(k+1).WDec,Group(k+1).WDecRMS]=WeightedMean(Dec(CurrentGroup),Amp(CurrentGroup));
    Group(k+1).RAdev=std(RA(CurrentGroup));
    Group(k+1).Decdev=std(Dec(CurrentGroup));
    Group(k+1).MAmp=max(Amp(CurrentGroup));
    Group(k+1).MVel=mean(Vel(CurrentGroup));
%    Group(k+1).summ=[max(Amp(CurrentGroup)), mean(RA(CurrentGroup)), mean(Dec(CurrentGroup)), WRA, WDec, std(RA(CurrentGroup)), std(Dec(CurrentGroup)), WRARMS, WDecRMS, mean(Vel(CurrentGroup)), std(Vel(CurrentGroup))];
    k=k+1;

    CurrentGroup=[];
end
k=0;
Duds=[]; % Added with JMc on 13 Aug 2015
for i=1:length(RA)
    if isempty(Group(i).index)
        k=k+1;
        Duds(k)=i;
    end
end
Group(Duds)=[];
