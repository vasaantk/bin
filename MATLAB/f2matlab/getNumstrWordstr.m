%%%if (exist ('OCTAVE_VERSION'))
%%% numstr='((\b[0-9]+)?\.)?\b[0-9]+([eEdDqQ][-+]?[0-9]+)?\b';
%%%else
numstr='(\<(\d+\.\d+|\d+\.|\.\d+|\d+)([eEdDqQ][+-]?\d+)?)';
%%%end
%wordstr='(\<[a-z_A-Z]\w*)';
% need to add a dollar sign to the \w
wordstr='(\<[a-z_A-Z][a-z_A-Z0-9\$]*)';



%numstr='(\<(\d+\.\d+|\d+\.|\.\d+|\d+)([eEdDqQ][+-]?\d+)?)';
%wordstr='(\<[a-z_A-Z]\w*)';
%ss='a11(de(2))-3.111d+21.*.322E-1*(-21.4e-2./b3.'') .or. 2.3+.12-2. - sqrt(fe_b(a(2)))';
%regexp(ss,'\<(\d+\.\d+|\d+\.|\.\d+|\d+)([eEdD][+-]?\d+)?','match'); % this gets the numbers
%regexp(ss,'\<[a-z_A-Z]\w*','match') % this gets the words
