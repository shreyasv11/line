classdef laneSet < BPMN.baseElement
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    name;       % string
    lane;       % set of lanes 
end

methods
%public methods, including constructor

    %constructor
    function obj = laneSet(id, name)
        if(nargin == 0)
            disp('No ID provided for this laneSet'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp(['No name provided for laneSet ', id]); 
            name = ['laneSet_',id];
        end
        obj@BPMN.baseElement(id); 
        obj.name = name;
    end
    
    function obj = addLane(obj, lane)
       if nargin > 1
            if isempty(obj.lane)
                obj.lane = lane;
            else
                obj.lane(end+1,1) = lane;
            end
       end
    end

end
    
end