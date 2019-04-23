classdef NodeState
    % Enumeration of node types.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        node; % model handle
        t; % timestamp
        state; % node state
    end
    
    methods
        function self = NodeState(node, tranState)
            % SELF = NODESTATE(NODE, TRANSTATE)
            
            self.t = tranState{1};
            self.state = tranState{2};
            self.node = node;
        end
        
        function state = getTimestamps(self)
            % STATE = GETTIMESTAMPS(SELF)
            
            state = self.t;
        end
        
        function state = getState(self)
            % STATE = GETSTATE(SELF)
            
            state = self.state;
        end
        
        function buf = getBufferState(self)
            % BUF = GETBUFFERSTATE(SELF)
            
            qn = self.node.model.getStruct;
            ind = self.node.model.getNodeIndex(self.node);
            ist = qn.nodeToStation(ind);
            K = qn.phasessz(ist,:);
            buf = self.state(:,1:(end-sum(K)-sum(qn.nvars(ind,:)))); % buffer state
        end
        
        function var = getLocalVarState(self)
            % VAR = GETLOCALVARSTATE(SELF)
            
            qn = self.node.model.getStruct;
            ind = self.node.model.getNodeIndex(self.node);
            var = self.state(:,(end-sum(qn.nvars(ind,:))+1):end); % local var
        end
        
        function srv = getServerState(self)
            % SRV = GETSERVERSTATE(SELF)
            
            qn = self.node.model.getStruct;
            ind = self.node.model.getNodeIndex(self.node);
            ist = qn.nodeToStation(ind);
            K = qn.phasessz(ist,:);
            srv = self.state(:,(end-sum(K)-sum(qn.nvars(ind,:))+1):(end-sum(qn.nvars(ind,:)))); % server state
        end
    end
    
end
