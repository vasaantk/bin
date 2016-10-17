% allLocalVar{1}=localVar;
% fix the problem of passing a scalar in Fortran and then the dummy arg is assumed size
% also try to fix the problem of doing this to an an array in general, not only dummy arrays

% also fix when the same variable is used as the multiple inputs in the same function call


if want_point
 
 %'rrrrrrrrrrr',kb
 %temp7={funwords{:},fun_name{:}};
 rets=zeros(1,2);
 keepLine=ones(1,s); %whether to keep this line in the end or not
 temp4=find(~cellfun('isempty',regexp(funstr,funNameSuffix))).';
 goon2=[find(~cellfun('isempty',regexp(funstr,['^function\>']))).',length(funstr)];
 temp13=regexp(funstr(temp4),['=\s*',wordstr,'\('],'tokens');
 temp13=cellfun(@(c) c{1}, temp13, 'UniformOutput', false);
 temp13=[temp13{:}];
 if ~isempty(temp13)
  temp13=find(ismember({files.name},temp13));
 else
  temp13=[];
 end
 for ii=[temp13(:)',length(allLocalVar)+1]
  %for ii=1:length(allLocalVar)+1
  % temp5 is then which function call lines call the ii'th function in fun_name
  if ii==length(allLocalVar)+1
   temp5=find(~cellfun('isempty',regexp(funstr,funHandleNameSuffix))).';
   temp11=[''];
  else
   temp5=find(~cellfun('isempty',regexp(funstr(temp4),['\<',fun_name{ii},'\>']))).';
   temp5=temp4(temp5);
   %temp5=find(~cellfun('isempty',regexp(funstr,['\<',fun_name{ii},'\>']))).';
   temp11=['cleaning up at end... ',num2str(ii),' out of ',num2str(length(fun_name)),' functions'];
  end
  dispback(temp11);
  if ii==length(allLocalVar),  disp([temp11,'  ...  done']), end

  if ~isempty(temp5)
   for i=temp5 %loop through the fun_name{ii} calls in the entire file
    ;% which function are we in?
     % temp9 is the index to fun_name of which function the line i is in
    temp12=find(goon2<=i); % which function def lines are before the current line
    for jj=fliplr(goon2(temp12))
     %jj=goon2(temp12);
     temp6=find(funstr{jj}=='=');
     if ~isempty(temp6)
      temp8=funstrwords{jj}{find(funstrwords_b{jj}>temp6(1),1,'first')};
      temp9=find(strcmp(temp8,fun_name));
     else
      %no output arguments on this function
      temp8=funstrwords{jj}{2};
      temp9=find(strcmp(temp8,fun_name));
     end % if ~isempty(temp6)
     if ~isempty(temp9),      break,     end % if ~isempty(temp9)
    end % for jj=fliplr(goon2(temp12))
%%%   'ddddddddd',funstr{i},
%%%   disp(['   fun_name{temp9} = ',num2str(   fun_name{temp9})]);
%%%   disp(['   fun_name{ii} = ',num2str(   fun_name{ii})]);
%%%   kb
% ii is which target (called) function we are working on 
% temp9 is which function the call is in (in the fun_name list and in allLocalVar)
% temp is which word in this line is the fun_name{ii}
% i is the actual line that this fun_name{ii} call is on
    if ii==length(allLocalVar)+1 || ...
          isempty(find(strcmp(fun_name{ii},{allLocalVar{temp9}{:,1}})))
     % make sure this is not s a local var
     temp6='   '; temp7='   ';
     while true
      if ii==length(allLocalVar)+1
       % assume only one use of ]=funhandle( per line
       temp=regexp(funstr{i},']=(\w+)\(','tokenExtents');
       if ~isempty(temp)
        temp=find(funstrwords_b{i}==temp{1}(1),1,'first');
       end
       %'rrrrrrrrrrr11',funstr{i},kb
      else
       temp=find(strcmp(funstrwords{i},fun_name{ii})); 
      end
      if ~isempty(temp)
       temp=temp(1); %assume only one function call per line
       goonimag=1;
       if validSpot(funstr{i},funstrwords_b{i}(temp))
        %outputs of the fun_name{ii} function on this line
        temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp));
        if temp12>0 && funstr{i}(temp12)=='='
         temp12=lastNonSpace(funstr{i},temp12);
         if temp12>0 && funstr{i}(temp12)==']'
          temp11=findlefts_f(temp12,funstr{i});
          [outflag,howmany,subscripts,centercomma,parens]=inbracket2(funstr{i},temp11+1);
          if howmany>0
           %go through input args, seeing if there is a duplicate
           centercomma=[parens(1),centercomma,parens(2)];
           temp16=unique(strtrim(subscripts));
           if howmany~=length(temp16)
            for fid=howmany:-1:1
             temp15=find(strcmp(strtrim(subscripts),subscripts{fid}));
             if length(temp15)>1
              if length(find(funstrwords_b{i}<centercomma(fid+1) & ...
                             funstrwords_b{i}>centercomma(fid)))==1 && ...
                   length(find(funstrnumbers_b{i}<centercomma(fid+1) & ...
                               funstrnumbers_b{i}>centercomma(fid)))==0
%%%               %if this is a scalar, then don't
%%%               tempstr=1;
%%%               temp11=find(strcmp(subscripts{fid},{allLocalVar{temp9}{:,1}}));
%%%               if ~isempty(temp11)
%%%                if isempty(allLocalVar{temp9}{temp11,5}), tempstr=0; end
%%%               end % if ~isempty(temp11)
               if ~any(strcmp(strtrim(subscripts{fid}),allExtWords{temp9}))% & tempstr
                temp6=[strtrim(subscripts{fid}),origVar,'=',strtrim(subscripts{fid}),'; ',temp6];
                temp7=[temp7,' ',strtrim(subscripts{fid}),'(',dumvar,num2str(fid),'~=',...
                       strtrim(subscripts{fid}),origVar,')=',dumvar,num2str(fid),...
                       '(',dumvar,num2str(fid),'~=',strtrim(subscripts{fid}),origVar,');'];
                %get the outputs so can change funstr
                funstr{i}=[funstr{i}(1:centercomma(fid)),dumvar,num2str(fid),...
                           funstr{i}(centercomma(fid+1):end)];
                %'xxxxxxxxxxxxxx122',funstr{i},temp6,temp7,kb
                [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
                goonimag=0;             break
               end % if ~any(strcmp(strtrim(subscripts{fid}),
              end % if length(find(funstrwords_b{i}<centercomma(fid+1) & .
             end % if length(temp15)>1
             if ~goonimag, break; end
            end % for fid=howmany:-1:1
           end % if howmany~=length(temp16{1})
          end % if howmany>0
         end % if funstr{i}(temp12)==']'
        end % if funstr{i}(temp12)=='='
       end % if validSpot(funstr{i},
      else
       break
      end % if ~isempty(temp)
      if goonimag, break; end
     end % while true
%%%    if ~isempty(strtrim(temp6))
%%%     'xxxxxxxxxxxxxx122',funstr{i},temp6,temp7,kb
%%%    end
     if any(~isspace(temp6))
      funstr{i}=[temp6,funstr{i},temp7];
      [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
      rets(1)=rets(1)+1;
     end
    end % if isempty(find(strcmp(fun_name{ii},
   end % for i=temp5
  end % if ~isempty(temp5)

  %'xxxxxxxxxxxxxx12233',showall(funstr),temp6,temp7,fun_name,ii,kb
  


%%%             if any(strcmp(funstrwords{i},'sub7'))
%%%              funstr{i},kb
%%%             end

  rets(2)=rets(2)+1;
  %temp5=find(~cellfun('isempty',regexp(funstr,['\<',fun_name{ii},'\>']))).';
  if ~isempty(temp5)
   for i=temp5
    % which function are we in? it may be a local variable
    temp12=find(goon2<=i); % which function def lines are before the current line
    for jj=fliplr(goon2(temp12))
     %jj=goon2(temp12);
     temp6=find(funstr{jj}=='=');
     if ~isempty(temp6)
      temp8=funstrwords{jj}{find(funstrwords_b{jj}>temp6(1),1,'first')};
      temp9=find(strcmp(temp8,fun_name));
     else
      %no output arguments on this function
      temp8=funstrwords{jj}{2};
      temp9=find(strcmp(temp8,fun_name));
     end % if ~isempty(temp6)
     if ~isempty(temp9),      break,     end % if ~isempty(temp9)
    end % for jj=fliplr(goon2(temp12))
%%%   'ddddddddd',funstr{i},
%%%   disp(['   fun_name{temp9} = ',num2str(   fun_name{temp9})]);
%%%   disp(['   fun_name{ii} = ',num2str(   fun_name{ii})]);
%%%   kb
% temp9 is which function we are in (in the fun_name list and in allLocalVar)
% i is the actual line that this fun_name{ii} call is on

    
    
    if ii==length(allLocalVar)+1 || isempty(find(strcmp(fun_name{ii},{allLocalVar{temp9}{:,1}})))
     temp6='   '; temp7='   '; bar={};
     temp17=[]; temp19=0;
     while true
      temp18=0;
      if ii==length(allLocalVar)+1
       % assume only one use of ]=funhandle( per line
       temp=regexp(funstr{i},']=(\w+)\(','tokenExtents');
       if ~isempty(temp)
        temp=find(funstrwords_b{i}==temp{1}(1),1,'first');
       end
       %'rrrrrrrrrrr11',funstr{i},kb
      else
       temp=find(strcmp(funstrwords{i},fun_name{ii})); 
      end
      if ~isempty(temp)
       goonimag=1;
       for j=length(temp):-1:1
        if validSpot(funstr{i},funstrwords_b{i}(temp(j)))
         [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords); 
         %args to function call
         if howmany>0
          if isempty(temp17), temp17=ones(1,howmany); end
          %go through input args, seeing if the they are scalar refs to a matrix, 
          % then if args in that subroutine are assumed shape
          centercomma=[parens(1),centercomma,parens(2)];
          temp16=[];
          for fid=1:howmany
           temp3=find(funstrwords_b{i}>centercomma(fid) & ...
                      funstrwords_b{i}<centercomma(fid+1),1,'first');
           if ~isempty(temp3)
            temp16=[temp16,temp3];
           end
          end
          for fid=1:howmany %which subscript we are in in the call
           temp3=find(funstrwords_b{i}>centercomma(fid) & ...
                      funstrwords_b{i}<centercomma(fid+1),1,'first');
           if ~isempty(temp3)
            %'ssssssssss',funstrwords{i}{temp3(1)},funstr{i},kb
            % make sure this is a variable
            if any(strcmp({allLocalVar{temp9}{:,1}},funstrwords{i}{temp3(1)}))
             % howmany2 etc are for the fid'th passed variable
             [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,temp3(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
             % sometimes they pass a scalar valued ind on one input, then the entire array on
             % another input. That entire array must also be dealt with as if it were scalar 
             % indexed with 1. e.g.
             % call sub2(y(3),y(5),y)
             % should be treated as
             % call sub2(y(3),y(5),y(1))              
             if howmany2==0
              %if any others of temp16 have a subscript, add one to this one
              temp18=0;              
              for jj=setdiff(temp16,temp3)
               if strcmp(funstrwords{i}{temp3},funstrwords{i}{jj})
                if funstr{i}(nextNonSpace(funstr{i},funstrwords_e{i}(jj)))=='('
                 temp18=1;
                end % if funstr{i}(nextNonSpace(funstr{i},
               end % if strcmp(funstrwords{i}{temp16(fid)},
              end % for jj=setxor(1:howmany,
              if strcmp(funstrwords{i}{temp3},strtrim(subscripts{fid}))
               if temp18 % add a (1) to this var
                temp20=find(funstr{i}=='[',1,'first');
                if isempty(temp20)
                 funstr{i}=[funstr{i}(1:funstrwords_e{i}(temp3)),...
                            '(1)',funstr{i}(funstrwords_e{i}(temp3)+1:end)];
                else
                 [outflag,howmany3,subscripts3,centercomma3,parens3]=inbracket2(funstr{i},...
                                                                   find(funstr{i}=='[',1,'first')+1);
                 centercomma3=[parens3(1),centercomma3,parens3(2)];
                 funstr{i}=[funstr{i}(1:centercomma3(fid)),subscripts3{fid},'(1)',...
                            funstr{i}(centercomma3(fid+1):funstrwords_e{i}(temp3)),...
                            '(1)',funstr{i}(funstrwords_e{i}(temp3)+1:end)];
                end % if isempty(temp20)
                
                [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
                [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,temp3(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
                [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords); %args to function call
                centercomma=[parens(1),centercomma,parens(2)];
                %'rrrrrrrrrrr11',funstr{i},kb
               end % if temp18 % add a (1) to this var
              end % if strcmp(funstrwords{i}{temp16(fid)},
             end
             
             if howmany2>0
              centercomma2=[parens2(1),centercomma2,parens2(2)];
              %this has to be the only thing passed, no other words or nums or - outside this var
%%%              if strcmp('b',funstrwords{i}{temp3(1)})
%%%               'weeeeeeeeee',funstr{i},fid,temp3,funstr{i}(1:centercomma(fid)),funstrwords{i},kb
%%%              end
              if isempty(find(funstrwords_b{i}>centercomma(fid)&...
                              funstrwords_b{i}<funstrwords_b{i}(temp3(1))))...
                   && ...
                   isempty(find(funstrnumbers_b{i}>centercomma(fid)&...
                                funstrnumbers_b{i}<funstrwords_b{i}(temp3(1))))...
                   &&...
                   isempty(find(funstrwords_b{i}<centercomma(fid+1)&...
                                funstrwords_b{i}>parens2(2)))...
                   && ...
                   isempty(find(funstrnumbers_b{i}<centercomma(fid+1)&...
                                funstrnumbers_b{i}>parens2(2)))...
                   && ...
                   isempty(find(funstr{i}(centercomma(fid):funstrwords_b{i}(temp3(1)))=='-'))
               if isempty(find(funstr{i}(parens2(1)+1:parens2(2)-1)==':')) && temp17(fid)

                
                
                
                
                
                
                
                if ii==length(allLocalVar)+1
                 % here fix anonymous function calls

                 %we have a single index coming into a vector or matrix (or scalar), adjust
                 % the call to be begin:(begin+lengthinsub-1) or :end on all dims
                 %'fddddddd',funstr{i},kb
                 tempstr=subscripts{fid};
                 
                 tempstr=[funstrwords{i}{temp3(1)},'('];
                 for jj=1:length(subscripts2)
                  tempstr=[tempstr,subscripts2{jj},':end,'];
                 end % for jj=1:length(subscripts2)
                 tempstr=[tempstr(1:end-1),')'];
                 
                 %there might be an output var that is the same, so do a strrep
                 % if that's true, then this is the only function call on that line
                 % must be careful here, for example:
                 % t = -CDOTC(N-l+1,X(l,l),1,X(l,j),1)/X(l,l)
                 %funstr{i},'fffffffffffff',kb
                 temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp(j)));
                 if temp12>0 && funstr{i}(temp12)=='=' && funstr{i}(lastNonSpace(funstr{i},temp12))==']'
                  
                  %if funstr{i}(1)=='['%originally a subroutine call, so strrep after the fun
                  % now, sillily, different indeces, same var (iwork) can be done in fortran:
                  %CALL SS2LT(N,Nelt,Ia,Ja,A,Isym,nl,Iwork(lociel),Iwork(locjel),Rwork(locel))
%%%                    if (~isempty(temp4) && ...
%%%                         any(strcmp(temp4,funstrwords{i}{temp3(1)}))) || ...
                  if any(strcmp({funstrwords{i}{setdiff(temp16,temp3)}},...
                                funstrwords{i}{temp3}))
%%%                     funstrwords{i}{temp3},'dddddddddd',kb
                   tempstr2=strrep(funstr{i}(funstrwords_b{i}(temp(j)):end),...
                                   funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                   tempstr);
                   funstr{i}=[strrep(funstr{i}(1:funstrwords_b{i}(temp(j))-1),...
                                     funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                     [dumvar,num2str(fid)]),...
                              tempstr2];
                   if howmany2~=1
                    temp6=[temp6,tempstr,'=',[dumvar,num2str(fid)],'; '];
                   else
                    temp7=[temp7,[dumvar,num2str(fid),'i'],'=',...
                           'find((',tempstr,')~=(',[dumvar,num2str(fid)],'));'];
                    temp6=[temp6,...
                           funstrwords{i}{temp3(1)},'(',subscripts2{1},'-1+',...
                           [dumvar,num2str(fid),'i'],')=',...
                           [dumvar,num2str(fid)],'(',[dumvar,num2str(fid),'i'],'); '];
%%%                      fid,temp6,temp7,'ttttttttttt',kb
                   end
                  elseif temp17(fid)
                   funstr{i}=strrep(...
                       funstr{i},funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),tempstr);
                  end
%%%                    temp4{fid}=funstrwords{i}{temp3(1)};
                 else % in a function, so only strrep on the arguments to this func
                  funstr{i}=[funstr{i}(1:parens(1)),...
                             strrep(funstr{i}(parens(1)+1:parens(2)-1),...
                                    funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                    tempstr),...
                             funstr{i}(parens(2):end)];
                 end
                 [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
                 goonimag=0;
                 break
                else %not an anonymous function, regular
                     % is this an assumed shape or an array at all on the way in?
                 for goon=1:size(allLocalVar{ii},1)
                  if ~isempty(allLocalVar{ii}{goon,13}) %must be an input var=
                   if allLocalVar{ii}{goon,13}==fid
                    %if ~isempty(allLocalVar{ii}{goon,5}) %must be an array in segment itself

                    %'tttttttt',allLocalVar{ii}{goon,:},fun_name{ii},kb
                    if ~strcmp(allLocalVar{ii}{goon,3},'character')
                        %if 1%~isempty(allLocalVar{ii}{goon,5}) %&& any(strcmp(strtrim(allLocalVar{ii}{goon,5}),'*'))
                        %let's go for it
                     if length(subscripts2)>0 && strcmp(subscripts2{1},'''offset''')
                      break
                     end
                     temp19=1; %new way, don't need temp6 or temp7 below
                     if howmany2>1
                      tempstr=[funstrwords{i}{temp3(1)},'(''offset'',[',...
                               funstr{i}(parens2(1)+1:parens2(2)-1),'])'];
                     else
                      tempstr=[funstrwords{i}{temp3(1)},'(''offset'',',...
                               funstr{i}(parens2(1)+1:parens2(2)-1),')'];
                     end
                     if want_ALLpoint==0
                      bar{length(bar)+1}=[funstrwords{i}{temp3(1)},'=mlPointer(',...
                                          funstrwords{i}{temp3(1)},');'];
                     end
                     %if length(subscripts2)==1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now adjust the called (target) function to get rid of shape adjustments and such
                     stat=[];
                     if isempty(allLocalVar{ii}{goon,5}) %coming into a scalar, need (1)
                                                         %'ttttttt',kb
                      funstr(goon2(ii)+1:goon2(ii+1)-1)=regexprep(...
                          funstr(goon2(ii)+1:goon2(ii+1)-1),...
                          ['\<',allLocalVar{ii}{goon,1},'\>([^\(])'],...
                          [allLocalVar{ii}{goon,1},'(1)$1']);
                     elseif length(allLocalVar{ii}{goon,5})==1
                      stat=find(~cellfun('isempty',...
                                         regexp(funstr(goon2(ii):goon2(ii+1)),...
                                                ['\<\s*',allLocalVar{ii}{goon,1},shapeVar])));
                      keepLine(goon2(ii)+stat-1)=0;
                     elseif length(allLocalVar{ii}{goon,5})==2
                      %change the declaration to adjust dims only
                      stat=find(~cellfun('isempty',...
                                         regexp(funstr(goon2(ii):goon2(ii+1)),...
                                                ['^\s*',allLocalVar{ii}{goon,1},shapeVar,...
                                          '=zeros'])));
                      if ~isempty(stat)
                       if want_ALLpoint==0
                        funstr{goon2(ii)+stat(1)-1}=['if ~isa(',allLocalVar{ii}{goon,1},...
                                            ',''mlPointer'');',funstr{goon2(ii)+stat(1)-1},...
                                            'end;'];
                       end % if want_ALLpoint
                      end
                      %keepLine(goon2(ii)+stat-1)=0;
                      stat=find(~cellfun('isempty',...
                                         regexp(funstr(goon2(ii):goon2(ii+1)),...
                                                ['^\s*',allLocalVar{ii}{goon,1},shapeVar,...
                                          '=size'])));
                      if ~isempty(stat)
                       if want_ALLpoint
                        funstr{goon2(ii)+stat(1)-1}=[allLocalVar{ii}{goon,1},...
                                            '.dims=[',num2str(allLocalVar{ii}{goon,5}{1}),...
                                            ',0];'];
                       else
                        funstr{goon2(ii)+stat(1)-1}=['if isa(',allLocalVar{ii}{goon,1},...
                                            ',''mlPointer''); ',allLocalVar{ii}{goon,1},...
                                            '.dims=[',num2str(allLocalVar{ii}{goon,5}{1}),...
                                            ',0]; else; ',funstr{goon2(ii)+stat(1)-1},'end;'];
                       end % if want_ALLpoint
                       %'fddddddd2',funstr{i},fid,funstr{goon2(ii)+stat(1)-1},kb
                      end
                     end % if length(allLocalVar{ii}{goon,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     
                     %else
                     %'dddddddd',funstr{i},tempstr,kb
%%%                       tempstr=[funstrwords{i}{temp3(1)},'(sub2ind(size(',...
%%%                                funstrwords{i}{temp3(1)},...
%%%                                '),',funstr{i}(parens2(1)+1:parens2(2)-1),'):end)'];

                     %end
                    else
                     %we have a single index coming into a vector or matrix (or scalar), 
                     % adjust the call to be begin:(begin+lengthinsub-1) or :end on all dims
                     %'fddddddd',funstr{i},kb
                     tempstr=subscripts{fid};
                     
                     if ~isempty(allLocalVar{ii}{goon,5}) %scalar or not
                      tempstr=[funstrwords{i}{temp3(1)},'('];
                      for jj=1:length(subscripts2)
                       %but a multiple subscript can also come into a single sub!
                       temp15=[];
                       if jj<=length(allLocalVar{ii}{goon,5})
                        temp15=find(strcmp(strtrim(allLocalVar{ii}{goon,5}{jj}),...
                                           {allLocalVar{ii}{:,1}}),1,'first');
                       end
                       if ~isempty(temp15) & length(allLocalVar{ii}{goon,5})<2
                        tempstr=[tempstr,subscripts2{jj},':',subscripts2{jj},'+',...
                                 subscripts{allLocalVar{ii}{temp15,13}},'-1,'];
                       else
                        tempstr=[tempstr,subscripts2{jj},':end,'];
                       end
                      end % for jj=1:length(subscripts2)
                      tempstr=[tempstr(1:end-1),')'];
                     else
                      temp17(fid)=0;
                     end % if ~isempty(allLocalVar{ii}{goon,
                    end 
                    %there might be an output var that is the same, so do a strrep
                    % if that's true, then this is the only function call on that line
                    % must be careful here, for example:
                    % t = -CDOTC(N-l+1,X(l,l),1,X(l,j),1)/X(l,l)
                    %funstr{i},'fffffffffffff',kb
                    temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp(j)));
                    if temp12>0 && funstr{i}(temp12)=='=' && funstr{i}(lastNonSpace(funstr{i},temp12))==']'
                     %if funstr{i}(1)=='['%originally a subroutine call, so strrep after the fun
                     % now, sillily, different indeces, same var (iwork) can be done in fortran:
                     %CALL SS2LT(N,Nelt,Ia,Ja,A,Isym,nl,Iwork(lociel),Iwork(locjel),Rwork(locel))
%%%                    if (~isempty(temp4) && ...
%%%                         any(strcmp(temp4,funstrwords{i}{temp3(1)}))) || ...
                     if any(strcmp({funstrwords{i}{setdiff(temp16,temp3)}},...
                                   funstrwords{i}{temp3})) | temp19
%%%                     funstrwords{i}{temp3},'dddddddddd',kb
                      tempstr2=strrep(funstr{i}(funstrwords_b{i}(temp(j)):end),...
                                      funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                      tempstr);
                      funstr{i}=[strrep(funstr{i}(1:funstrwords_b{i}(temp(j))-1),...
                                        funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                        [dumvar,num2str(fid)]),...
                                 tempstr2];
                      if howmany2~=1
                       temp6=[temp6,tempstr,'=',[dumvar,num2str(fid)],'; '];
                      else
                       temp7=[temp7,[dumvar,num2str(fid),'i'],'=',...
                              'find((',tempstr,')~=(',[dumvar,num2str(fid)],'));'];
                       temp6=[temp6,...
                              funstrwords{i}{temp3(1)},'(',subscripts2{1},'-1+',...
                              [dumvar,num2str(fid),'i'],')=',...
                              [dumvar,num2str(fid)],'(',[dumvar,num2str(fid),'i'],'); '];
%%%                      fid,temp6,temp7,'ttttttttttt',kb
                      end
                     elseif temp17(fid)
                      funstr{i}=strrep(...
                          funstr{i},funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),tempstr);
                     end
%%%                    temp4{fid}=funstrwords{i}{temp3(1)};
                    else % in a function, so only strrep on the arguments to this func
                     funstr{i}=[funstr{i}(1:parens(1)),...
                                strrep(funstr{i}(parens(1)+1:parens(2)-1),...
                                       funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                       tempstr),...
                                funstr{i}(parens(2):end)];
                    end
                    [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
                    goonimag=0;
                    break
                    %end % if ~isempty(allLocalVar{ii}{goon,
                   end % if allLocalVar{ii}{goon,w
                  end % if ~isempty(allLocalVar{ii}{goon,
                 end % for goon=1:size(allLocalVar{temp2(j)},
                end % if ii==length(allLocalVar)+1
               end % if isempty(find(funstr{i}(parens2(1)+1:parens2(2)-1)==':'))
              end % if isempty(find(funstrwords_b{i}>centercomma(fid)&.
             end % if howmany2>0
            end % if ~any(strcmp(temp7,
           end % if ~isempty(temp3)
           if ~goonimag, break; end
          end % for fid=1:howmany
         end % if howmany>0
        end % if validSpot(funstr{jj},
       end % for j=length(temp):-1:1
      else
       break
      end % if ~isempty(temp)
      if goonimag, break; end
     end % while true
%%%     if ~isempty(strtrim(temp6))
%%%      'xxxxxxxxxxxxxx1',funstr{i},temp6,temp7,kb
%%%     end
     if temp19, temp6=''; temp7=''; bar=unique(bar); end
     if any(~isspace(temp6)) || ~isempty(bar)
%%%      %get rid of duplicate mlPointer assignments
%%%      for iii=length(bar):-1:1
%%%%%%       bar{iii}
%%%%%%       'bbbbbbbbb',kb
%%%       foo=strrep(strrep(bar{iii},'(','\('),')','\)');
%%%       if ~isempty(find(~cellfun('isempty',(regexp(funstr(goon2(temp9):goon2(temp9+1)),foo)))))
%%%        bar={bar{setdiff(1:length(bar),iii)}};
%%%       end % if ~isempty(find(~cellfun('isempty',        
%%%      end
      %bar,'wwwwwwwww',funstr(goon2(temp9):goon2(temp9+1)),kb
      funstr{i}=[[bar{:}],funstr{i},temp7,temp6];
      [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
     end
    end % if isempty(find(strcmp(fun_name{ii},
   end % for i=temp5
  end % if ~isempty(temp5)
 end % for ii=1:length(allLocalVar)

 if rets(1)
  disp(['found ',num2str(rets(1)),' cases of duplicate input variables']);
 end
 if rets(2)
  disp(['cleaned up * inputs in ',num2str(rets(2)),' out of ',...
        num2str(length(allLocalVar)),' functions'])
 end
 disp(['*************** f2matlab second pass finished *************'])
%%%disp([' ii = ',num2str( ii)]);
%%%'================',kb

 % now get rid of all the funNameSuffix
 funstr=regexprep(funstr,funNameSuffix,'');
 funstr=regexprep(funstr,funHandleNameSuffix,'');
 funstr=funstr(find(keepLine));
 [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good]=updatefunstr_f(funstr); 

 %'dfdfdfdfdf',funstr,kb

  






 
%%% 
%%% 
%%% 
%%% %'rrrrrrrrrrr',kb
%%% %temp7={funwords{:},fun_name{:}};
%%% rets=zeros(1,2);
%%% keepLine=ones(1,s); %whether to keep this line in the end or not
%%% temp4=find(~cellfun('isempty',regexp(funstr,funNameSuffix))).';
%%% goon2=[find(~cellfun('isempty',regexp(funstr,['^function\>']))).',length(funstr)];
%%% for ii=1:length(allLocalVar)+1
%%%  % temp5 is then which function call lines call the ii'th function in fun_name
%%%  if ii==length(allLocalVar)+1
%%%   temp5=find(~cellfun('isempty',regexp(funstr,funHandleNameSuffix))).';
%%%   temp11=[''];
%%%  else
%%%   temp5=find(~cellfun('isempty',regexp(funstr(temp4),['\<',fun_name{ii},'\>']))).';
%%%   temp5=temp4(temp5);
%%%   %temp5=find(~cellfun('isempty',regexp(funstr,['\<',fun_name{ii},'\>']))).';
%%%   temp11=['cleaning up at end... ',num2str(ii),' out of ',num2str(length(fun_name)),' functions'];
%%%  end
%%%  dispback(temp11);
%%%  if ii==length(allLocalVar),  disp([temp11,'  ...  done']), end
%%%
%%%  if ~isempty(temp5)
%%%   for i=temp5 %loop through the fun_name{ii} calls in the entire file
%%%    ;% which function are we in?
%%%     % temp9 is the index to fun_name of which function the line i is in
%%%    temp12=find(goon2<=i); % which function def lines are before the current line
%%%    for jj=fliplr(goon2(temp12))
%%%     %jj=goon2(temp12);
%%%     temp6=find(funstr{jj}=='=');
%%%     if ~isempty(temp6)
%%%      temp8=funstrwords{jj}{find(funstrwords_b{jj}>temp6(1),1,'first')};
%%%      temp9=find(strcmp(temp8,fun_name));
%%%     else
%%%      %no output arguments on this function
%%%      temp8=funstrwords{jj}{2};
%%%      temp9=find(strcmp(temp8,fun_name));
%%%     end % if ~isempty(temp6)
%%%     if ~isempty(temp9),      break,     end % if ~isempty(temp9)
%%%    end % for jj=fliplr(goon2(temp12))
%%%%%%   'ddddddddd',funstr{i},
%%%%%%   disp(['   fun_name{temp9} = ',num2str(   fun_name{temp9})]);
%%%%%%   disp(['   fun_name{ii} = ',num2str(   fun_name{ii})]);
%%%%%%   kb
%%%% ii is which target (called) function we are working on 
%%%% temp9 is which function the call is in (in the fun_name list and in allLocalVar)
%%%% temp is which word in this line is the fun_name{ii}
%%%% i is the actual line that this fun_name{ii} call is on
%%%    if ii==length(allLocalVar)+1 || ...
%%%          isempty(find(strcmp(fun_name{ii},{allLocalVar{temp9}{:,1}})))
%%%     % make sure this is not s a local var
%%%     temp6='   '; temp7='   ';
%%%     while true
%%%      if ii==length(allLocalVar)+1
%%%       % assume only one use of ]=funhandle( per line
%%%       temp=regexp(funstr{i},']=(\w+)\(','tokenExtents');
%%%       if ~isempty(temp)
%%%        temp=find(funstrwords_b{i}==temp{1}(1),1,'first');
%%%       end
%%%       %'rrrrrrrrrrr11',funstr{i},kb
%%%      else
%%%       temp=find(strcmp(funstrwords{i},fun_name{ii})); 
%%%      end
%%%      if ~isempty(temp)
%%%       temp=temp(1); %assume only one function call per line
%%%       goonimag=1;
%%%       if validSpot(funstr{i},funstrwords_b{i}(temp))
%%%        %outputs of the fun_name{ii} function on this line
%%%        temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp));
%%%        if temp12>0 && funstr{i}(temp12)=='='
%%%         temp12=lastNonSpace(funstr{i},temp12);
%%%         if temp12>0 && funstr{i}(temp12)==']'
%%%          temp11=findlefts_f(temp12,funstr{i});
%%%          [outflag,howmany,subscripts,centercomma,parens]=inbracket2(funstr{i},temp11+1);
%%%          if howmany>0
%%%           %go through input args, seeing if there is a duplicate
%%%           centercomma=[parens(1),centercomma,parens(2)];
%%%           temp16=unique(strtrim(subscripts));
%%%           if howmany~=length(temp16)
%%%            for fid=howmany:-1:1
%%%             temp15=find(strcmp(strtrim(subscripts),subscripts{fid}));
%%%             if length(temp15)>1
%%%              if length(find(funstrwords_b{i}<centercomma(fid+1) & ...
%%%                             funstrwords_b{i}>centercomma(fid)))==1 && ...
%%%                   length(find(funstrnumbers_b{i}<centercomma(fid+1) & ...
%%%                               funstrnumbers_b{i}>centercomma(fid)))==0
%%%               if ~any(strcmp(strtrim(subscripts{fid}),allExtWords{temp9}))
%%%                temp6=[strtrim(subscripts{fid}),'_orig=',strtrim(subscripts{fid}),'; ',temp6];
%%%                temp7=[temp7,' ',strtrim(subscripts{fid}),'(',dumvar,num2str(fid),'~=',...
%%%                       strtrim(subscripts{fid}),'_orig)=',dumvar,num2str(fid),...
%%%                       '(',dumvar,num2str(fid),'~=',strtrim(subscripts{fid}),'_orig);'];
%%%                %get the outputs so can change funstr
%%%                funstr{i}=[funstr{i}(1:centercomma(fid)),dumvar,num2str(fid),...
%%%                           funstr{i}(centercomma(fid+1):end)];
%%%                %'xxxxxxxxxxxxxx122',funstr{i},temp6,temp7,kb
%%%                [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
%%%                goonimag=0;             break
%%%               end % if ~any(strcmp(strtrim(subscripts{fid}),
%%%              end % if length(find(funstrwords_b{i}<centercomma(fid+1) & .
%%%             end % if length(temp15)>1
%%%             if ~goonimag, break; end
%%%            end % for fid=howmany:-1:1
%%%           end % if howmany~=length(temp16{1})
%%%          end % if howmany>0
%%%         end % if funstr{i}(temp12)==']'
%%%        end % if funstr{i}(temp12)=='='
%%%       end % if validSpot(funstr{i},
%%%      end % if ~isempty(temp)
%%%      if goonimag, break; end
%%%     end % while true
%%%%%%    if ~isempty(strtrim(temp6))
%%%%%%     'xxxxxxxxxxxxxx122',funstr{i},temp6,temp7,kb
%%%%%%    end
%%%     if any(~isspace(temp6))
%%%      funstr{i}=[temp6,funstr{i},temp7];
%%%      [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
%%%      rets(1)=rets(1)+1;
%%%     end
%%%    end % if isempty(find(strcmp(fun_name{ii},
%%%   end % for i=temp5
%%%  end % if ~isempty(temp5)
%%%
%%%  %'xxxxxxxxxxxxxx12233',showall(funstr),temp6,temp7,fun_name,ii,kb
%%%  
%%%
%%%
%%%
%%%  % check to see if this one is an input array
%%%  temp10=0;
%%%  if ii==length(allLocalVar)+1
%%%   temp10=1;
%%%  else
%%%   for jj=1:size(allLocalVar{ii},1)
%%%    if ~isempty(allLocalVar{ii}{jj,13}) %is an input var
%%%     if ~isempty(allLocalVar{ii}{jj,5}) %is an array
%%%      temp10=1; break
%%%     end % if any(strcmp(strtrim(allLocalVar{ii}{jj,
%%%    end % if ~isempty(allLocalVar{ii}{jj,
%%%   end % for jj=1:size(allLocalVar{ii},
%%%  end
%%%  if temp10
%%%   rets(2)=rets(2)+1;
%%%   %temp5=find(~cellfun('isempty',regexp(funstr,['\<',fun_name{ii},'\>']))).';
%%%   if ~isempty(temp5)
%%%    for i=temp5
%%%     % which function are we in? it may be a local variable
%%%     'gggg',ii,kb
%%%     temp12=find(goon2<=i); % which function def lines are before the current line
%%%     for jj=fliplr(goon2(temp12))
%%%      %jj=goon2(temp12);
%%%      temp6=find(funstr{jj}=='=');
%%%      if ~isempty(temp6)
%%%       temp8=funstrwords{jj}{find(funstrwords_b{jj}>temp6(1),1,'first')};
%%%       temp9=find(strcmp(temp8,fun_name));
%%%      else
%%%       %no output arguments on this function
%%%       temp8=funstrwords{jj}{2};
%%%       temp9=find(strcmp(temp8,fun_name));
%%%      end % if ~isempty(temp6)
%%%      if ~isempty(temp9),      break,     end % if ~isempty(temp9)
%%%     end % for jj=fliplr(goon2(temp12))
%%%%%%   'ddddddddd',funstr{i},
%%%%%%   disp(['   fun_name{temp9} = ',num2str(   fun_name{temp9})]);
%%%%%%   disp(['   fun_name{ii} = ',num2str(   fun_name{ii})]);
%%%%%%   kb
%%%% temp9 is which function we are in (in the fun_name list and in allLocalVar)
%%%% i is the actual line that this fun_name{ii} call is on
%%%     if ii==length(allLocalVar)+1 || isempty(find(strcmp(fun_name{ii},{allLocalVar{temp9}{:,1}})))
%%%      temp6='   '; temp7='   '; bar={};
%%%      temp17=[]; temp19=0;
%%%      while true
%%%       temp18=0;
%%%       if ii==length(allLocalVar)+1
%%%        % assume only one use of ]=funhandle( per line
%%%        temp=regexp(funstr{i},']=(\w+)\(','tokenExtents');
%%%        if ~isempty(temp)
%%%         temp=find(funstrwords_b{i}==temp{1}(1),1,'first');
%%%        end
%%%        %'rrrrrrrrrrr11',funstr{i},kb
%%%       else
%%%        temp=find(strcmp(funstrwords{i},fun_name{ii})); 
%%%       end
%%%       if ~isempty(temp)
%%%        goonimag=1;
%%%        for j=length(temp):-1:1
%%%         if validSpot(funstr{i},funstrwords_b{i}(temp(j)))
%%%          [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords); 
%%%          %args to function call
%%%          if howmany>0
%%%           if isempty(temp17), temp17=ones(1,howmany); end
%%%           %go through input args, seeing if the they are scalar refs to a matrix, 
%%%           % then if args in that subroutine are assumed shape
%%%           centercomma=[parens(1),centercomma,parens(2)];
%%%           temp16=[];
%%%           for fid=1:howmany
%%%            temp3=find(funstrwords_b{i}>centercomma(fid) & ...
%%%                       funstrwords_b{i}<centercomma(fid+1),1,'first');
%%%            if ~isempty(temp3)
%%%             temp16=[temp16,temp3];
%%%            end
%%%           end
%%%           for fid=1:howmany %which subscript we are in in the call
%%%            temp3=find(funstrwords_b{i}>centercomma(fid) & ...
%%%                       funstrwords_b{i}<centercomma(fid+1),1,'first');
%%%            if ~isempty(temp3)
%%%             %'ssssssssss',funstrwords{i}{temp3(1)},funstr{i},kb
%%%             % make sure this is a variable
%%%             if any(strcmp({allLocalVar{temp9}{:,1}},funstrwords{i}{temp3(1)}))
%%%              [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,temp3(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%              % sometimes they pass a scalar valued index on one input, then the entire array on
%%%              % another input. That entire array must also be dealt with as if it were scalar 
%%%              % indexed with 1. e.g.
%%%              % call sub2(y(3),y(5),y)
%%%              % should be treated as
%%%              % call sub2(y(3),y(5),y(1))
%%%              if howmany2==0
%%%%%%             if strcmp(funstrwords{i}{temp3},'w') && any(strcmp(funstrwords{i},'npiqp'))
%%%%%%              funstr{i},kb
%%%%%%             end
%%%%if any others of temp16 have a subscript, add one to this one
%%%               temp18=0;              
%%%               for jj=setdiff(temp16,temp3)
%%%                if strcmp(funstrwords{i}{temp3},funstrwords{i}{jj})
%%%                 if funstr{i}(nextNonSpace(funstr{i},funstrwords_e{i}(jj)))=='('
%%%                  temp18=1;
%%%                 end % if funstr{i}(nextNonSpace(funstr{i},
%%%                end % if strcmp(funstrwords{i}{temp16(fid)},
%%%               end % for jj=setxor(1:howmany,
%%%               if strcmp(funstrwords{i}{temp3},strtrim(subscripts{fid}))
%%%                if temp18 % add a (1) to this var
%%%                 [outflag,howmany3,subscripts3,centercomma3,parens3]=inbracket2(funstr{i},...
%%%                                                                   find(funstr{i}=='[',1,'first')+1);
%%%                 %if howmany3~=howmany, error('not enough outputs?'),end
%%%                 centercomma3=[parens3(1),centercomma3,parens3(2)];
%%%                 funstr{i}=[funstr{i}(1:centercomma3(fid)),subscripts3{fid},'(1)',...
%%%                            funstr{i}(centercomma3(fid+1):funstrwords_e{i}(temp3)),...
%%%                            '(1)',funstr{i}(funstrwords_e{i}(temp3)+1:end)];
%%%                 [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
%%%                 [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,temp3(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
%%%                 [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords); %args to function call
%%%                 centercomma=[parens(1),centercomma,parens(2)];
%%%                 %'rrrrrrrrrrr11',funstr{i},kb
%%%                end % if temp18 % add a (1) to this var
%%%               end % if strcmp(funstrwords{i}{temp16(fid)},
%%%              end
%%%              
%%%              if howmany2>0
%%%               centercomma2=[parens2(1),centercomma2,parens2(2)];
%%%               %this has to be the only thing passed, no other words or nums or - outside this var
%%%%%%              if strcmp('b',funstrwords{i}{temp3(1)})
%%%%%%               'weeeeeeeeee',funstr{i},fid,temp3,funstr{i}(1:centercomma(fid)),funstrwords{i},kb
%%%%%%              end
%%%               if isempty(find(funstrwords_b{i}>centercomma(fid)&...
%%%                               funstrwords_b{i}<funstrwords_b{i}(temp3(1))))...
%%%                    && ...
%%%                    isempty(find(funstrnumbers_b{i}>centercomma(fid)&...
%%%                                 funstrnumbers_b{i}<funstrwords_b{i}(temp3(1))))...
%%%                    &&...
%%%                    isempty(find(funstrwords_b{i}<centercomma(fid+1)&...
%%%                                 funstrwords_b{i}>parens2(2)))...
%%%                    && ...
%%%                    isempty(find(funstrnumbers_b{i}<centercomma(fid+1)&...
%%%                                 funstrnumbers_b{i}>parens2(2)))...
%%%                    && ...
%%%                    isempty(find(funstr{i}(centercomma(fid):funstrwords_b{i}(temp3(1)))=='-'))
%%%                if isempty(find(funstr{i}(parens2(1)+1:parens2(2)-1)==':')) && temp17(fid)
%%%                 if ii==length(allLocalVar)+1
%%%                  % here fix anonymous function calls
%%%
%%%                  %we have a single index coming into a vector or matrix (or scalar), adjust
%%%                  % the call to be begin:(begin+lengthinsub-1) or :end on all dims
%%%                  %'fddddddd',funstr{i},kb
%%%                  tempstr=subscripts{fid};
%%%                  
%%%                  tempstr=[funstrwords{i}{temp3(1)},'('];
%%%                  for jj=1:length(subscripts2)
%%%                   tempstr=[tempstr,subscripts2{jj},':end,'];
%%%                  end % for jj=1:length(subscripts2)
%%%                  tempstr=[tempstr(1:end-1),')'];
%%%                  
%%%                  %there might be an output var that is the same, so do a strrep
%%%                  % if that's true, then this is the only function call on that line
%%%                  % must be careful here, for example:
%%%                  % t = -CDOTC(N-l+1,X(l,l),1,X(l,j),1)/X(l,l)
%%%                  %funstr{i},'fffffffffffff',kb
%%%                  temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp(j)));
%%%                  if temp12>0 && funstr{i}(temp12)=='=' && funstr{i}(lastNonSpace(funstr{i},temp12))==']'
%%%                   
%%%                   %if funstr{i}(1)=='['%originally a subroutine call, so strrep after the fun
%%%                   % now, sillily, different indeces, same var (iwork) can be done in fortran:
%%%                   %CALL SS2LT(N,Nelt,Ia,Ja,A,Isym,nl,Iwork(lociel),Iwork(locjel),Rwork(locel))
%%%%%%                    if (~isempty(temp4) && ...
%%%%%%                         any(strcmp(temp4,funstrwords{i}{temp3(1)}))) || ...
%%%                   if any(strcmp({funstrwords{i}{setdiff(temp16,temp3)}},...
%%%                                 funstrwords{i}{temp3}))
%%%%%%                     funstrwords{i}{temp3},'dddddddddd',kb
%%%                    tempstr2=strrep(funstr{i}(funstrwords_b{i}(temp(j)):end),...
%%%                                    funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
%%%                                    tempstr);
%%%                    funstr{i}=[strrep(funstr{i}(1:funstrwords_b{i}(temp(j))-1),...
%%%                                      funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
%%%                                      [dumvar,num2str(fid)]),...
%%%                               tempstr2];
%%%                    if howmany2~=1
%%%                     temp6=[temp6,tempstr,'=',[dumvar,num2str(fid)],'; '];
%%%                    else
%%%                     temp7=[temp7,[dumvar,num2str(fid),'i'],'=',...
%%%                            'find((',tempstr,')~=(',[dumvar,num2str(fid)],'));'];
%%%                     temp6=[temp6,...
%%%                            funstrwords{i}{temp3(1)},'(',subscripts2{1},'-1+',...
%%%                            [dumvar,num2str(fid),'i'],')=',...
%%%                            [dumvar,num2str(fid)],'(',[dumvar,num2str(fid),'i'],'); '];
%%%%%%                      fid,temp6,temp7,'ttttttttttt',kb
%%%                    end
%%%                   elseif temp17(fid)
%%%                    funstr{i}=strrep(...
%%%                        funstr{i},funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),tempstr);
%%%                   end
%%%%%%                    temp4{fid}=funstrwords{i}{temp3(1)};
%%%                  else % in a function, so only strrep on the arguments to this func
%%%                   funstr{i}=[funstr{i}(1:parens(1)),...
%%%                              strrep(funstr{i}(parens(1)+1:parens(2)-1),...
%%%                                     funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
%%%                                     tempstr),...
%%%                              funstr{i}(parens(2):end)];
%%%                  end
%%%                  [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
%%%                  goonimag=0;
%%%                  break
%%%                 else %not an anonymous function, regular
%%%                      % is this an assumed shape or an array at all on the way in?
%%%                  for goon=1:size(allLocalVar{ii},1)
%%%                   if ~isempty(allLocalVar{ii}{goon,13}) %must be an input var=
%%%                    if allLocalVar{ii}{goon,13}==fid
%%%                     %if ~isempty(allLocalVar{ii}{goon,5}) %must be an array in segment itself
%%%
%%%                     %'tttttttt',allLocalVar{ii}{goon,:},fun_name{ii},kb
%%%                     if 1%~isempty(allLocalVar{ii}{goon,5}) %&& any(strcmp(strtrim(allLocalVar{ii}{goon,5}),'*'))
%%%                      %let's go for it
%%%                      if length(subscripts2)>0 && strcmp(subscripts2{1},'''offset''')
%%%                       break
%%%                      end
%%%                      temp19=1; %new way, don't need temp6 or temp7 below
%%%                      tempstr=[funstrwords{i}{temp3(1)},'(''offset'',[',...
%%%                               funstr{i}(parens2(1)+1:parens2(2)-1),'])'];
%%%                      bar{length(bar)+1}=[funstrwords{i}{temp3(1)},'=mlPointer(',...
%%%                                          funstrwords{i}{temp3(1)},');'];
%%%                      %if length(subscripts2)==1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% now adjust the called function to get rid of shape adjustments and such
%%%                       stat=[];
%%%                       if length(allLocalVar{ii}{goon,5})<2
%%%                        stat=find(~cellfun('isempty',...
%%%                                           regexp(funstr(goon2(ii):goon2(ii+1)),...
%%%                                                  ['\<\s*',allLocalVar{ii}{goon,1},shapeVar])));
%%%                        keepLine(goon2(ii)+stat-1)=0;
%%%                       elseif length(allLocalVar{ii}{goon,5})==2
%%%                        %change the declaration to adjust dims only
%%%                        stat=find(~cellfun('isempty',...
%%%                                           regexp(funstr(goon2(ii):goon2(ii+1)),...
%%%                                                  ['^\s*',allLocalVar{ii}{goon,1},shapeVar,...
%%%                                            '=zeros'])));
%%%                        if ~isempty(stat)
%%%                         funstr{goon2(ii)+stat(1)-1}=['if ~isa(',allLocalVar{ii}{goon,1},...
%%%                                             ',''mlPointer'');',funstr{goon2(ii)+stat(1)-1},...
%%%                                             'end;'];
%%%                        end
%%%                        %keepLine(goon2(ii)+stat-1)=0;
%%%                        stat=find(~cellfun('isempty',...
%%%                                           regexp(funstr(goon2(ii):goon2(ii+1)),...
%%%                                                  ['^\s*',allLocalVar{ii}{goon,1},shapeVar,...
%%%                                            '=size'])));
%%%                        if ~isempty(stat)
%%%                         funstr{goon2(ii)+stat(1)-1}=['if isa(',allLocalVar{ii}{goon,1},...
%%%                                             ',''mlPointer''); ',allLocalVar{ii}{goon,1},...
%%%                                             '.dims=[',num2str(allLocalVar{ii}{goon,5}{1}),...
%%%                                             ',0]; else; ',funstr{goon2(ii)+stat(1)-1},'end;'];
%%%                         %'fddddddd2',funstr{i},fid,funstr{goon2(ii)+stat(1)-1},kb
%%%                        end
%%%                       end % if length(allLocalVar{ii}{goon,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                      
%%%                       %else
%%%                       %'dddddddd',funstr{i},tempstr,kb
%%%%%%                       tempstr=[funstrwords{i}{temp3(1)},'(sub2ind(size(',...
%%%%%%                                funstrwords{i}{temp3(1)},...
%%%%%%                                '),',funstr{i}(parens2(1)+1:parens2(2)-1),'):end)'];
%%%
%%%                       %end
%%%                     else
%%%                      %we have a single index coming into a vector or matrix (or scalar), 
%%%                      % adjust the call to be begin:(begin+lengthinsub-1) or :end on all dims
%%%                      %'fddddddd',funstr{i},kb
%%%                      tempstr=subscripts{fid};
%%%                      
%%%                      if ~isempty(allLocalVar{ii}{goon,5}) %scalar or not
%%%                       tempstr=[funstrwords{i}{temp3(1)},'('];
%%%                       for jj=1:length(subscripts2)
%%%                        %but a multiple subscript can also come into a single sub!
%%%                        temp15=[];
%%%                        if jj<=length(allLocalVar{ii}{goon,5})
%%%                         temp15=find(strcmp(strtrim(allLocalVar{ii}{goon,5}{jj}),...
%%%                                            {allLocalVar{ii}{:,1}}),1,'first');
%%%                        end
%%%                        if ~isempty(temp15) & length(allLocalVar{ii}{goon,5})<2
%%%                         tempstr=[tempstr,subscripts2{jj},':',subscripts2{jj},'+',...
%%%                                  subscripts{allLocalVar{ii}{temp15,13}},'-1,'];
%%%                        else
%%%                         tempstr=[tempstr,subscripts2{jj},':end,'];
%%%                        end
%%%                       end % for jj=1:length(subscripts2)
%%%                       tempstr=[tempstr(1:end-1),')'];
%%%                      else
%%%                       temp17(fid)=0;
%%%                      end % if ~isempty(allLocalVar{ii}{goon,
%%%                     end 
%%%                     %there might be an output var that is the same, so do a strrep
%%%                     % if that's true, then this is the only function call on that line
%%%                     % must be careful here, for example:
%%%                     % t = -CDOTC(N-l+1,X(l,l),1,X(l,j),1)/X(l,l)
%%%                     %funstr{i},'fffffffffffff',kb
%%%                     temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp(j)));
%%%                     if temp12>0 && funstr{i}(temp12)=='=' && funstr{i}(lastNonSpace(funstr{i},temp12))==']'
%%%                      %if funstr{i}(1)=='['%originally a subroutine call, so strrep after the fun
%%%                      % now, sillily, different indeces, same var (iwork) can be done in fortran:
%%%                      %CALL SS2LT(N,Nelt,Ia,Ja,A,Isym,nl,Iwork(lociel),Iwork(locjel),Rwork(locel))
%%%%%%                    if (~isempty(temp4) && ...
%%%%%%                         any(strcmp(temp4,funstrwords{i}{temp3(1)}))) || ...
%%%                      if any(strcmp({funstrwords{i}{setdiff(temp16,temp3)}},...
%%%                                    funstrwords{i}{temp3})) | temp19
%%%%%%                     funstrwords{i}{temp3},'dddddddddd',kb
%%%                       tempstr2=strrep(funstr{i}(funstrwords_b{i}(temp(j)):end),...
%%%                                       funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
%%%                                       tempstr);
%%%                       funstr{i}=[strrep(funstr{i}(1:funstrwords_b{i}(temp(j))-1),...
%%%                                         funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
%%%                                         [dumvar,num2str(fid)]),...
%%%                                  tempstr2];
%%%                       if howmany2~=1
%%%                        temp6=[temp6,tempstr,'=',[dumvar,num2str(fid)],'; '];
%%%                       else
%%%                        temp7=[temp7,[dumvar,num2str(fid),'i'],'=',...
%%%                               'find((',tempstr,')~=(',[dumvar,num2str(fid)],'));'];
%%%                        temp6=[temp6,...
%%%                               funstrwords{i}{temp3(1)},'(',subscripts2{1},'-1+',...
%%%                               [dumvar,num2str(fid),'i'],')=',...
%%%                               [dumvar,num2str(fid)],'(',[dumvar,num2str(fid),'i'],'); '];
%%%%%%                      fid,temp6,temp7,'ttttttttttt',kb
%%%                       end
%%%                      elseif temp17(fid)
%%%                       funstr{i}=strrep(...
%%%                           funstr{i},funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),tempstr);
%%%                      end
%%%%%%                    temp4{fid}=funstrwords{i}{temp3(1)};
%%%                     else % in a function, so only strrep on the arguments to this func
%%%                      funstr{i}=[funstr{i}(1:parens(1)),...
%%%                                 strrep(funstr{i}(parens(1)+1:parens(2)-1),...
%%%                                        funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
%%%                                        tempstr),...
%%%                                 funstr{i}(parens(2):end)];
%%%                     end
%%%                     [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
%%%                     goonimag=0;
%%%                     break
%%%                     %end % if ~isempty(allLocalVar{ii}{goon,
%%%                    end % if allLocalVar{ii}{goon,w
%%%                   end % if ~isempty(allLocalVar{ii}{goon,
%%%                  end % for goon=1:size(allLocalVar{temp2(j)},
%%%                 end % if ii==length(allLocalVar)+1
%%%                end % if isempty(find(funstr{i}(parens2(1)+1:parens2(2)-1)==':'))
%%%               end % if isempty(find(funstrwords_b{i}>centercomma(fid)&.
%%%              end % if howmany2>0
%%%             end % if ~any(strcmp(temp7,
%%%            end % if ~isempty(temp3)
%%%            if ~goonimag, break; end
%%%           end % for fid=1:howmany
%%%          end % if howmany>0
%%%         end % if validSpot(funstr{jj},
%%%        end % for j=length(temp):-1:1
%%%       end % if ~isempty(temp)
%%%       if goonimag, break; end
%%%      end % while true
%%%%%%     if ~isempty(strtrim(temp6))
%%%%%%      'xxxxxxxxxxxxxx1',funstr{i},temp6,temp7,kb
%%%%%%     end
%%%      if temp19, temp6=''; temp7=''; bar=unique(bar); end
%%%      if any(~isspace(temp6)) || ~isempty(bar)
%%%       funstr{i}=[[bar{:}],funstr{i},temp7,temp6];
%%%       [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
%%%      end
%%%     end % if isempty(find(strcmp(fun_name{ii},
%%%    end % for i=temp5
%%%   end % if ~isempty(temp5)
%%%  end % if temp10
%%%  
%%% end % for ii=1:length(allLocalVar)
%%%
%%% if rets(1)
%%%  disp(['found ',num2str(rets(1)),' cases of duplicate input variables']);
%%% end
%%% if rets(2)
%%%  disp(['cleaned up * inputs in ',num2str(rets(2)),' out of ',...
%%%        num2str(length(allLocalVar)),' functions'])
%%% end
%%% disp(['*************** f2matlab second pass finished *************'])
%%%%%%disp([' ii = ',num2str( ii)]);
%%%%%%'================',kb
%%%
%%% % now get rid of all the funNameSuffix
%%% funstr=regexprep(funstr,funNameSuffix,'');
%%% funstr=regexprep(funstr,funHandleNameSuffix,'');
%%% funstr=funstr(find(keepLine));
%%% if isempty(find(keepLine==0))
%%%  [funstr,funstrwords,funstrwords_b,funstrwords_e,funstrnumbers,funstrnumbers_b,funstrnumbers_e,s,fs_good]=updatefunstr_f(funstr); 
%%% end
%%%
%%% %'dfdfdfdfdf',kb
%%%
%%%
%%%
%%%
%%%
%%%
%%%
%%%






else
















 % allLocalVar{1}=localVar;
 % fix the problem of passing a scalar in Fortran and then the dummy arg is assumed size
 % also try to fix the problem of doing this to an an array in general, not only dummy arrays

 % also fix when the same variable is used as the multiple inputs in the same function call

 
 if oneBYone
  fun_name={files.name};
 end
 %temp7={funwords{:},fun_name{:}};

%%% if strcmpi(this_fun_name,'cunk1') & ~informationRun 
%%%  'ssssss',kb
%%% end

 rets=zeros(1,2);
 temp4=find(~cellfun('isempty',regexp(funstr,funNameSuffix))).';
 goon2=find(~cellfun('isempty',regexp(funstr,['^function\>']))).';
 temp13=regexp(funstr(temp4),['=\s*',wordstr,'\('],'tokens');
 for ii=1:length(temp13)
  if ~isempty(temp13{ii})
   temp13{ii}=cellfun(@(c) c{1}, temp13{ii}, 'UniformOutput', false);
  end
 end
 if isempty(temp13) | isempty([temp13{:}]) %isempty(temp13{1})
  temp13=[];
 else
  temp13=[temp13{:}];
  if isempty(temp13)
   temp13=[];
  elseif oneBYone
   temp13=find(ismember({files.name},temp13));
  else
   temp13=find(ismember(fun_name,temp13));
  end
 end
%%% if ~informationRun
%%%  'eeeeee',funstr,kb
%%% end
 for ii=[temp13(:)',length(allLocalVar)+1]
  %for ii=1:length(allLocalVar)+1
  % temp5 is then which function call lines call the ii'th function in fun_name
  if ii==length(allLocalVar)+1
   temp5=find(~cellfun('isempty',regexp(funstr,funHandleNameSuffix))).';
   temp11=[''];
  else
   temp5=find(~cellfun('isempty',regexp(funstr(temp4),['\<',fun_name{ii},'\>']))).';
   temp5=temp4(temp5);
   %temp5=find(~cellfun('isempty',regexp(funstr,['\<',fun_name{ii},'\>']))).';
   temp11=['cleaning up at end... ',num2str(ii),' out of ',num2str(length(fun_name)),' functions'];
  end
  %dispback(temp11);
  if ii==length(allLocalVar),  disp([temp11,'  ...  done']), end

  if ~isempty(temp5)
   for i=temp5 %loop through the fun_name{ii} calls in the entire file
    ;% which function are we in?
     % ii is which function we are working on 
     % temp8 is the name of the function that line i is in
     % temp9 is the index to fun_name of which function the line i is in
     % temp9 is which function we are in (in the fun_name list and in allLocalVar)
    temp9=length(find(i-[sublist{:,2}]>0));
    temp8=sublist{temp9,1};
    if oneBYone
     temp9=find(strcmp(sublist{1,1},fun_name));
    end % if oneBYone

    % temp is which word in this line is the fun_name{ii}
    % i is the actual line that this fun_name{ii} call is on
    if ii==length(allLocalVar)+1 || isempty(find(strcmp(fun_name{ii},{allLocalVar{temp9}{:,1}}))) % make sure this is not s alocal var
     temp6='   '; temp7='   ';
     while true
      if ii==length(allLocalVar)+1
       % assume only one use of ]=funhandle( per line
       temp=regexp(funstr{i},']=(\w+)\(','tokenExtents');
       if ~isempty(temp)
        temp=find(funstrwords_b{i}==temp{1}(1),1,'first');
       end
       %'rrrrrrrrrrr11',funstr{i},kb
      else
       temp=find(strcmp(funstrwords{i},fun_name{ii})); 
      end
      if ~isempty(temp)
       temp=temp(1); %assume only one function call per line
       goonimag=1;
       if validSpot(funstr{i},funstrwords_b{i}(temp))
        %outputs of the fun_name{ii} function on this line
        temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp));
        if temp12>0 && funstr{i}(temp12)=='='
         temp12=lastNonSpace(funstr{i},temp12);
         if temp12>0 && funstr{i}(temp12)==']'
          temp11=findlefts_f(temp12,funstr{i});
          [outflag,howmany,subscripts,centercomma,parens]=inbracket2(funstr{i},temp11+1);
          if howmany>0
           %go through input args, seeing if there is a duplicate
           centercomma=[parens(1),centercomma,parens(2)];
           temp16=unique(strtrim(subscripts));
           if howmany~=length(temp16)
            for fid=howmany:-1:1
             temp15=find(strcmp(strtrim(subscripts),subscripts{fid}));
             if length(temp15)>1
              if length(find(funstrwords_b{i}<centercomma(fid+1) & ...
                             funstrwords_b{i}>centercomma(fid)))==1 && ...
                   length(find(funstrnumbers_b{i}<centercomma(fid+1) & ...
                               funstrnumbers_b{i}>centercomma(fid)))==0
               if ~any(strcmp(strtrim(subscripts{fid}),allExtWords{temp9}))
                temp6=[strtrim(subscripts{fid}),'_orig=',strtrim(subscripts{fid}),'; ',temp6];
                temp7=[temp7,' ',strtrim(subscripts{fid}),'(',dumvar,num2str(fid),'~=',...
                       strtrim(subscripts{fid}),'_orig)=',dumvar,num2str(fid),...
                       '(',dumvar,num2str(fid),'~=',strtrim(subscripts{fid}),'_orig);'];
                %get the outputs so can change funstr
                funstr{i}=[funstr{i}(1:centercomma(fid)),dumvar,num2str(fid),...
                           funstr{i}(centercomma(fid+1):end)];
                %'xxxxxxxxxxxxxx122',funstr{i},temp6,temp7,kb
                [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
                goonimag=0;             break
               end % if ~any(strcmp(strtrim(subscripts{fid}),
              end % if length(find(funstrwords_b{i}<centercomma(fid+1) & .
             end % if length(temp15)>1
             if ~goonimag, break; end
            end % for fid=howmany:-1:1
           end % if howmany~=length(temp16{1})
          end % if howmany>0
         end % if funstr{i}(temp12)==']'
        end % if funstr{i}(temp12)=='='
       end % if validSpot(funstr{i},
      else
       break
      end % if ~isempty(temp)
      if goonimag, break; end
     end % while true
     if any(~isspace(temp6))
      funstr{i}=[temp6,funstr{i},temp7];
      [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
      rets(1)=rets(1)+1;
     end
    end % if isempty(find(strcmp(fun_name{ii},
   end % for i=temp5
  end % if ~isempty(temp5)

  %'xxxxxxxxxxxxxx12233',showall(funstr),temp6,temp7,fun_name,ii,kb
  



  % check to see if this one is an input array
  temp10=0;
  if ii==length(allLocalVar)+1
   temp10=1;
  else
   for jj=1:size(allLocalVar{ii},1)
    if ~isempty(allLocalVar{ii}{jj,13}) %is an input var
     if ~isempty(allLocalVar{ii}{jj,5}) %is an array
      temp10=1; break
     end % if any(strcmp(strtrim(allLocalVar{ii}{jj,
    end % if ~isempty(allLocalVar{ii}{jj,
   end % for jj=1:size(allLocalVar{ii},
  end
  if temp10
   rets(2)=rets(2)+1;
   %temp5=find(~cellfun('isempty',regexp(funstr,['\<',fun_name{ii},'\>']))).';
   if ~isempty(temp5)
    for i=temp5
     % which function are we in? it may be a local variable
     temp9=length(find(i-[sublist{:,2}]>0));
     temp8=sublist{temp9,1};
     if oneBYone
      temp9=find(strcmp(sublist{1,1},fun_name));
     end % if oneBYone
    

%%%     temp12=find(goon2<=i); % which function def lines are before the current line
%%%     for jj=fliplr(goon2(temp12))
%%%      %jj=goon2(temp12);
%%%      temp6=find(funstr{jj}=='=');
%%%      if ~isempty(temp6)
%%%       temp8=funstrwords{jj}{find(funstrwords_b{jj}>temp6(1),1,'first')};
%%%       temp9=find(strcmp(temp8,fun_name));
%%%      else
%%%       %no output arguments on this function
%%%       temp8=funstrwords{jj}{2};
%%%       temp9=find(strcmp(temp8,fun_name));
%%%      end % if ~isempty(temp6)
%%%      if ~isempty(temp9),      break,     end % if ~isempty(temp9)
%%%     end % for jj=fliplr(goon2(temp12))

%%%   'ddddddddd',funstr{i},
%%%   disp(['   fun_name{temp9} = ',num2str(   fun_name{temp9})]);
%%%   disp(['   fun_name{ii} = ',num2str(   fun_name{ii})]);
%%%   kb
% temp5 (indexed by i, is the list of lines which call the iith function in fun_name
% temp9 is which function we are in (in the fun_name list and in allLocalVar)
% i is the actual line that this fun_name{ii} call is on
     if ii==length(allLocalVar)+1 || isempty(find(strcmp(fun_name{ii},{allLocalVar{temp9}{:,1}})))
      temp6='   '; temp7='   ';
      temp17=[];
      while true
       if ii==length(allLocalVar)+1
        % assume only one use of ]=funhandle( per line
        temp=regexp(funstr{i},']=(\w+)\(','tokenExtents');
        if ~isempty(temp)
         temp=find(funstrwords_b{i}==temp{1}(1),1,'first');
        end
        %'rrrrrrrrrrr11',funstr{i},kb
       else
        temp=find(strcmp(funstrwords{i},fun_name{ii})); 
       end
       if ~isempty(temp)
        goonimag=1;
        for j=length(temp):-1:1
         if validSpot(funstr{i},funstrwords_b{i}(temp(j)))
          [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords); %args to function call
          if howmany>0
           if isempty(temp17), temp17=ones(1,howmany); end
           %go through input args, seeing if the they are scalar refs to a matrix, 
           % then if args in that subroutine are assumed shape
           centercomma=[parens(1),centercomma,parens(2)];
           temp16=[];
           for fid=1:howmany
            temp3=find(funstrwords_b{i}>centercomma(fid) & ...
                       funstrwords_b{i}<centercomma(fid+1),1,'first');
            if ~isempty(temp3)
             temp16=[temp16,temp3];
            end
           end
           for fid=1:howmany %which subscript we are in in the call
            temp3=find(funstrwords_b{i}>centercomma(fid) & ...
                       funstrwords_b{i}<centercomma(fid+1),1,'first');
            if ~isempty(temp3)
             %'ssssssssss',funstrwords{i}{temp3(1)},funstr{i},kb
             % See what function we are in and make sure this is a variable
             %hmmmm or just disallow funwords and fun_names?
             if any(strcmp({allLocalVar{temp9}{:,1}},funstrwords{i}{temp3(1)}))
              [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,temp3(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
              % sometimes they pass a scalar valued index on one input, then the entire array on
              % another input. That entire array must also be dealt with as if it were scalar 
              % indexed with 1. e.g.
              % call sub2(y(3),y(5),y)
              % should be treated as
              % call sub2(y(3),y(5),y(1))
%%%             if strcmp(funstrwords{i}{temp3},'cwrk') && any(strcmp(funstrwords{i},'cunik')) & strcmpi(this_fun_name,'cunk1') & ~informationRun
%%%              funstr{i},'aaaaaaaaaaaa',kb
%%%             end
              if howmany2==0
%if any others of temp16 have a subscript, add one to this one
               temp18=0;              
               for jj=setdiff(temp16,temp3)
                if strcmp(funstrwords{i}{temp3},funstrwords{i}{jj})
                 if funstr{i}(nextNonSpace(funstr{i},funstrwords_e{i}(jj)))=='('
                  temp18=1;
                 end % if funstr{i}(nextNonSpace(funstr{i},
                end % if strcmp(funstrwords{i}{temp16(fid)},
               end % for jj=setxor(1:howmany,
               if strcmp(funstrwords{i}{temp3},strtrim(subscripts{fid}))
                if temp18 % add a (1) to this var
                 temp20=find(funstr{i}=='[',1,'first');
                 if isempty(temp20)
                  funstr{i}=[funstr{i}(1:funstrwords_e{i}(temp3)),...
                             '(1)',funstr{i}(funstrwords_e{i}(temp3)+1:end)];
                 else
                  [outflag,howmany3,subscripts3,centercomma3,parens3]=inbracket2(funstr{i},...
                                                                    find(funstr{i}=='[',1,'first')+1);
                  centercomma3=[parens3(1),centercomma3,parens3(2)];
                  funstr{i}=[funstr{i}(1:centercomma3(fid)),subscripts3{fid},'(1)',...
                             funstr{i}(centercomma3(fid+1):funstrwords_e{i}(temp3)),...
                             '(1)',funstr{i}(funstrwords_e{i}(temp3)+1:end)];
                 end % if isempty(temp20)
                 
                 [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
                 [howmany2,subscripts2,centercomma2,parens2]=hassubscript_f(i,temp3(1),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords);
                 [howmany,subscripts,centercomma,parens]=hassubscript_f(i,temp(j),funstr,funstrnumbers,funstrnumbers_b,funstrnumbers_e,funstrwords,funstrwords_b,funstrwords_e,funwords); %args to function call
                 centercomma=[parens(1),centercomma,parens(2)];
                 %'rrrrrrrrrrr11',funstr{i},kb
                end % if temp18 % add a (1) to this var
               end % if strcmp(funstrwords{i}{temp16(fid)},
              end
              
              if howmany2>0
               centercomma2=[parens2(1),centercomma2,parens2(2)];
               %this has to be the only thing passed, no other words or nums or - outside this var
%%%              if strcmp('b',funstrwords{i}{temp3(1)})
%%%               'weeeeeeeeee',funstr{i},fid,temp3,funstr{i}(1:centercomma(fid)),funstrwords{i},kb
%%%              end
               if isempty(find(funstrwords_b{i}>centercomma(fid)&...
                               funstrwords_b{i}<funstrwords_b{i}(temp3(1))))...
                    && ...
                    isempty(find(funstrnumbers_b{i}>centercomma(fid)&...
                                 funstrnumbers_b{i}<funstrwords_b{i}(temp3(1))))...
                    &&...
                    isempty(find(funstrwords_b{i}<centercomma(fid+1)&...
                                 funstrwords_b{i}>parens2(2)))...
                    && ...
                    isempty(find(funstrnumbers_b{i}<centercomma(fid+1)&...
                                 funstrnumbers_b{i}>parens2(2)))...
                    && ...
                    isempty(find(funstr{i}(centercomma(fid):funstrwords_b{i}(temp3(1)))=='-'))
                if isempty(find(funstr{i}(parens2(1)+1:parens2(2)-1)==':')) && temp17(fid)
                 if ii==length(allLocalVar)+1
                  % here fix anonymous function calls

                  %we have a single index coming into a vector or matrix (or scalar), adjust
                  % the call to be begin:(begin+lengthinsub-1) or :end on all dims
                  %'fddddddd',funstr{i},kb
                  tempstr=subscripts{fid};
                  
                  tempstr=[funstrwords{i}{temp3(1)},'('];
                  for jj=1:length(subscripts2)
                   tempstr=[tempstr,subscripts2{jj},':end,'];
                  end % for jj=1:length(subscripts2)
                  tempstr=[tempstr(1:end-1),')'];

%%%                  if length(subscripts2)==1
%%%                   tempstr=[funstrwords{i}{temp3(1)},'(sub2ind(size(',funstrwords{i}{temp3(1)},...
%%%                            '),max(',funstr{i}(parens2(1)+1:parens2(2)-1),',1)):end)'];
%%%                  else
%%%                   tempstr=[funstrwords{i}{temp3(1)},'(sub2ind(size(',...
%%%                            funstrwords{i}{temp3(1)},...
%%%                            '),',funstr{i}(parens2(1)+1:parens2(2)-1),'):end)'];
%%%                  end

                  
                  %there might be an output var that is the same, so do a strrep
                  % if that's true, then this is the only function call on that line
                  % must be careful here, for example:
                  % t = -CDOTC(N-l+1,X(l,l),1,X(l,j),1)/X(l,l)
                  %funstr{i},'fffffffffffff',kb
                  temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp(j)));
                  if temp12>0 && funstr{i}(temp12)=='=' && funstr{i}(lastNonSpace(funstr{i},temp12))==']'
                   
                   %if funstr{i}(1)=='['%originally a subroutine call, so strrep after the fun
                   % now, sillily, different indeces, same var (iwork) can be done in fortran:
                   %CALL SS2LT(N,Nelt,Ia,Ja,A,Isym,nl,Iwork(lociel),Iwork(locjel),Rwork(locel))
%%%                    if (~isempty(temp4) && ...
%%%                         any(strcmp(temp4,funstrwords{i}{temp3(1)}))) || ...
                   if any(strcmp({funstrwords{i}{setdiff(temp16,temp3)}},...
                                 funstrwords{i}{temp3}))
%%%                     funstrwords{i}{temp3},'dddddddddd',kb
                    tempstr2=strrep(funstr{i}(funstrwords_b{i}(temp(j)):end),...
                                    funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                    tempstr);
                    funstr{i}=[strrep(funstr{i}(1:funstrwords_b{i}(temp(j))-1),...
                                      funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                      [dumvar,num2str(fid)]),...
                               tempstr2];
                    if howmany2~=1
                     temp6=[temp6,tempstr,'=',[dumvar,num2str(fid)],'; '];
                    else
                     temp7=[temp7,[dumvar,num2str(fid),'i'],'=',...
                            'find((',tempstr,')~=(',[dumvar,num2str(fid)],'));'];
                     temp6=[temp6,...
                            funstrwords{i}{temp3(1)},'(',subscripts2{1},'-1+',...
                            [dumvar,num2str(fid),'i'],')=',...
                            [dumvar,num2str(fid)],'(',[dumvar,num2str(fid),'i'],'); '];
%%%                      fid,temp6,temp7,'ttttttttttt',kb
                    end
                   elseif temp17(fid)
                    funstr{i}=strrep(...
                        funstr{i},funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),tempstr);
                   end
%%%                    temp4{fid}=funstrwords{i}{temp3(1)};
                  else % in a function, so only strrep on the arguments to this func
                   funstr{i}=[funstr{i}(1:parens(1)),...
                              strrep(funstr{i}(parens(1)+1:parens(2)-1),...
                                     funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                     tempstr),...
                              funstr{i}(parens(2):end)];
                  end
                  [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
                  goonimag=0;
                  break
                 else %not an anonymous function, regular
                      % is this an assumed shape or an array at all on the way in?
                  for goon=1:size(allLocalVar{ii},1)
                   if ~isempty(allLocalVar{ii}{goon,13}) %must be an input var
                    if allLocalVar{ii}{goon,13}==fid
                     %if ~isempty(allLocalVar{ii}{goon,5}) %must be an array in the segment itself
%%%                     if strcmp(this_fun_name,'cunk1') & ~informationRun
%%%                      'fddddddd2',funstr{i},fid,kb
%%%                     end
                     if ~isempty(allLocalVar{ii}{goon,5}) && ...
                          (any(strcmp(strtrim(allLocalVar{ii}{goon,5}),'*')) | ...
                           strcmp(allLocalVar{ii}{goon,5}{end},'1'))
                      %let's go for it
                      if length(subscripts2)==1
                       tempstr=[funstrwords{i}{temp3(1)},'(sub2ind(size(',funstrwords{i}{temp3(1)},...
                                '),max(',funstr{i}(parens2(1)+1:parens2(2)-1),',1)):end)'];
                      else
                       tempstr=[funstrwords{i}{temp3(1)},'(sub2ind(size(',funstrwords{i}{temp3(1)},...
                                '),',funstr{i}(parens2(1)+1:parens2(2)-1),'):end)'];
                       
                      end
                     else
                      %we have a single index coming into a vector, matrix, or scalar, adjust
                      % the call to be begin:(begin+lengthinsub-1) or :end on all dims
                      %'fddddddd',funstr{i},kb

%%%                  if any(strcmp(funstrwords{i},'daxpy'))
%%%                   tempstr,'iiiiiiiii',funstr{i},kb
%%%                  end

                      tempstr=subscripts{fid};
                      
                      if ~isempty(allLocalVar{ii}{goon,5}) %scalar or not
                       tempstr=[funstrwords{i}{temp3(1)},'('];
                       for jj=1:length(subscripts2)
                        %but a multiple subscript can also come into a single sub!
                        temp15=[];
                        if jj<=length(allLocalVar{ii}{goon,5})
                         temp15=find(strcmp(strtrim(allLocalVar{ii}{goon,5}{jj}),...
                                            {allLocalVar{ii}{:,1}}),1,'first');
                        end
                        if ~isempty(temp15) & length(allLocalVar{ii}{goon,5})<2
                         tempstr=[tempstr,subscripts2{jj},':',subscripts2{jj},'+',...
                                  subscripts{allLocalVar{ii}{temp15,13}},'-1,'];
                        else
                         tempstr=[tempstr,subscripts2{jj},':end,'];
                        end
                       end % for jj=1:length(subscripts2)
                       tempstr=[tempstr(1:end-1),')'];
                      else
                       temp17(fid)=0;
                      end % if ~isempty(allLocalVar{ii}{goon,
                     end 
                     %there might be an output var that is the same, so do a strrep
                     % if that's true, then this is the only function call on that line
                     % must be careful here, for example:
                     % t = -CDOTC(N-l+1,X(l,l),1,X(l,j),1)/X(l,l)
                     %funstr{i},'fffffffffffff',kb
                     temp12=lastNonSpace(funstr{i},funstrwords_b{i}(temp(j)));
                     if temp12>0 && funstr{i}(temp12)=='=' && funstr{i}(lastNonSpace(funstr{i},temp12))==']'
                      %if funstr{i}(1)=='['%originally a subroutine call, so strrep after the fun
                      % now, sillily, different indeces, same var (iwork) can be done in fortran:
                      %CALL SS2LT(N,Nelt,Ia,Ja,A,Isym,nl,Iwork(lociel),Iwork(locjel),Rwork(locel))
%%%                    if (~isempty(temp4) && ...
%%%                         any(strcmp(temp4,funstrwords{i}{temp3(1)}))) || ...
                      if any(strcmp({funstrwords{i}{setdiff(temp16,temp3)}},...
                                    funstrwords{i}{temp3}))
%%%                     funstrwords{i}{temp3},'dddddddddd',kb
                       tempstr2=strrep(funstr{i}(funstrwords_b{i}(temp(j)):end),...
                                       funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                       tempstr);
                       funstr{i}=[strrep(funstr{i}(1:funstrwords_b{i}(temp(j))-1),...
                                         funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                         [dumvar,num2str(fid)]),...
                                  tempstr2];
                       if howmany2~=1
                        temp6=[temp6,tempstr,'=',[dumvar,num2str(fid)],'; '];
                       else
                        temp7=[temp7,[dumvar,num2str(fid),'i'],'=',...
                               'find((',tempstr,')~=(',[dumvar,num2str(fid)],'));'];
                        temp6=[temp6,...
                               funstrwords{i}{temp3(1)},'(',subscripts2{1},'-1+',...
                               [dumvar,num2str(fid),'i'],')=',...
                               [dumvar,num2str(fid)],'(',[dumvar,num2str(fid),'i'],'); '];
%%%                      fid,temp6,temp7,'ttttttttttt',kb
                       end
                      elseif temp17(fid)
                       funstr{i}=strrep(...
                           funstr{i},funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),tempstr);
                      end
%%%                    temp4{fid}=funstrwords{i}{temp3(1)};
                     else % in a function, so only strrep on the arguments to this func
                      funstr{i}=[funstr{i}(1:parens(1)),...
                                 strrep(funstr{i}(parens(1)+1:parens(2)-1),...
                                        funstr{i}(funstrwords_b{i}(temp3(1)):parens2(2)),...
                                        tempstr),...
                                 funstr{i}(parens(2):end)];
                     end
                     [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
                     goonimag=0;
                     break
                     %end % if ~isempty(allLocalVar{ii}{goon,
                    end % if allLocalVar{ii}{goon,w
                   end % if ~isempty(allLocalVar{ii}{goon,
                  end % for goon=1:size(allLocalVar{temp2(j)},
                 end % if ii==length(allLocalVar)+1
                end % if isempty(find(funstr{i}(parens2(1)+1:parens2(2)-1)==':'))
               end % if isempty(find(funstrwords_b{i}>centercomma(fid)&.
              end % if howmany2>0
             end % if ~any(strcmp(temp7,
            end % if ~isempty(temp3)
            if ~goonimag, break; end
           end % for fid=1:howmany
          end % if howmany>0
         end % if validSpot(funstr{jj},
        end % for j=length(temp):-1:1
       else
        break
       end % if ~isempty(temp)
       if goonimag, break; end
      end % while true
%%%     if ~isempty(strtrim(temp6))
%%%      'xxxxxxxxxxxxxx1',funstr{i},temp6,temp7,kb
%%%     end
      if any(~isspace(temp6))
       funstr{i}=[funstr{i},temp7,temp6];
       [s,fs_good]=updatefunstr_1line_f(funstr,fs_good,i);
      end
     end % if isempty(find(strcmp(fun_name{ii},
    end % for i=temp5
   end % if ~isempty(temp5)
  end % if temp10
  
 end % for ii=1:length(allLocalVar)

 if rets(1)
  disp(['found ',num2str(rets(1)),' cases of duplicate input variables']);
 end
 if rets(2)
  disp(['cleaned up * inputs in ',num2str(rets(2)),' out of ',...
        num2str(length(allLocalVar)),' functions'])
 end
 disp(['*************** f2matlab second pass finished *************'])
%%%disp([' ii = ',num2str( ii)]);
%%%'================',kb

 % now get rid of all the funNameSuffix
 funstr=regexprep(funstr,funNameSuffix,'');
 funstr=regexprep(funstr,funHandleNameSuffix,'');

 %'dfdfdfdfdf',kb



end