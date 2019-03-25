function model = QN2LINE(qn, modelName)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
if ~exist('modelName','var')
    modelName = 'qn';
end
%%
M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes
rt = qn.rt;
NK = qn.njobs;  % initial population per class
Ktrue = nnz(NK); % classes that are not artificial

%% initialization
model = Network(modelName);
hasSink = 0;
idSource = [];
for i = 1:M
    switch qn.sched{i}
        case SchedStrategy.INF
            node{i} = DelayStation(model, qn.stationnames{i});
        case SchedStrategy.FORK
            node{i} = ForkStation(model, qn.stationnames{i});
        case SchedStrategy.EXT
            node{i} = Source(model, 'Source'); idSource = i;
            node{M+1} = Sink(model, 'Sink'); hasSink = 1;
        otherwise
            node{i} = Queue(model, qn.stationnames{i}, qn.sched{i});
            node{i}.setNumServers(qn.nservers(i));
    end
end

mu=qn.mu;
phi=qn.phi;
PH=cell(M,K);
for i=1:M
    for k=1:K
        PH{i,k} = Coxian(mu{i,k}, phi{i,k}).getRenewalProcess();
    end
end

for k = 1:K
    if k<=Ktrue
        if isinf(NK(k))
            jobclass{k} = OpenClass(model, qn.classnames{k}, 0);
        else
            jobclass{k} = ClosedClass(model, qn.classnames{k}, NK(k), node{qn.refstat(k)}, 0);
        end
    else
        % if the reference node is unspecified, as in artificial classes,
        % set it to the first node where the rate for this class is
        % non-null
        for i=1:M
            if nnz(qn.mu{i,k})>0
                break
            end
        end
        if isinf(NK(k))
            jobclass{k} = OpenClass(model, qn.classnames{k});
        else
            jobclass{k} = ClosedClass(model, qn.classnames{k}, NK(k), node{i}, 0);
        end
    end
    
    for i=1:M
        SCVik = map_scv(PH{i,k});
        if SCVik >= 0.5
            switch qn.sched{i}
                case SchedStrategy.EXT
                    node{i}.setArrival(jobclass{k}, Cox2.fitMeanAndSCV(map_mean(PH{i,k}),SCVik));
                case SchedStrategy.FORK
                    % do nothing
                otherwise
                    node{i}.setService(jobclass{k}, Cox2.fitMeanAndSCV(map_mean(PH{i,k}),SCVik));
            end
        else
            % this could be made more precised by fitting into a 2-state
            % APH, especially if SCV in [0.5,0.1]
            nPhases = max(1,round(1/SCVik));
            switch qn.sched{i}
                case SchedStrategy.EXT
                    node{i}.setArrival(jobclass{k}, Erlang(nPhases/map_mean(PH{i,k}),nPhases));
                case SchedStrategy.FORK
                    % do nothing
                otherwise
                    node{i}.setService(jobclass{k}, Erlang(nPhases/map_mean(PH{i,k}),nPhases));
            end
        end
    end
end

myP = cell(K,K);
for k = 1:K
    for c = 1:K
        myP{k,c} = zeros(M+hasSink);
        for i=1:M
            for m=1:M
                % routing matrix for each class
                if hasSink && m == idSource % direct to sink
                    myP{k,c}(i,M+1) = rt((i-1)*K+k,(m-1)*K+c);
                else
                    myP{k,c}(i,m) = rt((i-1)*K+k,(m-1)*K+c);                    
                end
            end
        end
    end
end

model.link(myP);
end