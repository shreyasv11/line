function [AvgTable,QT] = getAvgQLenTable(self,Q,keepDisabled)
% [AVGTABLE,QT] = GETAVGQLENTABLE(SELF,Q,KEEPDISABLED)

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
    Q = self.model.getAvgQLenHandles();
end
QN = self.getAvgQLen();
if isempty(QN)
    AvgTable = Table();
    QT = Table();
elseif ~keepDisabled
    Qval = [];
    Class = {};
    Station = {};
    for i=1:M
        for k=1:K
            if any(sum([QN(i,k)])>0)
                Class{end+1,1} = Q{i,k}.class.name;
                Station{end+1,1} = Q{i,k}.station.name;
                Qval(end+1) = QN(i,k);
            end
        end
    end
    QLen = Qval(:); % we need to save first in a variable named like the column
    QT = Table(Station,Class,QLen);
    AvgTable = Table(Station,Class,QLen);
else
    Qval = zeros(M,K);
    Class = cell(K*M,1);
    Station = cell(K*M,1);
    for i=1:M
        for k=1:K
            Class{(i-1)*K+k} = Q{i,k}.class.name;
            Station{(i-1)*K+k} = Q{i,k}.station.name;
            Qval((i-1)*K+k) = QN(i,k);
        end
    end
    QLen = Qval(:); % we need to save first in a variable named like the column
    QT = Table(Station,Class,QLen);
    AvgTable = Table(Station,Class,QLen);
end
end
