function [AvgTable,QT,UT,RT,TT] = getNodeAvgTable(self,Q,U,R,T,keepDisabled)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
if ~exist('keepDisabled','var')
    keepDisabled = false;
end
qn = self.model.getStruct;
I = self.model.getNumberOfNodes();
K = self.model.getNumberOfClasses();
if nargin == 1
    [Q,U,R,T] = self.model.getAvgHandles();
end
[QN,UN,RN,TN] = self.getNodeAvg(Q,U,R,T);
if isempty(QN)
    AvgTable = Table();
    QT = Table();
    UT = Table();
    RT = Table();
    TT = Table();
elseif ~keepDisabled
    Qval = []; Uval = [];
    Rval = []; Tval = [];
    Class = {};
    Node = {};
    for i=1:I
        for k=1:K
            if any(sum([QN(i,k),UN(i,k),RN(i,k),TN(i,k)])>0)
                Class{end+1,1} = qn.classnames{k};
                Node{end+1,1} = qn.nodenames{i};
                Qval(end+1) = QN(i,k);
                Uval(end+1) = UN(i,k);
                Rval(end+1) = RN(i,k);
                Tval(end+1) = TN(i,k);
            end
        end
    end
    QLen = Qval(:); % we need to save first in a variable named like the column
    QT = Table(Node,Class,QLen);
    Util = Uval(:); % we need to save first in a variable named like the column
    UT = Table(Node,Class,Util);
    RespT = Rval(:); % we need to save first in a variable named like the column
    RT = Table(Node,Class,RespT);
    Tput = Tval(:); % we need to save first in a variable named like the column
    TT = Table(Node,Class,Tput);
    AvgTable = Table(Node,Class,QLen,Util,RespT,Tput);
else
    Qval = zeros(I,K); Uval = zeros(I,K);
    Rval = zeros(I,K); Tval = zeros(I,K);
    Class = cell(K*I,1);
    Node = cell(K*I,1);
    for i=1:I
        for k=1:K
            Class{end+1,1} = qn.classnames{k};
            Node{end+1,1} = qn.nodenames{i};
            Qval((i-1)*K+k) = QN(i,k);
            Uval((i-1)*K+k) = UN(i,k);
            Rval((i-1)*K+k) = RN(i,k);
            Tval((i-1)*K+k) = TN(i,k);
        end
    end
    QLen = Qval(:); % we need to save first in a variable named like the column
    QT = Table(Node,Class,QLen);
    Util = Uval(:); % we need to save first in a variable named like the column
    UT = Table(Node,Class,Util);
    RespT = Rval(:); % we need to save first in a variable named like the column
    RT = Table(Node,Class,RespT);
    Tput = Tval(:); % we need to save first in a variable named like the column
    TT = Table(Node,Class,Tput);
    AvgTable = Table(Node,Class,QLen,Util,RespT,Tput);
end
end