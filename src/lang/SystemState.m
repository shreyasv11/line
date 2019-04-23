classdef SystemState
    % System state over time
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        model; % model handle
        t; % timestamp
        state; % joint system state
    end
    
    methods
        function self = SystemState(model, tranSysState)
            % SELF = SYSTEMSTATE(MODEL, TRANSYSSTATE)
            
            self.t = tranSysState{1};
            self.state = {tranSysState{2:end}};
            self.model = model;
        end
        
        function state = getTimestamps(self)
            % STATE = GETTIMESTAMPS(SELF)
            
            state = self.t;
        end
        
        function state = getJointState(self)
            % STATE = GETJOINTSTATE(SELF)
            
            state = cell2mat(self.state);
        end
        
        function buf = getBufferState(self, node)
            % BUF = GETBUFFERSTATE(SELF, NODE)
            
            if exist('node','var')
                qn = self.model.getStruct;
                ind = self.model.getNodeIndex(node);
                isf = qn.nodeToStateful(ind);
                ist = qn.nodeToStation(ind);
                K = qn.phasessz(ist,:);
                buf = self.state{isf}(:,1:(end-sum(K)-sum(qn.nvars(ind,:)))); % buffer state
            else
                error('getBufferState requires a node as input parameter.');
            end
        end
        
        function var = getLocalVarState(self, node)
            % VAR = GETLOCALVARSTATE(SELF, NODE)
            
            if exist('node','var')
                qn = self.model.getStruct;
                ind = self.model.getNodeIndex(node);
                isf = qn.nodeToStateful(ind);
                var = self.state{isf}(:,(end-sum(qn.nvars(ind,:))+1):end); % local var
            else
                error('getLocalVarState requires a node as input parameter.');
            end
        end
        
        function srv = getServerState(self, node)
            % SRV = GETSERVERSTATE(SELF, NODE)
            
            if exist('node','var')
                qn = self.model.getStruct;
                ind = self.model.getNodeIndex(node);
                isf = qn.nodeToStateful(ind);
                ist = qn.nodeToStation(ind);
                K = qn.phasessz(ist,:);
                srv = self.state{isf}(:,(end-sum(K)-sum(qn.nvars(ind,:))+1):(end-sum(qn.nvars(ind,:)))); % server state
            else
                error('getServerState requires a node as input parameter.');
            end
        end
    end
    
end
