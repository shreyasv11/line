classdef ActivityPrecedence
    % An auxiliary class to specify precedence among Activity elements.
    %
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
            % OBJ = ACTIVITYPRECEDENCE(PRES, POSTS, PRETYPE, POSTTYPE, POSTPROBS)
            
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
            % AP = SERIAL(VARARGIN)
            
            ap = cell(1,nargin-1);
            for m=1:nargin-1
                preActObj = varargin{m};
                postActObj = varargin{m+1};
                ap{m} = ActivityPrecedence({preActObj.name},{postActObj.name},'single','single',1.0);
            end
        end
    end
end
