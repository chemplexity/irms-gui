function toolboxAxes(obj, varargin)

% ---------------------------------------
% Axes Properties
% ---------------------------------------
default.margin      = 0.01;
default.position(1) = 0.05 + default.margin;
default.position(2) = 0.05 + default.margin;
default.position(3) = 1.00 - default.position(1) - default.margin * 2;
default.position(4) = 1.00 - default.position(2) - default.margin * 2;
default.looseinset  = [0.06, 0.06, 0.025, 0.025];
default.box         = 'off';
default.linewidth   = obj.settings.axes.linewidth;
default.units       = 'normalized';
default.color       = [1.00, 1.00, 1.00];
default.xcolor      = [0.10, 0.10, 0.10];
default.ycolor      = [0.10, 0.10, 0.10];
default.xtick       = [];
default.ytick       = [];
default.xtickmode   = 'auto';
default.ytickmode   = 'auto';
default.xminortick  = 'off';
default.yminortick  = 'off';
default.ticklength  = [0.007, 0.0075];
default.tickdir     = 'out';
default.xgrid       = 'off';
default.ygrid       = 'off';
default.fontname    = obj.settings.axes.fontname;
default.fontsize    = obj.settings.axes.fontsize;
default.fontweight  = 'normal';
default.xlabel      = 'Time (min)';
default.ylabel      = 'Intensity';

% ---------------------------------------
% Primary Axes
% ---------------------------------------
obj.axes.main = axes(...
    'parent',     obj.panel.axes,...
    'tag',        'axesplot',...
    'nextplot',   'add',...
    'looseinset', default.looseinset,...
    'units',      default.units,...
    'position',   default.position,...
    'color',      default.color,...
    'xcolor',     default.xcolor,...
    'ycolor',     default.ycolor,...
    'box',        default.box,...
    'xtick',      default.xtick,...
    'ytick',      default.ytick,...
    'xtickmode',  default.xtickmode,...
    'ytickmode',  default.ytickmode,...
    'xminortick', default.xminortick,...
    'yminortick', default.yminortick,...
    'xgrid',      default.xgrid,...
    'ygrid',      default.ygrid,...
    'linewidth',  default.linewidth,...
    'tickdir',    default.tickdir,...
    'ticklength', default.ticklength,...
    'fontname',   default.fontname,...
    'fontsize',   default.fontsize,...
    'fontweight', default.fontweight);

set(obj.axes.main, 'activepositionproperty', 'position');

% ---------------------------------------
% X-Axes Label
% ---------------------------------------
xlabel(default.xlabel,...
    'fontname',   default.fontname,...
    'fontsize',   default.fontsize,...
    'fontweight', default.fontweight);

% ---------------------------------------
% Y-Axes Label
% ---------------------------------------
ylabel(default.ylabel,...
    'fontname',   default.fontname,...
    'fontsize',   default.fontsize,...
    'fontweight', default.fontweight);

% ---------------------------------------
% Secondary Axes
% ---------------------------------------
obj.axes.secondary = axes(...
    'parent',    obj.panel.axes,...
    'tag',       'axesbox',...
    'nextplot',  'replacechildren',...
    'box',       'on',...
    'color',     'none',...
    'xcolor',    default.xcolor,...
    'ycolor',    default.ycolor,...
    'box',       'on',...
    'xtick',     [],...
    'ytick',     [],...
    'linewidth', default.linewidth,...
    'position',  obj.axes.main.Position,...
    'hittest',   'off');

% ---------------------------------------
% Axes Border
% ---------------------------------------
box(obj.axes.secondary, 'on');
box(obj.axes.main, 'off');

linkaxes([obj.axes.main, obj.axes.secondary]);

try
    set(zoom(obj.figure),...
        'actionpostcallback', @(varargin) set(obj.axes.secondary,...
        'position', obj.axes.main.Position));
catch
end

try
    
    if verLessThan('matlab', 'R2014b')
        
        set(obj.figure,...
            'resizefcn', @(varargin) set(obj.axes.secondary,...
            'position', obj.axes.main.Position));
        
    else
        
        set(obj.figure,...
            'sizechangedfcn', @(varargin) set(obj.axes.secondary,...
            'position', obj.axes.main.Position));
        
        set(get(get(obj.axes.main, 'yruler'), 'axle'), 'visible', 'off');
        set(get(get(obj.axes.main, 'xruler'), 'axle'), 'visible', 'off');
        set(get(get(obj.axes.main, 'ybaseline'), 'axle'), 'visible', 'off');
        
    end
    
catch
end

if ~verLessThan('matlab', 'R2015b')
    obj.axes.main.YAxis.Exponent = 0;
end

updateAxesPosition(obj);

end

% ---------------------------------------
% updateAxesPosition
% ---------------------------------------
function updateAxesPosition(obj, varargin)

if isprop(obj.axes.main, 'OuterPosition')
    
    x1 = obj.axes.main.Position;
    x2 = obj.axes.main.OuterPosition;
    
    x(1) = x1(1) - x2(1);
    x(2) = x1(2) - x2(2);
    x(3) = x1(3) - (x2(3)-1);
    x(4) = x1(4) - (x2(4)-1);
    
    if all(x > 0)
        obj.axes.main.Position = x;
        obj.axes.secondary.Position = x;
    end
    
end

end