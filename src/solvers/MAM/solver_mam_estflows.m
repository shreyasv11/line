function ARV = solver_mam_estflows(qn, DEP, config)
% ARV = SOLVER_MAM_ESTFLOWS(QN, DEP, CONFIG)
% DEP{i,r} is the departure process of class r from i in (D0,D1) format

I = qn.nnodes;
C = qn.nchains;
R = qn.nclasses;

% In this function we use indexing over all non-ClassSwitch nodes
non_cs_classes = [];
isNCS = zeros(1,I);
nodeToNCS = zeros(1,I);
for ind=1:I
    if qn.nodetype(ind) ~= NodeType.ClassSwitch
        non_cs_classes(end+1:end+R)= ((ind-1)*R+1):(ind*R);
        isNCS(ind) = true;
        nodeToNCS(ind) = sum(isNCS);
    else
        isNCS(ind) = false;
    end
end

% Hide the nodes that are not class switches
rtncs = dtmc_stochcomp(qn.rtnodes,non_cs_classes);
Inc = I - sum(qn.nodetype == NodeType.ClassSwitch);

MMAP = DEP; % PH renewal process initially in (D0,D1) format

% We now bring into MMAP format with a single class
for ist=1:size(MMAP,1)
    for r=1:size(MMAP,2)
        if isnan(MMAP{ist,r}{1})
            MMAP{ist,r} = map_exponential(Inf); % no arrivals from this class
        end
        MMAP{ist,r}{3} = MMAP{ist,r}{2};
    end
end

ARV = cell(Inc,1);
DEP = cell(Inc,R);
LINKS = cell(Inc,Inc);
% first we determine all outgoing flows from all stations
for ind=1:I
    if isNCS(ind)
        inc = nodeToNCS(ind);
        switch qn.nodetype(ind)
            case {NodeType.Source, NodeType.Delay, NodeType.Queue}
                ist = qn.nodeToStation(ind);
                
                % obtain departure maps
                DEP{inc} = mmap_super({MMAP{ist,1:R}});
                
                Psplit = zeros(R,Inc*R);
                for r=1:R % superpose all classes
                    for jnd = 1:I %to
                        if isNCS(jnd)
                            jnc = nodeToNCS(jnd);
                            for s=1:R %to
                                Psplit(r,(jnc-1)*R+s) = rtncs((inc-1)*R+r, (jnc-1)*R+s);
                            end
                        end
                    end
                end
                [Fsplit{1:Inc}] = estflows_split_cs(DEP{inc}, Psplit, config);
                for jnc=1:Inc
                    LINKS{inc,jnc} = Fsplit{jnc};
                end
        end
    end
end

% then we determine all incoming flows from all stations
for ind=1:I
    if isNCS(ind)
        inc = nodeToNCS(ind);
        ARV{ind} = estflows_merge({LINKS{1:Inc,inc}}, config);               
    else
        ARV{ind} = [];
    end
end

end
