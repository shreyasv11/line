classdef Node < matlab.mixin.Copyable
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        model;
        name;
        input;
        server;
        output;
    end
        
    methods(Hidden)
        %Constructor
        function self = Node(name)
            self.name = name;
        end
        
        function self = setModel(self, model)
            self.model = model;
        end
        
        function self = link(self, nodeTo)
            self.model.addLink(self,nodeTo);
        end
    end
    
    methods
        function sections = getSections(self)
            sections = {self.input, self.server, self.output};
        end
        
        function setProbRouting(self, class, destination, probability)
            self.setRouting(class, RoutingStrategy.PROB, destination, probability);
        end
        
        function setScheduling(self, class, strategy)
            self.input.inputJobClasses{class.index}{2} = strategy;
        end
        
        function setRouting(self, class, strategy, destination, probability)
            switch nargin
                case 3
                    self.output.outputStrategy{1, class.index}{2} = RoutingStrategy.toType(strategy);
                case 5
                    self.output.outputStrategy{1, class.index}{2} = RoutingStrategy.toType(strategy);
                    if length(self.output.outputStrategy{1, class.index})<3
                        self.output.outputStrategy{1, class.index}{3}{1} = {destination, probability};
                    else
                        self.output.outputStrategy{1, class.index}{3}{end+1} = {destination, probability};
                    end
            end
        end

        function bool = hasClassSwitch(self)
            bool = isa(self.server,'ClassSwitchSection');
        end
        
        function bool = isStateful(self)
            bool = isa(self,'StatefulNode');
        end

        function bool = isStation(self)
            bool = isa(self,'Station');
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@matlab.mixin.Copyable(self);
            % Make a deep copy of each object
            clone.input = self.input.copy;
            clone.server = self.server.copy;
            clone.output = self.output.copy;
        end        
    end
    
    methods (Access = public)
        function ind = subsindex(self)
            ind = double(self.model.getNodeIndex(self.name))-1; % 0 based
        end
        
        function V = horzcat(self, varargin)
            V = zeros(1,length(varargin));
            V(1) = 1+ self.subsindex;
            for v=1:length(varargin)
                V(1+v) = 1+varargin{v}.subsindex;
            end
        end
        
        function V = vertcat(self, varargin)
            V = zeros(length(varargin),1);
            V(1) = 1+ self.subsindex;
            for v=1:length(varargin)
                V(1+v) = 1+varargin{v}.subsindex;
            end
        end
    end
end