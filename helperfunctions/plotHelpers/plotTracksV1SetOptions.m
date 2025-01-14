function options = plotTracksV1SetOptions(varargin)
% plotTracksV1SetOptions   set default options for plotTracksV1
% 
% options = plotTracksV1SetOptions;
%
% OUTPUT:
%   options: structured array with the following fields:
%

options = struct;

if (nargin == 0 || ischar(varargin{1}))
    options = struct('tracks',[],...
        'h',[],...
        'ha',[],...
        'colorByValue',1,...
        'tracksVal',[],...
        'cmap',jet(100),...
        'colorbar',1,...
        'xlim',[],...
        'ylim',[],...
        't',1,...
        'linewidth',1.5,...
        'linestyle','-',...
        'valueName','\lambda value',...
        'trackNum',[],...
        'view',[45 45],...
        'color',[0 0 0],...
        'minMaxVal',[],...
        'markersize',3,...
        'marker','o',...
        'trange',[],...
        'addShadow',.5,...
        'highlightTracks',1,...
        'displayName','');
end
if(nargin > 0)
    if(ischar(varargin{1}))
        i = 1;
        while (i < length(varargin))
            options = setfield(options,varargin{i},varargin{i+1});
            i = i+2;
        end
    else if(isstruct(varargin{1}))
            if(isstruct(varargin{1}))
                options = varargin{1};
                j = 2;
                while (j < length(varargin))
                    options = setfield(options,varargin{j},varargin{j+1});
                    j = j+2;
                end
            else disp('error - in calling function');
            end
        end
    end
end


return