function [AvgTable,TT] = getAvgTputTable(self,T,keepDisabled)
% [AVGTABLE,TT] = GETAVGTPUTTABLE(SELF,T,KEEPDISABLED)

% Return table of average station metrics
%
% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
if ~exist('keepDisabled','var')
    keepDisabled = false;
end

M = self.model.getNumberOfStations();
K = self.model.getNumberOfClasses();
if nargin == 1
    T = self.model.getAvgTputHandles();
end
TN = self.getAvgTput();
if isempty(TN)
    AvgTable = Table();
    TT = Table();
elseif ~keepDisabled
    Tval = [];
    Class = {};
    Station = {};
    for i=1:M
        for k=1:K
            if any(sum([TN(i,k)])>0)
                Class{end+1,1} = T{i,k}.class.name;
                Station{end+1,1} = T{i,k}.station.name;
                Tval(end+1) = TN(i,k);
            end
        end
    end
    Tput = Tval(:); % we need to save first in a variable named like the column
    TT = Table(Station,Class,Tput);
    AvgTable = Table(Station,Class,Tput);
else
    Tval = zeros(M,K);
    Class = cell(K*M,1);
    Station = cell(K*M,1);
    for i=1:M
        for k=1:K
            Class{(i-1)*K+k} = T{i,k}.class.name;
            Station{(i-1)*K+k} = T{i,k}.station.name;
            Tval((i-1)*K+k) = TN(i,k);
        end
    end
    Tput = Tval(:); % we need to save first in a variable named like the column
    TT = Table(Station,Class,Tput);
    AvgTable = Table(Station,Class,Tput);
end
end
