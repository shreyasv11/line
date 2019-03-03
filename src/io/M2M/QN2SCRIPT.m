function QN2SCRIPT(qn, modelName, fid)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
if ~exist('modelName','var')
    modelName='qn';
end
if ~exist('fid','var')
    fid=1;
end
%% initialization
fprintf(fid,'model = Network(''%s'');\n',modelName);
rt = qn.rt;
hasSink = 0;
extID = 0;
mu=qn.mu;
phi=qn.phi;
PH=cell(qn.nstations,qn.nclasses);
for i=1:qn.nstations
    for k=1:qn.nclasses
        if length(mu{i,k})==1
            PH{i,k} = map_exponential(1/mu{i,k});
        else
            D0 = diag(-mu{i,k})+diag(mu{i,k}(1:end-1).*(1-phi{i,k}(1:end-1)),1);
            D1 = zeros(size(D0));
            D1(:,1)=(phi{i,k}.*mu{i,k});
            PH{i,k} = map_normalize({D0,D1});
        end
    end
end


%% write nodes (except ClassSwitch nodes)
for i= 1:qn.nnodes
    switch qn.nodetype(i)
        case NodeType.Source
            extID = i;
            fprintf(fid,'node{%d} = Source(model, ''Source'');\n',i);
            hasSink = 1;
        case NodeType.Delay
            fprintf(fid,'node{%d} = DelayStation(model, ''%s'');\n',i,qn.nodenames{i});
        case NodeType.Queue
            fprintf(fid,'node{%d} = Queue(model, ''%s'', SchedStrategy.%s); ', i, qn.nodenames{i}, SchedStrategy.toProperty(qn.sched{qn.nodeToStation(i)}));
            fprintf(fid,'node{%d}.setNumServers(%d);\n', i, qn.nservers(i));
        case NodeType.Router
            fprintf(fid,'node{%d} = Router(model, ''%s'');\n',i,qn.nodenames{i});
        case NodeType.Sink
            fprintf(fid,'node{%d} = Sink(model, ''%s'');\n',i,'Sink');
    end
end

%% write classes
for k = 1:qn.nclasses
    if qn.njobs(k)>0
        if isinf(qn.njobs(k))
            fprintf(fid,'jobclass{%d} = OpenClass(model, ''%s'', %d);\n',k,qn.classnames{k},qn.classprio(k));
        else
            fprintf(fid,'jobclass{%d} = ClosedClass(model, ''%s'', %d, node{%d}, %d);\n',k,qn.classnames{k},qn.njobs(k),qn.refstat(k),qn.classprio(k));
        end
    else
        % if the reference node is unspecified, as in artificial classes,
        % set it to the first node where the rate for this class is
        % non-null
        iref = 0;
        for i=1:qn.nstations
            if nnz(qn.mu{i,k})>0
                iref = i;
                break
            end
        end
        if isinf(qn.njobs(k))
            fprintf(fid,'jobclass{%d} = OpenClass(model, ''%s'', %d);\n',k,qn.classnames{k},qn.classprio(k));
        else
            fprintf(fid,'jobclass{%d} = ClosedClass(model, ''%s'', %d, node{%d}, %d);\n',k,qn.classnames{k},qn.njobs(k),iref,qn.classprio(k));
        end
    end
end

%% write class-switch nodes 
% must be instantiated after classes
for i= 1:qn.nnodes
    if qn.nodetype(i) == NodeType.ClassSwitch
        csMatrix = zeros(qn.nclasses);
        fprintf(fid,'csMatrix%d = zeros(%d);\n',i,qn.nclasses);        
        for k = 1:qn.nclasses            
            for c = 1:qn.nclasses
                for m=1:qn.nnodes
                    % routing matrix for each class
                    csMatrix(k,c) = csMatrix(k,c) + qn.rtnodes((i-1)*qn.nclasses+k,(m-1)*qn.nclasses+c);
                end
            end
        end
        for k = 1:qn.nclasses            
            for c = 1:qn.nclasses
                if csMatrix(k,c)>0
                    fprintf(fid,'csMatrix%d(%d,%d) = %f; %% %s -> %s\n',i,k,c,csMatrix(k,c),qn.classnames{k},qn.classnames{c});
                end
            end
        end
        fprintf(fid,'node{%d} = ClassSwitch(model, ''%s'', csMatrix%d);\n',i,qn.nodenames{i},i);
    end
end

%% arrival and service processes
for k=1:qn.nclasses    
    for i=1:qn.nstations
        SCVik = map_scv(PH{i,k});
        if SCVik >= 0.5
            switch qn.sched{i}
                case SchedStrategy.EXT
                    if SCVik == 1
                        fprintf(fid,'node{%d}.setArrival(jobclass{%d}, Exp.fitMean(%f)); %% (%s,%s)\n',qn.stationToNode(i),k,map_mean(PH{i,k}),qn.nodenames{qn.stationToNode(i)},qn.classnames{k});
                    else
                        fprintf(fid,'node{%d}.setArrival(jobclass{%d}, Cox2.fitMeanAndSCV(%f,%f)); %% (%s,%s)\n',qn.stationToNode(i),k,map_mean(PH{i,k}),SCVik,qn.nodenames{qn.stationToNode(i)},qn.classnames{k});
                    end
                otherwise
                    if SCVik == 1
                        fprintf(fid,'node{%d}.setService(jobclass{%d}, Exp.fitMean(%f)); %% (%s,%s)\n',qn.stationToNode(i),k,map_mean(PH{i,k}),qn.nodenames{qn.stationToNode(i)},qn.classnames{k});
                    else
                        fprintf(fid,'node{%d}.setService(jobclass{%d}, Cox2.fitMeanAndSCV(%f,%f)); %% (%s,%s)\n',qn.stationToNode(i),k,map_mean(PH{i,k}),SCVik,qn.nodenames{qn.stationToNode(i)},qn.classnames{k});
                    end
            end
        else
            % this could be made more precised by fitting into a 2-state
            % APH, especially if SCV in [0.5,0.1]
            nPhases = max(1,round(1/SCVik));
            switch qn.sched{i}
                case SchedStrategy.EXT
                    if isnan(PH{i,k}{1})
                        fprintf(fid,'node{%d}.setArrival(jobclass{%d}, Disabled()); %% (%s,%s)\n',qn.stationToNode(i),k,qn.nodenames{qn.stationToNode(i)},qn.classnames{k});
                    else
                        fprintf(fid,'node{%d}.setArrival(jobclass{%d}, Erlang(%f,%f)); %% (%s,%s)\n',qn.stationToNode(i),k,nPhases/map_mean(PH{i,k}),nPhases,qn.nodenames{qn.stationToNode(i)},qn.classnames{k});
                    end
                otherwise
                    if isnan(PH{i,k}{1})
                        fprintf(fid,'node{%d}.setService(jobclass{%d}, Disabled()); %% (%s,%s)\n',qn.stationToNode(i),k,qn.nodenames{qn.stationToNode(i)},qn.classnames{k});
                    else
                        fprintf(fid,'node{%d}.setService(jobclass{%d}, Erlang(%f,%f)); %% (%s,%s)\n',qn.stationToNode(i),k,nPhases/map_mean(PH{i,k}),nPhases,qn.nodenames{qn.stationToNode(i)},qn.classnames{k});
                    end
            end
        end
    end
end

if hasSink
    rt(qn.nstations*qn.nclasses+(1:qn.nclasses),qn.nstations*qn.nclasses+(1:qn.nclasses)) = zeros(qn.nclasses);
    for k=find(isinf(qn.njobs)) % for all open classes
        for i=1:qn.nstations
            % all open class transitions to ext station are re-routed to sink
            rt((i-1)*qn.nclasses+k, qn.nstations*qn.nclasses+k) = rt((i-1)*qn.nclasses+k, (extID-1)*qn.nclasses+k);
            rt((i-1)*qn.nclasses+k, (extID-1)*qn.nclasses+k) = 0;
        end
    end
end

fprintf(fid,'P = cellzeros(%d,%d,%d,%d); %% routing matrix \n',qn.nclasses,qn.nclasses,qn.nnodes,qn.nnodes);
for k = 1:qn.nclasses
    for c = 1:qn.nclasses       
        for i=1:qn.nnodes
            for m=1:qn.nnodes
                % routing matrix for each class
                myP{k,c}(i,m) = qn.rtnodes((i-1)*qn.nclasses+k,(m-1)*qn.nclasses+c);
                if myP{k,c}(i,m) > 0
                    % do not change %d into %f to avoid round-off errors in
                    % the total probability
                    fprintf(fid,'P{%d,%d}(%d,%d) = %d; %% (%s,%s) -> (%s,%s)\n',k,c,i,m,myP{k,c}(i,m),qn.nodenames{i},qn.classnames{k},qn.nodenames{m},qn.classnames{c});
                end
            end
        end
        %fprintf(fid,'P{%d,%d} = %s;\n',k,c,mat2str(myP{k,c}));
    end
end

fprintf(fid,'model.link(P);\n');

end