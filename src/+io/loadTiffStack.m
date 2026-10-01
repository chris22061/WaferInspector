function [vol, meta] = loadTiffStack(source, opts)
%LOADTIFFSTACK Wczytuje stos 16-bit TIFF (folder plikow LUB jeden wielostronicowy TIFF).
%   [vol, meta] = io.loadTiffStack("data/synth_fail")
%   [vol, meta] = io.loadTiffStack("data/stack.tif", ZRange=10:50)

arguments
    source (1,1) string
    opts.ZRange double = []
    opts.MaxRAMFraction (1,1) double {mustBePositive} = 0.5
end

if isfolder(source)
    f = [dir(fullfile(source, "*.tif")); dir(fullfile(source, "*.tiff"))];
    if isempty(f)
        error("WaferInspector:io:EmptyFolder", "Brak plikow TIFF w: %s", source);
    end
    files = natsortFiles(fullfile({f.folder}, {f.name}));
    info1 = imfinfo(files{1});
    nZ = numel(files);
elseif isfile(source)
    info = imfinfo(source); info1 = info(1); nZ = numel(info); files = {};
else
    error("WaferInspector:io:NotFound", "Nie znaleziono: %s", source);
end

z = 1:nZ;
if ~isempty(opts.ZRange)
    if any(opts.ZRange < 1 | opts.ZRange > nZ | opts.ZRange ~= round(opts.ZRange))
        error("WaferInspector:io:BadZRange", "ZRange poza zakresem 1..%d", nZ);
    end
    z = opts.ZRange;
end

if info1.BitDepth ~= 16
    error("WaferInspector:io:BitDepth", "Oczekiwano 16-bit, jest %d-bit.", info1.BitDepth);
end

H = info1.Height; W = info1.Width;
needBytes = double(H) * double(W) * numel(z) * 2;
totalRAM  = systemRAM();
if needBytes > opts.MaxRAMFraction * totalRAM
    error("WaferInspector:io:TooLarge", ...
        "Stos %.2f GB > limit %.2f GB. Uzyj ZRange.", ...
        needBytes/1e9, opts.MaxRAMFraction*totalRAM/1e9);
end

vol = zeros(H, W, numel(z), "uint16");
t = tic;
for k = 1:numel(z)
    if isempty(files)
        vol(:,:,k) = imread(source, z(k));
    else
        vol(:,:,k) = imread(files{z(k)});
    end
end

meta = struct("H", H, "W", W, "nZ", numel(z), "zIndices", z, ...
    "source", source, "sizeGB", needBytes/1e9, "loadTime_s", toc(t), ...
    "files", {files}, "info", info1);
end

% -------------------------------------------------------------------------
function total = systemRAM()
if ismac || isunix
    [st, s] = system("sysctl -n hw.memsize 2>/dev/null");
    total = str2double(strtrim(s));
    if st ~= 0 || isnan(total)   % Linux fallback
        [~, s] = system("awk '/MemTotal/ {print $2*1024}' /proc/meminfo");
        total = str2double(strtrim(s));
    end
else
    m = memory; total = m.MemAvailableAllArrays;
end
end

function out = natsortFiles(c)
[~, names] = cellfun(@fileparts, c, "UniformOutput", false);
num = cellfun(@(s) str2double(regexp(s, '\d+$', 'match', 'once')), names);
if any(isnan(num))
    out = sort(c);               % brak numeru na koncu -> sortowanie alfabetyczne
else
    [~, i] = sort(num); out = c(i);
end
end
