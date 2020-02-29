function data = importThermo(varargin)
% ------------------------------------------------------------------------
% Method      : importThermo
% Description : Read Thermo data files (.CF)
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = importThermo()
%   data = importThermo( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'file' -- name of file or folder path
%       empty (default) | char | cell array of strings
%
%   'depth' -- subfolder search depth
%       1 (default) | integer >= 0
%
%   'content' -- read all data, header only, or signal data only
%       'all' (default) | 'header', 'data'
%
%   'verbose' -- show progress in command window
%       'on' (default) | 'off' | 'waitbar'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = importThermo()
%   data = importThermo('file', '00159F.CF')
%   data = importThermo('file', {'/Data/2016/04/', '00201B.CF'})
%   data = importThermo('file', {'/Data/2016/'}, 'depth', 4)
%   data = importThermo('content', 'header', 'depth', 8)
%   data = importThermo('verbose', 'off')

% ---------------------------------------
% Data
% ---------------------------------------
data = struct(...
    'file_path',       [],...
    'file_name',       [],...
    'file_size',       [],...
    'file_checksum',   [],...
    'file_info',       [],...
    'file_version',    [],...
    'sample_name',     [],...
    'sample_info',     [],...
    'operator',        [],...
    'datetime',        [],...
    'datevalue',       [],...
    'instrument',      [],...
    'instmodel',       [],...
    'inlet',           [],...
    'method_name',     [],...
    'sequence_name',   [],...
    'sequence_path',   [],...
    'seqindex',        [],...
    'vial',            [],...
    'replicate',       [],...
    'injvol',          [],...
    'h3_factor',       [],...
    'ref_gas',         [],...
    'num_scans',       [],...
    'software_rev',    [],...
    'start_time',      [],...
    'end_time',        [],...
    'sampling_rate',   [],...
    'time',            [],...
    'intensity',       [],...
    'channel',         [],...
    'time_units',      [],...
    'intensity_units', [],...
    'channel_units',   [],...
    'baseline',        [],...
    'peaks',           []);

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file    = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'.CF'};

% ---------------------------------------
% Platform
% ---------------------------------------
if exist('OCTAVE_VERSION', 'builtin')
    more('off');
end

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addParameter(p, 'file',    default.file);
addParameter(p, 'depth',   default.depth);
addParameter(p, 'content', default.content, @ischar);
addParameter(p, 'verbose', default.verbose, @ischar);

parse(p, varargin{:});

% ---------------------------------------
% Options
% ---------------------------------------
option.file    = p.Results.file;
option.depth   = p.Results.depth;
option.content = p.Results.content;
option.verbose = p.Results.verbose;
option.waitbar = false;

% ---------------------------------------
% Validate
% ---------------------------------------

% Parameter: 'file'
if ~isempty(option.file)
    if iscell(option.file)
        option.file(~cellfun(@ischar, option.file)) = [];
    elseif ischar(option.file)
        option.file = {option.file};
    end
end

% Parameter: 'depth'
if ischar(option.depth) && ~isnan(str2double(option.depth))
    option.depth = round(str2double(default.depth));
elseif ~isnumeric(option.depth)
    option.depth = default.depth;
elseif option.depth < 0 || isnan(option.depth) || isinf(option.depth)
    option.depth = default.depth;
else
    option.depth = round(option.depth);
end

% Parameter: 'content'
option.content = lower(option.content);

switch option.content
    case {'all', 'default'}
        option.content = 'all';
    case {'data', 'signal'}
        option.content = 'data';
    case {'metadata', 'header', 'info'}
        option.content = 'header';
    otherwise
        option.content = default.content;
end

% Parameter: 'verbose'
option.verbose = lower(option.verbose);

switch option.verbose
    case {'on', 'true', '1', 'yes', 'y'}
        option.verbose = true;
    case {'off', 'false', '0', 'no', 'n'}
        option.verbose = false;
    case {'waitbar'}
        option.verbose = false;
        option.waitbar = true;
    otherwise
        option.verbose = default.verbose;
end

% ---------------------------------------
% File selection
% ---------------------------------------
status(option.verbose, 'import');

if isempty(option.file)
    [file, fileError] = FileUI([]);
else
    file = FileVerify(option.file, []);
end

% ---------------------------------------
% Status
% ---------------------------------------
if exist('fileError', 'var') && fileError == 1
    status(option.verbose, 'selection_cancel');
    status(option.verbose, 'exit');
    return
    
elseif exist('fileError', 'var') && fileError == 2
    status(option.verbose, 'java_error');
    status(option.verbose, 'exit');
    return
    
elseif isempty(file)
    status(option.verbose, 'file_error');
    status(option.verbose, 'exit');
    return
end

% ---------------------------------------
% Search subfolders
% ---------------------------------------
if sum([file.directory]) == 0
    option.depth = 0;
else
    status(option.verbose, 'subfolder_search');
    file = parsesubfolder(file, option.depth, default.formats);
end

% ---------------------------------------
% Filter unsupported files
% ---------------------------------------
[~,~,ext] = cellfun(@(x) fileparts(x), {file.Name}, 'uniformoutput', 0);

file(cellfun(@(x) ~any(strcmpi(x, default.formats)), ext)) = [];

% ---------------------------------------
% Status
% ---------------------------------------
if isempty(file)
    status(option.verbose, 'selection_error');
    status(option.verbose, 'exit');
    return
else
    status(option.verbose, 'file_count', length(file));
end

% ---------------------------------------
% Import
% ---------------------------------------
tic;

for i = 1:length(file)
    
    % ---------------------------------------
    % Permissions
    % ---------------------------------------
    if ~file(i).UserRead
        continue
    end
    
    % ---------------------------------------
    % Properties
    % ---------------------------------------
    [filePath, fileName, fileExt] = fileparts(file(i).Name);
    
	data(i,1).file_path = filePath;
    data(i,1).file_name = [fileName, fileExt];    
    data(i,1).file_size = subsref(dir(file(i).Name), substruct('.', 'bytes'));
    
    % ---------------------------------------
    % Waitbar
    % ---------------------------------------
    if i == 1
        if option.waitbar
            h = initializeWaitbar(length(file), data(i,1).file_name);
        else
            h = [];
        end
    end
    
    if option.waitbar && ~ishandle(h)
        data(i,:) = [];
        status(option.verbose, 'abort', i, length(file));
        break
    elseif option.waitbar
        updateWaitbar(h, i, length(file), data(i,1).file_name);
    end
    
    % ---------------------------------------
    % Status
    % ---------------------------------------
    [~, statusPath] = fileparts(data(i,1).file_path);
    statusPath = ['..', filesep, statusPath, filesep, data(i,1).file_name];
    
    status(option.verbose, 'loading_file', i, length(file));
    status(option.verbose, 'file_name', statusPath);
    status(option.verbose, 'loading_stats', data(i,1).file_size);
    
    % ---------------------------------------
    % Read
    % ---------------------------------------
    if data(i,1).file_size ~= 0
        
        f = fopen(file(i).Name, 'r');
        
        switch option.content
            
            case {'all', 'default'}
                %data(i,1) = parseinfo(f, data(i,1));
                data(i,1) = parsedata(f, data(i,1));
                
            case {'header'}
                %data(i,1) = parseinfo(f, data(i,1));
                data(i,1) = parsedata(f, data(i,1));
                
            case {'data'}
                data(i,1) = parsedata(f, data(i,1));
                %data(i,1) = parsedata(f, data(i,1));
                
        end
        
        fclose(f);
        
        % ---------------------------------------
        % MD5 Checksum
        % ---------------------------------------
        data(i,1) = getMD5(file(i).Name, data(i,1));
        
    end
    
end

% ---------------------------------------
% Exit
% ---------------------------------------
if option.waitbar && ishandle(h)
    close(h);
end

status(option.verbose, 'stats', length(data), toc, sum([data.file_size]));
status(option.verbose, 'exit');

end

% ---------------------------------------
% MD5 Checksum
% ---------------------------------------
function data = getMD5(file, data)

try 
    fileHash = java.security.MessageDigest.getInstance('MD5');
catch
    return
end

f = fopen(file, 'r');
digest = dec2hex(typecast(fileHash.digest(fread(f, inf, '*uint8')), 'uint8'));
fclose(f);

data.file_checksum = (reshape(digest',1,[]));

end

% ---------------------------------------
% Initialize Waitbar
% ---------------------------------------
function h = initializeWaitbar(n, filename)

m = num2str('0');
n = num2str(n);
msg = ['(', repmat('0', 1, length(n) - 1), m, '/', n, ')'];

x = fileparts(filename);

if isempty(x)
    x = filename;
end

h = waitbar(0, ['Loading ../', x, msg], 'name', 'Loading...');

% Set text interpreter
if isprop(h, 'Children')
    if ~isempty(h.Children) && isprop(h.Children(1), 'Title')
        if isprop(h.Children(1).Title, 'Interpreter')
            h.Children(1).Title.Interpreter = 'none';
        end
    end
end

end

% ---------------------------------------
% Update Waitbar
% ---------------------------------------
function updateWaitbar(h, i, j, filename)

m = num2str(i);
n = num2str(j);
msg = [' (', repmat('0', 1, length(n) - length(m)), m, '/', n, ')'];

x = fileparts(filename);

if isempty(x)
    x = filename;
end

waitbar(i/j, h, ['Loading ../', x, msg]);

end

% ---------------------------------------
% Status
% ---------------------------------------
function status(varargin)

if ~varargin{1}
    return
end

switch varargin{2}
    
    case 'exit'
        fprintf(['\n', repmat('-',1,50), '\n']);
        fprintf(' EXIT');
        fprintf(['\n', repmat('-',1,50), '\n']);
        
    case 'file_count'
        fprintf([' STATUS  Importing ', num2str(varargin{3}), ' files...', '\n\n']);
        
    case 'file_name'
        fprintf(' %s', varargin{3});
        
    case 'import'
        fprintf(['\n', repmat('-',1,50), '\n']);
        fprintf(' IMPORT');
        fprintf(['\n', repmat('-',1,50), '\n\n']);
        
    case 'java_error'
        fprintf([' STATUS  Unable to load file selection interface...', '\n']);
        
    case 'abort'
        m = num2str(varargin{3});
        n = num2str(varargin{4});
        fprintf([' [', [repmat('0', 1, length(n) - length(m)), m], '/', n, ']']);
        fprintf([' File import cancelled...', '\n']);
        
    case 'loading_file'
        m = num2str(varargin{3});
        n = num2str(varargin{4});
        fprintf([' [', [repmat('0', 1, length(n) - length(m)), m], '/', n, ']']);
        
    case 'loading_stats'
        fprintf([' (', parsebytes(varargin{3}), ')\n']);
        
    case 'selection_cancel'
        fprintf([' STATUS  No files selected...', '\n']);
        
    case 'selection_error'
        fprintf([' STATUS  No files found...', '\n']);
        
    case 'subfolder_search'
        fprintf([' STATUS  Searching subfolders...', '\n']);
        
    case 'stats'
        fprintf(['\n Files   : ', num2str(varargin{3})]);
        fprintf(['\n Elapsed : ', parsetime(varargin{4})]);
        fprintf(['\n Bytes   : ', parsebytes(varargin{5}),'\n']);
        
end

end

% ---------------------------------------
% FileUI
% ---------------------------------------
function [file, status] = FileUI(file)

% JFileChooser (Java)
if ~usejava('swing')
    status = 2;
    return
end

fc = javax.swing.JFileChooser(java.io.File(pwd));

% Options
fc.setFileSelectionMode(fc.FILES_AND_DIRECTORIES);
fc.setMultiSelectionEnabled(true);
fc.setAcceptAllFileFilterUsed(false);

% Filter: Thermo (.CF)
thermo = com.mathworks.hg.util.dFilter;

thermo.setDescription('Thermo files (*.CF)');
thermo.addExtension('cf');

fc.addChoosableFileFilter(thermo);

% Initialize UI
status = fc.showOpenDialog(fc);

if status == fc.APPROVE_OPTION
    
    % Get file selection
    fs = fc.getSelectedFiles();
    
    for i = 1:size(fs, 1)
        
        % Get file information
        [~, f] = fileattrib(char(fs(i).getAbsolutePath));
        
        % Append to file list
        if isstruct(f)
            file = [file; f];
        end
    end
end

end

% ---------------------------------------
% File verification
% ---------------------------------------
function file = FileVerify(str, file)

for i = 1:length(str)
    
    [~, f] = fileattrib(str{i});
    
    if isstruct(f)
        file = [file; f];
    end
    
end

end

% ---------------------------------------
% Subfolder contents
% ---------------------------------------
function file = parsesubfolder(file, searchDepth, fileType)

searchIndex = [1, length(file)];

while searchDepth >= 0
    
    for i = searchIndex(1):searchIndex(2)
        
        [~, ~, fileExt] = fileparts(file(i).Name);
        
        if any(strcmpi(fileExt, {'.m', '.git', '.lnk'}))
            continue
        elseif file(i).directory == 1
            file = parsedirectory(file, i, fileType);
        end
        
    end
    
    if length(file) > searchIndex(2)
        searchDepth = searchDepth-1;
        searchIndex = [searchIndex(2)+1, length(file)];
    else
        break
    end
end

end

% ---------------------------------------
% Directory contents
% ---------------------------------------
function file = parsedirectory(file, fileIndex, fileType)

filePath = dir(file(fileIndex).Name);
filePath(cellfun(@(x) any(strcmpi(x, {'.', '..'})), {filePath.name})) = [];

for i = 1:length(filePath)
    
    fileName = [file(fileIndex).Name, filesep, filePath(i).name];
    [~, fileName] = fileattrib(fileName);
    
    if isstruct(fileName)
        [~, ~, fileExt] = fileparts(fileName.Name);
        
        if fileName.directory || any(strcmpi(fileExt, fileType))
            file = [file; fileName];
        end
    end
end

end

% ---------------------------------------
% Data = byte string
% ---------------------------------------
function str = parsebytes(x)

if x > 1E9
    str = [num2str(x/1E9, '%.1f'), ' GB'];
elseif x > 1E6
    str = [num2str(x/1E6, '%.1f'), ' MB'];
elseif x > 1E3
    str = [num2str(x/1E3, '%.1f'), ' KB'];
else
    str = [num2str(x/1E3, '%.3f'), ' KB'];
end

end

% ---------------------------------------
% Data = time string
% ---------------------------------------
function str = parsetime(x)

if x > 60
    str = [num2str(x/60, '%.1f'), ' min'];
else
    str = [num2str(x, '%.1f'), ' sec'];
end

end

% ---------------------------------------
% File header
% ---------------------------------------
function data = parseinfo(f, data)

data.file_version = fpascal(f, 0, 'uint8');

if isnan(str2double(data.file_version))
    data.file_version = [];
end

if isempty(data.file_version)
    return
end

% Sample Information
switch data.file_version
    
    case {'2', '8', '81', '30', '31'}
        
        data.file_info    = fpascal(f,  4,    'uint8');
        data.sample_name  = fpascal(f,  24,   'uint8');
        data.sample_info  = fpascal(f,  86,   'uint8');
        data.operator     = fpascal(f,  148,  'uint8');
        data.datetime     = fpascal(f,  178,  'uint8');
        data.instmodel    = fpascal(f,  208,  'uint8');
        data.inlet        = fpascal(f,  218,  'uint8');
        data.method_name  = fpascal(f,  228,  'uint8');
        data.seqindex     = fnumeric(f, 252,  'int16');
        data.vial         = fnumeric(f, 254,  'int16');
        data.replicate    = fnumeric(f, 256,  'int16');
        
    case {'130', '131', '179', '181'}
        
        data.file_info    = fpascal(f,  347,  'uint16');
        data.sample_name  = fpascal(f,  858,  'uint16');
        data.sample_info  = fpascal(f,  1369, 'uint16');
        data.operator     = fpascal(f,  1880, 'uint16');
        data.datetime     = fpascal(f,  2391, 'uint16');
        data.instmodel    = fpascal(f,  2492, 'uint16');
        data.inlet        = fpascal(f,  2533, 'uint16');
        data.method_name  = fpascal(f,  2574, 'uint16');
        data.seqindex     = fnumeric(f, 252,  'int16');
        data.vial         = fnumeric(f, 254,  'int16');
        data.replicate    = fnumeric(f, 256,  'int16');
        
end

% Extra Information
switch data.file_version
    
    case {'30'}
        
        data.glp_flag     = fnumeric(f, 318,  'int32');
        data.data_source  = fpascal(f,  322,  'uint8');
        data.firmware_rev = fpascal(f,  355,  'uint8');
        data.software_rev = fpascal(f,  405,  'uint8');
        
    case {'130', '179'}
        
        data.glp_flag     = fnumeric(f, 3085, 'int32');
        data.data_source  = fpascal(f,  3089, 'uint16');
        data.firmware_rev = fpascal(f,  3601, 'uint16');
        data.software_rev = fpascal(f,  3802, 'uint16');
        
end

% Units
switch data.file_version
    
    case {'2'}
        
        data.time_units      = 'minutes';
        data.intensity_units = 'counts';
        data.channel_units   = 'm/z';
        
    case {'8', '81', '30'}
        
        data.time_units      = 'minutes';
        data.intensity_units = fpascal(f,  580, 'uint8');
        data.channel_units   = fpascal(f,  596, 'uint8');
        
    case {'31'}
        
        data.time_units      = 'minutes';
        data.intensity_units = fpascal(f, 326, 'uint8');
        data.channel_units   = fpascal(f, 344, 'uint8');
        
    case {'130', '179', '181'}
        
        data.time_units      = 'minutes';
        data.intensity_units = fpascal(f, 4172, 'uint16');
        data.channel_units   = fpascal(f, 4213, 'uint16');
        
    case {'131'}
        
        data.time_units      = 'minutes';
        data.intensity_units = fpascal(f, 3093, 'uint16');
        data.channel_units   = fpascal(f, 3136, 'uint16');
        
end

% Parse channel name (GC/FID)
switch data.file_version
    
    case {'8', '81', '179', '181'}
        
        if ~isempty(regexpi(data.file_name, '(FID1A)', 'tokens', 'once'))
            data.channel = 'A';
        elseif ~isempty(regexpi(data.file_name, '(FID2B)', 'tokens', 'once'))
            data.channel = 'B';
        else
            data.channel = '';
        end
        
        if isempty(data.channel_units)
            data.channel_units = 'char';
        end
        
end

% Parse start/end time
data = parsexlim(f, data);

% Parse sequence name
data = parsesequence(data);

% Parse datetime
if ~isempty(data.datetime)
    [data.datetime, data.datevalue] = parsedate(data.datetime, data.datevalue);
end

% Parse instrument
data.instrument = parseinstrument(data);

% Fix formatting
data.instmodel = upper(data.instmodel);
data.inlet     = upper(data.inlet);
data.operator  = upper(data.operator);

end

% ---------------------------------------
% File data
% ---------------------------------------
function data = parsedata(f, data)

offset = findStr(f, 'CRawDataScanStorage', 'uint8', 50);
%dataOffset = false;

%while ~dataOffset
    
%    n = 50;
%    x = fread(f, n, 'uint8=>char')';
    
%    if any(x == dataStr(1))
        
%        fseek(f, ftell(f) - (n - find(x == dataStr(1), 1) + 1), 'bof');
%        str = fread(f, 19, 'uint8=>char')';
        
%        if str(2) ~= dataStr(2) || str(end) ~= dataStr(end)
%            continue
%        elseif strcmp(str, dataStr)
%            dataOffset = true;
%        else
%            continue
%        end
        
%    else
%        continue
%    end
    
%end

%if feof(f)
%    return
%end

fseek(f, ftell(f) + 60, 'bof');
data.num_scans = fread(f, 1, 'uint16', 'l');

if data.num_scans < 1 || data.num_scans > 1E9
    return
end

n = 2;

data.channel   = [2,3];
data.time      = zeros(data.num_scans, 1);
data.intensity = zeros(length(data.time), length(data.channel));

fseek(f, ftell(f) + 35, 'bof');
offset = ftell(f);

% Time
data.time = fread(f, data.num_scans, 'single', n*8, 'l') ./ 60;

% Intensity
for i = 1:n
    fseek(f, offset+4 + (i-1)*8, 'bof');
    data.intensity(:,i) = fread(f, data.num_scans, 'double', (n-1)*8+4, 'l');
end

% Units
data.time_units      = 'minutes';
data.intensity_units = 'mV';
data.channel_units   = 'm/z';

% Start/End Time
data.start_time = min(data.time);
data.end_time   = max(data.time);

% Sampling Rate
if ~isempty(data.time)
    data.sampling_rate = round(1 ./ mean(diff(data.time .* 60)), 2);
end

end

function data = parsexlim(f, data)

% Time range
switch data.file_version
    
    case {'81', '179', '181'}
        
        data.start_time = fnumeric(f, 282, 'float32');
        data.end_time = fnumeric(f, 286, 'float32');
        
    case {'2', '8', '30', '130'}
        
        data.start_time = fnumeric(f, 282, 'int32');
        data.end_time = fnumeric(f, 286, 'int32');
        
    otherwise
        
        data.start_time = [];
        data.end_time = [];
        
end

if ~isempty(data.start_time)
    data.start_time = data.start_time ./ 6E4;
end

if ~isempty(data.end_time)
    data.end_time = data.end_time ./ 6E4;
end

end

% ---------------------------------------
% Data = datetime
% ---------------------------------------
function [str, val] = parsedate(str, val)

% Platform
if exist('OCTAVE_VERSION', 'builtin')
    return
end

% ISO 8601
formatOut = 'yyyy-mm-ddTHH:MM:SS';

% Possible Formats
dateFormat = {...
    'dd mmm yy HH:MM PM',...
    'dd mmm yy HH:MM',...
    'mm/dd/yy HH:MM:SS PM',...
    'mm/dd/yy HH:MM:SS',...
    'mm/dd/yyyy HH:MM',...
    'mm/dd/yyyy HH:MM:SS PM',...
    'mm.dd.yyyy HH:MM:SS',...
    'dd-mmm-yy HH:MM:SS',...
    'dd-mmm-yy, HH:MM:SS'};

dateRegex = {...
    '\d{1,2} \w{3} \d{1,2}\s*\d{1,2}[:]\d{2} \w{2}',...
    '\d{2} \w{3} \d{2}\s*\d{2}[:]\d{2}',...
    '\d{2}[/]\d{2}[/]\d{2}\s*\d{2}[:]\d{2}[:]\d{2} \w{2}',...
    '\d{1,2}[/]\d{1,2}[/]\d{2}\s*\d{1,2}[:]\d{2}[:]\d{2}',...
    '\d{2}[/]\d{2}[/]\d{4}\s*\d{2}[:]\d{2}',...
    '\d{1,2}[/]\d{1,2}[/]\d{4}\s*\d{1,2}[:]\d{2}[:]\d{2} \w{2}',...
    '\d{2}[.]\d{2}[.]\d{4}\s*\d{2}[:]\d{2}[:]\d{2}',...
    '\d{2}[-]\w{3}[-]\d{2}\s*\d{2}[:]\d{2}[:]\d{2}',...
    '\d{2}[-]\w{3}[-]\d{2}[,]\s*\d{2}[:]\d{2}[:]\d{2}'};

if ~isempty(str)
    
    dateMatch = regexp(str, dateRegex, 'match');
    dateIndex = find(~cellfun(@isempty, dateMatch), 1);
    
    if ~isempty(dateIndex)
        val = datenum(str, dateFormat{dateIndex});
        str = datestr(val, formatOut);
    end
    
end

end

% ---------------------------------------
% Data = sequence info
% ---------------------------------------
function data = parsesequence(data)

if isempty(data.file_path) || ~exist(data.file_path, 'dir')
    return
end

[~, data.sequence_path] = fileparts(data.file_path);
data.sequence_name = '';

f = dir(data.file_path);
f = f(~[f.isdir]);

if isempty(f)
    return
end

for i = 1:length(f)
    
    [~, str, ext] = fileparts(f(i).name);
    
    if strcmpi(ext, '.S')
        data.sequence_name = str;
        break
    end
    
end

end

% ---------------------------------------
% Data = instrument string
% ---------------------------------------
function str = parseinstrument(data)

instrMatch = @(x,str) any(cellfun(@any, regexpi(x, str)));

str = [...
    data.file_info,...
    data.inlet,...
    data.instmodel,...
    data.channel_units];

if isempty(str)
    return
end

switch data.file_version
    
    case {'2'}
        
        if instrMatch(str, {'CE'})
            str = 'CE/MS';
        elseif instrMatch(str, {'LC'})
            str = 'LC/MS';
        elseif instrMatch(str, {'GC'})
            str = 'GC/MS';
        else
            str = 'MS';
        end
        
    case {'8', '81', '179', '181'}
        
        if instrMatch(str, {'GC'})
            str = 'GC/FID';
        else
            str = 'GC';
        end
        
    case {'30', '31', '130', '131'}
        
        if instrMatch(str, {'DAD', '1315', '4212', '7117'})
            str = 'LC/DAD';
        elseif instrMatch(str, {'VWD', '1314', '7114'})
            str = 'LC/VWD';
        elseif instrMatch(str, {'MWD', '1365'})
            str = 'LC/MWD';
        elseif instrMatch(str, {'FLD', '1321'})
            str = 'LC/FLD';
        elseif instrMatch(str, {'ELS', '4260', '7102'})
            str = 'LC/ELSD';
        elseif instrMatch(str, {'RID', '1362'})
            str = 'LC/RID';
        elseif instrMatch(str, {'ADC', '35900'})
            str = 'LC/ADC';
        elseif instrMatch(str, {'CE'})
            str = 'CE';
        else
            str = 'LC';
        end
        
end

end

% ---------------------------------------
% Data = binary offset
% ---------------------------------------
function offset = findStr(f, str, type, varargin)

offset = [];
readFile = false;

if ~isempty(varargin) && isnumeric(varargin{1})
    readSize = varargin{1};
else
    readSize = 50;
end

while ~feof(f) && ~readFile
    
    x = fread(f, readSize, [type, '=>char'])';
    
    if any(x == str(1))
        
        fseek(f, ftell(f) - (readSize - find(x == str(1), 1) + 1), 'bof');
        readStr = fread(f, length(str), [type, '=>char'])';
        
        if readStr(end) ~= str(end)
            continue
        elseif strcmp(readStr, str)
            offset = ftell(f) - length(str);
            readFile = true;
        else
            continue
        end
        
    else
        continue
    end
    
end

end

% ---------------------------------------
% Data = pascal string
% ---------------------------------------
function str = fpascal(f, offset, type)

fseek(f, offset, 'bof');
str = fread(f, fread(f, 1, 'uint8'), [type, '=>char'], 'l')';

if length(str) > 512
    str = '';
else
    str = strtrim(deblank(str));
end

end

% ---------------------------------------
% Data = numeric
% ---------------------------------------
function x = fnumeric(f, offset, type)

fseek(f, offset, 'bof');
x = fread(f, 1, type, 'b');

end

% ---------------------------------------
% Data = array
% ---------------------------------------
function x = farray(f, offset, type, count, skip)

fseek(f, offset, 'bof');
x = fread(f, count, type, skip, 'b');

end

% ---------------------------------------
% Data = time vector
% ---------------------------------------
function x = ftime(start, stop, count)

if count > 2
    x = linspace(start, stop, count)';
else
    x = [start; stop];
end

end

% ---------------------------------------
% Data = delta compression
% ---------------------------------------
function y = fdelta(f, offset)

fseek(f, 0, 'eof');
n = ftell(f);

fseek(f, offset, 'bof');
y = zeros(floor(n/2), 1);

buffer = [0,0,0,0,0];

while ftell(f) < n
    
    buffer(1) = fread(f, 1, 'int16', 'b');
    buffer(2) = buffer(4);
    
    if bitshift(int16(buffer(1)), -12) ~= 0
        
        for j = 1:bitand(int16(buffer(1)), int16(4095))
            
            buffer(3) = fread(f, 1, 'int16', 'b');
            buffer(5) = buffer(5) + 1;
            
            if buffer(3) ~= -32768
                buffer(2) = buffer(2) + buffer(3);
            else
                buffer(2) = fread(f, 1, 'int32', 'b');
            end
            
            y(buffer(5),1) = buffer(2);
            
        end
        
        buffer(4) = buffer(2);
        
    else
        break
    end
    
end

if buffer(5)+1 < length(y)
    y(buffer(5)+1:end) = [];
end

end

% ---------------------------------------
% Data = double delta compression
% ---------------------------------------
function y = fdoubledelta(f, offset)

fseek(f, 0, 'eof');
n = ftell(f);

fseek(f, offset, 'bof');
y = zeros(floor(n/2), 1);

buffer = [0,0,0,0];

while ftell(f) < n
    
    buffer(4) = buffer(4) + 1;
    buffer(3) = fread(f, 1, 'int16', 'b');
    
    if buffer(3) ~= 32767
        buffer(2) = buffer(2) + buffer(3);
        buffer(1) = buffer(1) + buffer(2);
    else
        buffer(1) = fread(f, 1, 'int16', 'b') * 4294967296;
        buffer(1) = fread(f, 1, 'uint32', 'b') + buffer(1);
        buffer(2) = 0;
    end
    
    y(buffer(4),1) = buffer(1);
    
end

if buffer(4)+1 < length(y)
    y(buffer(4)+1:end) = [];
end

end

% ---------------------------------------
% Data = double array
% ---------------------------------------
function y = fdoublearray(f, offset)

fseek(f, 0, 'eof');
n = floor((ftell(f) - offset) / 8);

fseek(f, offset, 'bof');
y = fread(f, n, 'float64', 'l');

end