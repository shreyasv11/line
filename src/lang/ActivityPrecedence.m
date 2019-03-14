classdef ActivityPrecedence
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        pres  = cell(0);        %string array
        posts = cell(0);        %string array
        preType = 'single';     %string \in {'single', 'OR', 'AND'}
        postType = 'single';    %string \in {'single', 'OR', 'AND'}
        postProbs = [];         %double array (column)
    end
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = ActivityPrecedence(pres, posts, preType, postType, postProbs)
            if nargin == 3
                obj.pres = pres;
                obj.posts = posts;
            else
                obj.pres = pres;
                obj.posts = posts;
                obj.preType = preType;
                obj.postType = postType;
                obj.postProbs = postProbs;
            end
        end
        
    end
    
    methods (Static)
        function ap = Serial(varargin)
            ap = cell(1,nargin-1);
            for m=1:nargin-1
                preActObj = varargin{m};
                postActObj = varargin{m+1};
                ap{m} = ActivityPrecedence({preActObj.name},{postActObj.name},'single','single',1.0);
            end
        end
    end
end