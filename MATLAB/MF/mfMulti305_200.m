% Script to run mfVelFix for several epocs of obs and collect the data iteratively.

% Changed flux of channel 3888 in MF_R.OUT from 77.447 to 70.447, in order to allow velocity alignment to work properly. The change makes this peak slightly lower than the peak used for phase referencing. Thus, the phas ref peak is the strongest and is selected by mfVelFix.m for velocity channel alignment.

% Changed flux of channel 4649 in MF_Q.OUT from 416.638 to 402.638, in order to allow velocity alignment to work properly. The change makes this peak slightly lower than the peak used for phase referencing. Thus, the phas ref peak is the strongest and is selected by mfVelFix.m for velocity channel alignment.

colLim = [-40.0,-27.5]; % Colourbar limits
axLim  = 1500;          % Axes limit for plotting

%velfind = @(epoch) find(epoch == -35.6366);
%[Qra,Qdec,Qamp,Qvel] = mfVelFix('POSS_Q_GREP.OUT','MF_Q_GREP.OUT',4,0.5,0.4);
%[Rra,Rdec,Ramp,Rvel] = mfVelFix('POSS_R_GREP.OUT','MF_R_GREP.OUT',4,0.5,0.4);
%[Sra,Sdec,Samp,Svel] = mfVelFix('POSS_S_GREP.OUT','MF_S_GREP.OUT',4,0.5,0.3);
%[Tra,Tdec,Tamp,Tvel] = mfVelFix('POSS_T_GREP.OUT','MF_T_GREP.OUT',4,0.5,0.3);
%[Ura,Udec,Uamp,Uvel] = mfVelFix('POSS_U_GREP.OUT','MF_U_GREP.OUT',4,0.5,0.3);

[Qra,Qdec,Qamp,Qvel] = mfFrameOne('POSS_Q_GREP.OUT','MF_Q_GREP.OUT',1,2,0.5,0.4);
[Rra,Rdec,Ramp,Rvel] = mfFrameOne('POSS_R_GREP.OUT','MF_R_GREP.OUT',1,2,0.5,0.4);
[Sra,Sdec,Samp,Svel] = mfFrameOne('POSS_S_GREP.OUT','MF_S_GREP.OUT',1,2,0.5,0.3);
[Tra,Tdec,Tamp,Tvel] = mfFrameOne('POSS_T_GREP.OUT','MF_T_GREP.OUT',1,2,0.5,0.3);
[Ura,Udec,Uamp,Uvel] = mfFrameOne('POSS_U_GREP.OUT','MF_U_GREP.OUT',1,2,0.5,0.3);


velfind = @(epoch) find(Qamp==max(Qamp(find(Qvel>-36.0 & Qvel<-35.0)))); % Code for mfFrameOne only
QpkRa  =  Qra(velfind(Qvel));
QpkDec = Qdec(velfind(Qvel));

velfind = @(epoch) find(Ramp==max(Ramp(find(Rvel>-36.0 & Rvel<-35.0)))); % Code for mfFrameOne only
RpkRa  =  Rra(velfind(Rvel));
RpkDec = Rdec(velfind(Rvel));

velfind = @(epoch) find(Samp==max(Samp(find(Svel>-36.0 & Svel<-35.0)))); % Code for mfFrameOne only
SpkRa  =  Sra(velfind(Svel));
SpkDec = Sdec(velfind(Svel));

velfind = @(epoch) find(Tamp==max(Tamp(find(Tvel>-36.0 & Tvel<-35.0)))); % Code for mfFrameOne only
TpkRa  =  Tra(velfind(Tvel));
TpkDec = Tdec(velfind(Tvel));

velfind = @(epoch) find(Uamp==max(Uamp(find(Uvel>-36.0 & Uvel<-35.0)))); % Code for mfFrameOne only
UpkRa  =  Ura(velfind(Uvel));
UpkDec = Udec(velfind(Uvel));


Qra  = Qra  -  QpkRa(1);
Qdec = Qdec - QpkDec(1);
Rra  = Rra  -  RpkRa(1);
Rdec = Rdec - RpkDec(1);
Sra  = Sra  -  SpkRa(1);
Sdec = Sdec - SpkDec(1);
Tra  = Tra  -  TpkRa(1);
Tdec = Tdec - TpkDec(1);
Ura  = Ura  -  UpkRa(1);
Udec = Udec - UpkDec(1);


clf
hold on
colormap jet

scatter(Qra,Qdec,20,Qvel,'^','MarkerFaceColor','flat')
scatter(Rra,Rdec,20,Rvel,'o','MarkerFaceColor','flat')
scatter(Sra,Sdec,20,Svel,'S','MarkerFaceColor','flat')
scatter(Tra,Tdec,20,Tvel,'D','MarkerFaceColor','flat')
scatter(Ura,Udec,20,Uvel,'*','MarkerFaceColor','flat')


xlim([-axLim,axLim])
ylim([-axLim,axLim])

set (gca,'Xdir','reverse')
%set(gcf,'color','black')
set(gca,'color','black')
axis equal
caxis(colLim)
colorbar

%(- -484.888 -484.433)-0.4549999999999841
%(- 218.326 218.891)-0.5649999999999977

%(- -485.0 -484.875)-0.125
%(- 218.262 218.902)-0.6399999999999864
