function [x0, y0, f0, f1] = resample(x, y, varargin)

if ~isempty(varargin) && isnumeric(varargin{1})
    f1 = varargin{1};
else
    f1 = 10;
end

x0 = [];
y0 = [];
n0 = 25;

if isempty(x) || isempty(y) || ~any(x) || ~any(y)
    return
elseif length(x) < n0 || length(y) < n0
    return
end

f0 = 1 / mean(diff(x(1:n0)));
ftol = 25;

if f0 > f1
    
    dx = round(1./(x(3:20)-x(2)));
    
    if any(dx == f1)
        ii = find(dx == f1, 1);
        x0 = x(1:ii:end);
        y0 = y(1:ii:end);
    elseif any(dx >= f1-ftol & dx <= f1+ftol)
        f1 = f0;
        ii = find(dx >= f1-ftol & dx <= f1+ftol, 1);
        x0 = x(1:ii:end);
        y0 = y(1:ii:end);
    else
        x0 = min(x):1/f1:max(x);
        y0 = interp1(x,y,x0);
    end
    
elseif f0 < f1
    x0 = min(x):1/f1:max(x);
    y0 = interp1(x,y,x0);
end

end

function hz = seconds2hertz(x)

if length(x) > 1
    hz = 1 / mean(diff(x));
elseif length(x) == 1
    hz = 1 / x;
end

end

function x = hertz2seconds(hz)

if length(hz) > 1
    x = 1 / mean(diff(hz));
elseif length(hz) == 1
    x = 1 / hz;
end

end