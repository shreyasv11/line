function [AvgTable,QT,UT,RT,TT] = getAvgTable(self,Q,U,R,T,keepDisabled)
% [AVGTABLE,QT,UT,RT,TT] = GETAVGTABLE(SELF,Q,U,R,T,KEEPDISABLED)
% Return table of average station metrics
%
% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.

if ~exist('keepDisabled','var')
    keepDisabled = false;
end  
M = self.model.getNumberOfStations();
K = self.model.getNumberOfClasses();
if nargin == 2
    keepDisabled = Q;
    [Q,U,R,T,~] = self.model.getAvgHandles();
elseif nargin == 1
    [Q,U,R,T,~] = self.model.getAvgHandles();
end
if isfinite(self.getOptions.timespan(2))
    [Qt,Ut,Tt] = self.model.getTranHandles();
    [QNt,UNt,TNt] = self.getTranAvg(Qt,Ut,Tt);
    QN = cellfun(@(c) c.metric(end),QNt);
    UN = cellfun(@(c) c.metric(end),UNt);
    TN = cellfun(@(c) c.metric(end),TNt);
    RN = zeros(size(QN));
else
    [QN,UN,RN,TN] = self.getAvg(Q,U,R,T);
end
if isempty(QN)
    AvgTable = Table();
    QT = Table();
    UT = Table();
    RT = Table();
    TT = Table();
    AT = Table();
elseif ~keepDisabled
    Qval = []; Uval = [];
    Rval = []; Tval = [];
    Class = {};
    Station = {};
    for i=1:M
        for k=1:K
            if any(sum([QN(i,k),UN(i,k),RN(i,k),TN(i,k)])>0)
                Class{end+1,1} = Q{i,k}.class.name;
                Station{end+1,1} = Q{i,k}.station.name;
                Qval(end+1) = QN(i,k);
                Uval(end+1) = UN(i,k);
                Rval(end+1) = RN(i,k);
                Tval(end+1) = TN(i,k);
            end
        end
    end
    QLen = Qval(:); % we need to save first in a variable named like the column
    QT = Table(Station,Class,QLen);
    Util = Uval(:); % we need to save first in a variable named like the column
    UT = Table(Station,Class,Util);
    RespT = Rval(:); % we need to save first in a variable named like the column
    RT = Table(Station,Class,RespT);
    Tput = Tval(:); % we need to save first in a variable named like the column
    TT = Table(Station,Class,Tput);
    AvgTable = Table(Station,Class,QLen,Util,RespT,Tput);
else
    Qval = zeros(M,K); Uval = zeros(M,K);
    Rval = zeros(M,K); Tval = zeros(M,K);
    Class = cell(K*M,1);
    Station = cell(K*M,1);
    for i=1:M
        for k=1:K
            Class{(i-1)*K+k} = Q{i,k}.class.name;
            Station{(i-1)*K+k} = Q{i,k}.station.name;
            Qval((i-1)*K+k) = QN(i,k);
            Uval((i-1)*K+k) = UN(i,k);
            Rval((i-1)*K+k) = RN(i,k);
            Tval((i-1)*K+k) = TN(i,k);
        end
    end
    QLen = Qval(:); % we need to save first in a variable named like the column
    QT = Table(Station,Class,QLen);
    Util = Uval(:); % we need to save first in a variable named like the column
    UT = Table(Station,Class,Util);
    RespT = Rval(:); % we need to save first in a variable named like the column
    RT = Table(Station,Class,RespT);
    Tput = Tval(:); % we need to save first in a variable named like the column
    TT = Table(Station,Class,Tput);
    AvgTable = Table(Station,Class,QLen,Util,RespT,Tput);
end
end
