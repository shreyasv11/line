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
for i = 1:qn.nstations
    switch qn.sched{i}
        case SchedStrategy.INF
            fprintf(fid,'node{%d} = DelayStation(model, ''%s'');\n',i,qn.nodenames{qn.stationToNode(i)});
        case SchedStrategy.EXT
            extID = i;
            fprintf(fid,'node{%d} = Source(model, ''Source'');\n',i);
            hasSink = 1;
        otherwise
            fprintf(fid,'node{%d} = Queue(model, ''%s'', SchedStrategy.%s); ', i, qn.nodenames{qn.stationToNode(i)}, SchedStrategy.toProperty(qn.sched{i}));
            fprintf(fid,'node{%d}.setNumServers(%d);\n', i, qn.nservers(i));
    end
end
if hasSink
    fprintf(fid,'node{%d} = Sink(model, ''%s'');\n',qn.nstations+1,'Sink');
end
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
    
    for i=1:qn.nstations
        SCVik = map_scv(PH{i,k});
        if SCVik >= 0.5
            switch qn.sched{i}
                case SchedStrategy.EXT
                    fprintf(fid,'node{%d}.setArrival(jobclass{%d}, Cox2.fitMeanAndSCV(%f,%f));\n',i,k,map_mean(PH{i,k}),SCVik);
                otherwise
                    fprintf(fid,'node{%d}.setService(jobclass{%d}, Cox2.fitMeanAndSCV(%f,%f));\n',i,k,map_mean(PH{i,k}),SCVik);
            end
        else
            % this could be made more precised by fitting into a 2-state
            % APH, especially if SCV in [0.5,0.1]
            nPhases = max(1,round(1/SCVik));
            switch qn.sched{i}
                case SchedStrategy.EXT
                    if isnan(PH{i,k}{1})
                        fprintf(fid,'node{%d}.setArrival(jobclass{%d}, Disabled());\n',i,k);
                    else
                        fprintf(fid,'node{%d}.setArrival(jobclass{%d}, Erlang(%f,%f));\n',i,k,nPhases/map_mean(PH{i,k}),nPhases);
                    end
                otherwise
                    if isnan(PH{i,k}{1})
                        fprintf(fid,'node{%d}.setService(jobclass{%d}, Disabled());\n',i,k);
                    else
                        fprintf(fid,'node{%d}.setService(jobclass{%d}, Erlang(%f,%f));\n',i,k,nPhases/map_mean(PH{i,k}),nPhases);
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

fprintf(fid,'P = cell(%d);\n',qn.nclasses);
for k = 1:qn.nclasses
    for c = 1:qn.nclasses
        for i=1:(qn.nstations+hasSink)
            for m=1:(qn.nstations+hasSink)
                % routing matrix for each class
                myP{k,c}(i,m) = rt((i-1)*qn.nclasses+k,(m-1)*qn.nclasses+c);
            end
        end
        fprintf(fid,'P{%d,%d} = %s;\n',k,c,mat2str(myP{k,c}));
    end
end

fprintf(fid,'model.link(P);\n');

end