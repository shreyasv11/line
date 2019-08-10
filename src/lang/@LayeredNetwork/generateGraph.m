function self = generateGraph(self)
% SELF = GENERATEGRAPH()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

wantCalls = true;
wantProcs = true;
self.lqnGraph = digraph();
% add processors
self.nodeDep = [];
fullname = {};
name = {};
type = {};
object = {};
EndNodes = [];
Weight = [];
Object = [];
demand = [];
multiplicity = [];
%boundToEntry = [];
host_proc = {};
host_task = {};
host_entry = {};
maxjobs = [];
nodeDep = [];
ctrp = 0; ctrt = 0; ctre = 0; ctrap = 0; ctras = 0;
for p=1:length(self.processors)
    ctrp = ctrp + 1;
    fullname{end+1} = self.processors(p).name;
    type{end+1} = 'P';
    hostname = sprintf('P%d',ctrp);
    name{end+1} = sprintf('P%d',ctrp);
    pidx = length(name);
    object{end+1} = self.processors(p);
    demand(end+1)= 0.0;
    multiplicity(end+1)= object{end}.multiplicity;
    %    boundToEntry(end+1)=false;
    host_proc{end+1}= '';
    host_task{end+1}= '';
    host_entry{end+1}= '';
    nodeDep(end+1,1:3) = [NaN,NaN,NaN];
    for t=1:length(self.processors(p).tasks)
        ctrt = ctrt + 1;
        fullname{end+1} = self.processors(p).tasks(t).name;
        name{end+1} = sprintf('T%d',ctrt);
        tidx = length(name);
        taskname = name{end};
        demand(end+1)= self.processors(p).tasks(t).thinkTimeMean;
        object{end+1} = self.processors(p).tasks(t);
        multiplicity(end+1)= object{end}.multiplicity;
        %        boundToEntry(end+1)=false;
        host_proc{end+1}= hostname;
        host_task{end+1}= '';
        host_entry{end+1}= '';
        nodeDep(end+1,1:3) = [pidx,NaN,NaN];
        switch self.processors(p).tasks(t).scheduling
            case 'ref'
                type{end+1} = 'R'; % reference task
                maxjobs(:,end+1) =  multiplicity(end);
            otherwise
                type{end+1} = 'T';
        end
        for e=1:length(self.processors(p).tasks(t).entries)
            ctre = ctre + 1;
            fullname{end+1} = self.processors(p).tasks(t).entries(e).name;
            name{end+1} = sprintf('E%d',ctre);
            eidx = length(name);
            entryname = name{end};
            type{end+1} = 'E';
            demand(end+1)= 0.0;
            object{end+1} = self.processors(p).tasks(t).entries(e);
            multiplicity(end+1)= NaN;
            %            boundToEntry(end+1)=false;
            host_proc{end+1}= hostname;
            host_task{end+1}= taskname;
            host_entry{end+1}= '';
            nodeDep(end+1,1:3) = [pidx,tidx,NaN];
            for a=1:length(self.processors(p).tasks(t).entries(e).activities)
                ctrap = ctrap + 1;
                fullname{end+1} = self.processors(p).tasks(t).entries(e).activities(a).name;
                demand(end+1)= self.processors(p).tasks(t).entries(e).activities(a).hostDemandMean;
                %                name{end+1} = sprintf('AH%d(%.3f)',ctrap,demand(end));
                name{end+1} = sprintf('AH%d',ctrap);
                nodeDep(end+1,1:3) = [pidx,tidx,eidx];
                type{end+1} = 'AH';
                object{end+1} = self.processors(p).tasks(t).entries(e).activities(a);
                multiplicity(end+1)= NaN;
                %                boundToEntry(end+1)=false;
                %                if ~isempty(object{end}.boundToEntry)
                %                    boundToEntry(end)=true;
                %                end
                host_proc{end+1}= hostname;
                host_task{end+1}= taskname;
                host_entry{end+1}= entryname;
            end
        end
        for a=1:length(self.processors(p).tasks(t).activities)
            ctras = ctras + 1;
            fullname{end+1} = self.processors(p).tasks(t).activities(a).name;
            demand(end+1)= self.processors(p).tasks(t).activities(a).hostDemandMean;
            %            name{end+1} = sprintf('AS%d(%.3f)',ctras,demand(end));
            name{end+1} = sprintf('AS%d',ctras);
            type{end+1} = 'AS';
            object{end+1} = self.processors(p).tasks(t).activities(a);
            multiplicity(end+1)= NaN;
            %            boundToEntry(end+1)=false;
            %            if ~isempty(object{end}.boundToEntry)
            %                boundToEntry(end)=true;
            %            end
            host_proc{end+1}= hostname;
            host_task{end+1}= taskname;
            host_entry{end+1}= 'NaN';
            if ~isempty(object{end}.boundToEntry)
                host_entry{end}= name{findstring(fullname,object{end}.boundToEntry)};
                eidx = findstring(name,host_entry{end});
                nodeDep(end+1,1:3) = [pidx,tidx,eidx];
            else
                nodeDep(end+1,1:3) = [pidx,tidx,NaN];
            end
        end
    end
end

myTable = Table();%'RowNames',name(:));
myTable.Name = name(:);
self.nodeNames = name(:);
myTable.Type = type(:);
myTable.Proc = host_proc(:);
myTable.Task = host_task(:);
myTable.Entry = host_entry(:);
myTable.D = demand(:);
myTable.Mult = multiplicity(:);
%myTable.BtoE = boundToEntry(:);
myTable.MaxJobs = repmat(maxjobs,height(myTable),1);
myTable.Node = fullname(:);
myTable.Object = object(:);
self.lqnGraph = self.lqnGraph.addnode(myTable);
self.nodeDep = nodeDep;
proc = self.processors;
EndNodes = [];
Weight = [];
EdgeType = [];
PostType = [];
PreType = [];
for p=1:length(proc)
    tasks_p = proc(p).tasks;
    for t=1:length(tasks_p)
        if wantProcs
            EndNodes(end+1,1) = findstring(self.lqnGraph.Nodes.Node,proc(p).tasks(t).name);
            EndNodes(end,2) = findstring(self.lqnGraph.Nodes.Node,proc(p).name);
            Weight(end+1,1) = 1.0;
            EdgeType(end+1,1) = 0; % within task
            PreType(end+1,1) = 0; % single
            PostType(end+1,1) = 0; % single
        end
        entries_tp = tasks_p(t).entries;
        for e=1:length(entries_tp)
            EndNodes(end+1,1) = findstring(self.lqnGraph.Nodes.Node,tasks_p(t).name);
            EndNodes(end,2) = findstring(self.lqnGraph.Nodes.Node,entries_tp(e).name);
            Weight(end+1,1) = 1.0;
            EdgeType(end+1,1) = 0; % within task
            PreType(end+1,1) = 0; % single
            PostType(end+1,1) = 0; % single
            
            hw_act_etp = entries_tp(e).activities; % hw activities
            for a=1:length(hw_act_etp)
                EndNodes(end+1,1) = findstring(self.lqnGraph.Nodes.Node,entries_tp(e).name);
                EndNodes(end,2) = findstring(self.lqnGraph.Nodes.Node,hw_act_etp(a).name);
                Weight(end+1,1) = 1.0;
                EdgeType(end+1,1) = 0; % within task
                PreType(end+1,1) = 0; % single
                PostType(end+1,1) = 0; % single
            end
        end
        
        sw_act_tp = tasks_p(t).activities; % sw activities
        for a=1:length(sw_act_tp)
            if ~isempty(sw_act_tp(a).boundToEntry)
                EndNodes(end+1,1) = findstring(self.lqnGraph.Nodes.Node,sw_act_tp(a).boundToEntry);
                EndNodes(end,2) = findstring(self.lqnGraph.Nodes.Node,sw_act_tp(a).name);
                Weight(end+1,1) = 1.0;
                EdgeType(end+1,1) = 0; % within task
                PreType(end+1,1) = 0; % single
                PostType(end+1,1) = 0; % single
            end
            
            for d=1:length(tasks_p(t).precedences)
                if strcmp(tasks_p(t).precedences(d).pres{1},sw_act_tp(a).name)
                    switch tasks_p(t).precedences(d).preType
                        case 'single'
                            switch tasks_p(t).precedences(d).postType
                                case 'single'
                                    EndNodes(end+1,1) = findstring(self.lqnGraph.Nodes.Node, tasks_p(t).precedences(d).pres{1});
                                    EndNodes(end,2) = findstring(self.lqnGraph.Nodes.Node, tasks_p(t).precedences(d).posts{1});
                                    Weight(end+1,1) = 1.0;
                                    EdgeType(end+1,1) = 0; % within task
                                    PreType(end+1,1) = 0; % single
                                    PostType(end+1,1) = 0; % single
                                otherwise
                                    error('Precedence is not supported yet.');
                            end
                        otherwise
                            error('Precedence is not supported yet.');
                    end
                end
            end
            
            if wantCalls
                synchCallDests = sw_act_tp(a).synchCallDests;
                for sd=1:length(synchCallDests)
                    EndNodes(end+1,1) = findstring(self.lqnGraph.Nodes.Node,sw_act_tp(a).name);
                    EndNodes(end,2) = findstring(self.lqnGraph.Nodes.Node,synchCallDests{sd});
                    Weight(end+1,1) = sw_act_tp(a).synchCallMeans(sd);
                    EdgeType(end+1,1) = 1; % sync
                    PreType(end+1,1) = 0; % single
                    PostType(end+1,1) = 0; % single
                end
                
                
                asynchCallDests = sw_act_tp(a).asynchCallDests;
                for asd=1:length(asynchCallDests)
                    EndNodes(end+1,1) = findstring(self.lqnGraph.Nodes.Node,sw_act_tp(a).name);
                    EndNodes(end,2) = findstring(self.lqnGraph.Nodes.Node,asynchCallDests{asd});
                    Weight(end+1,1) = sw_act_tp(a).asynchCallMeans(asd);
                    EdgeType(end+1,1) = 2; % async
                    PreType(end+1,1) = 0; % single
                    PostType(end+1,1) = 0; % single
                end
                
                %                 fwdCallDests = sw_act_tp(a).fwdCallDests;
                %                 for asd=1:length(fwdCallDests)
                %                     EndNodes(end+1,1) = sw_act_tp(a).name;
                %                     EndNodes(end,2) = fwdCallDests{sd};
                %                     Weight(end+1,1) = sw_act_tp(a).fwdCallMeans;
                %                     Type(end+1,1) = 3; % forwarding
                %                 end
            end
        end
    end
end

for e=1:size(EndNodes,1)
    source = EndNodes(e,1);
    target = EndNodes(e,2);
    self.lqnGraph = self.lqnGraph.addedge(name{source},name{target},Weight(e,1));
end

for e=1:size(EndNodes,1) % do not merge with previous as addedge does mess
    source = EndNodes(e,1);
    target = EndNodes(e,2);
    eid = self.lqnGraph.findedge(name{source},name{target});
    self.endNodes(eid,1) = EndNodes(e,1); % someone addedge does not preserve the order
    self.endNodes(eid,2) = EndNodes(e,2);
    self.lqnGraph.Edges.Type(eid)=EdgeType(e,1);
    self.lqnGraph.Edges.Pre(eid)=PreType(e,1);
    self.lqnGraph.Edges.Post(eid)=PostType(e,1);
end

% fix all activities
for j=find(cellfun(@(c) strcmpi(c,'NaN'),self.lqnGraph.Nodes.Entry))'
    self.lqnGraph.Nodes.Entry{j} = self.findEntryOfActivity(self.lqnGraph.Nodes.Name{j});
end
% for i=1:numnodes(G)
%     if isempty(successors(G,i))
%         if ~strcmpi(G.Nodes.Type{i},'AH')
%             %G.Nodes.Type{i}='X';
%         end
%     end
% end

% put processors as target of hosted task
keep = ([findstring(self.lqnGraph.Nodes.Type,'P'); findstring(self.lqnGraph.Nodes.Type,'R'); findstring(self.lqnGraph.Nodes.Type,'T')]);
taskGraph = self.lqnGraph.subgraph(keep(keep>0)); % ignore missing types
% now H contains all tasks and edges to the processors they run on
% we add external calls

actset = [findstring(self.lqnGraph.Nodes.Type,'AS')]';
entryset = [findstring(self.lqnGraph.Nodes.Type,'E')]';
for s = actset(actset>0)
    source_activity = self.getNodeName(s);
    source_task = self.getNodeTask(source_activity);
    entryset = self.lqnGraph.successors(s)';
    for t = entryset(entryset>0)
        if strcmpi(self.getNodeType(t),'E')
            target_task = self.getNodeTask(t);
            edge = self.findEdgeIndex(s, t);
            if edge
                weight = exp(self.lqnGraph.Edges.Weight(edge));
                try
                    taskGraph=taskGraph.addedge(source_task, target_task, weight);
                end
            end
        end
    end
end

self.param.Nodes.RespT=zeros(height(self.lqnGraph.Nodes),1);
self.param.Nodes.Util=zeros(height(self.lqnGraph.Nodes),1);
self.param.Nodes.Tput=zeros(height(self.lqnGraph.Nodes),1);

self.param.Edges.RespT=zeros(height(self.lqnGraph.Edges),1);
self.param.Edges.Tput=zeros(height(self.lqnGraph.Edges),1);

self.lqnGraph = self.lqnGraph;
self.taskGraph = taskGraph;
end
