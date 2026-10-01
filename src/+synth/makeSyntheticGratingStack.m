function gt = makeSyntheticGratingStack(outDir, opts)
%MAKESYNTHETICGRATINGSTACK Syntetyczny stos 16-bit TIFF: siatka DRIE na krzemie.
%   gt = synth.makeSyntheticGratingStack("data/synth_fail")
%   gt = synth.makeSyntheticGratingStack("data/synth_pass", Defects=strings(0))
%
%   Geometria: os Z = wysokosc (przekroje poziome, jak po rekonstrukcji CT).
%   z = 1..SubstrateSlices           -> pelny krzem (podloze)
%   z = podloze+1 .. podloze+glebokosc -> lamele (linie wzdluz osi Y)
%   powyzej                          -> powietrze
%   Defekty: "collapse" (zawalona/wytrawiona czesc lameli), "grass" (black silicon na dnie rowka).
%   Zwraca ground truth i zapisuje go jako ground_truth.json w outDir.

arguments
    outDir (1,1) string
    opts.ImageSize (1,2) double {mustBePositive, mustBeInteger} = [256 256]  % [H W] px
    opts.NumSlices (1,1) double {mustBePositive, mustBeInteger} = 80
    opts.PixelSize_um (1,1) double {mustBePositive} = 0.5
    opts.Pitch_um (1,1) double {mustBePositive} = 8
    opts.LineWidth_um (1,1) double {mustBePositive} = 4
    opts.Depth_um (1,1) double {mustBePositive} = 16
    opts.SubstrateSlices (1,1) double {mustBeNonnegative, mustBeInteger} = 20
    opts.Defects (1,:) string = ["collapse" "grass"]
    opts.NoiseSigma (1,1) double {mustBeNonnegative} = 0.02
    opts.EdgeEnhancement (1,1) double {mustBeNonnegative} = 0.6   % sila "fringe" kontrastu fazowego
    opts.Format (1,1) string {mustBeMember(opts.Format, ["folder" "multipage"])} = "folder"
    opts.PadNames (1,1) logical = true      % false -> slice_1, slice_10 (test sortowania)
    opts.Seed (1,1) double = 42
end

rng(opts.Seed, "twister");
H = opts.ImageSize(1); W = opts.ImageSize(2); nZ = opts.NumSlices;
px       = opts.PixelSize_um;
linePx   = round(opts.LineWidth_um / px);
pitchPx  = round(opts.Pitch_um / px);
depthPx  = round(opts.Depth_um / px);
zSub     = opts.SubstrateSlices;
zTop     = zSub + depthPx;
assert(zTop <= nZ, "synth:TooShallow", ...
    "NumSlices (%d) < podloze + glebokosc (%d).", nZ, zTop);
assert(linePx < pitchPx, "synth:BadGeometry", "LineWidth musi byc < Pitch.");

% --- maska lamel (2D) ---
x = 0:W-1;
lineId1D = floor(x / pitchPx) + 1;
isLine1D = mod(x, pitchPx) < linePx;
lines    = repmat(isLine1D, H, 1);
lineId   = repmat(lineId1D, H, 1);
nLines   = max(lineId1D);

% --- definicje defektow ---
defects = struct("type", {}, "lineId", {}, "rows", {}, "zRange", {}, "bbox", {});
collapseMask = false(H, W); collapseZ = [];
grassMask = false(H, W);    grassZ = [];

if any(opts.Defects == "collapse")
    k  = max(1, round(nLines/2));
    r  = round(0.30*H)+1 : round(0.60*H);
    collapseZ = zSub + round(0.3*depthPx) + 1 : zTop;
    collapseMask(r, :) = lines(r, :) & lineId(r, :) == k;
    [cr, cc] = find(collapseMask);
    defects(end+1) = struct("type", "collapse", "lineId", k, "rows", [r(1) r(end)], ...
        "zRange", [collapseZ(1) collapseZ(end)], ...
        "bbox", [min(cc) min(cr) collapseZ(1) max(cc)-min(cc)+1 max(cr)-min(cr)+1 numel(collapseZ)]);
end

if any(opts.Defects == "grass")
    trench = ~lines;
    trench(:, [1 end]) = false; trench([1 end], :) = false;
    idx = find(trench);
    seeds = idx(randperm(numel(idx), min(15, numel(idx))));
    grassMask(seeds) = true;
    grassMask = imdilate(grassMask, ones(2)) & ~lines;
    grassZ = zSub + 1 : zSub + max(1, round(0.15*depthPx));
    [gr, gc] = find(grassMask);
    defects(end+1) = struct("type", "grass", "lineId", NaN, "rows", [min(gr) max(gr)], ...
        "zRange", [grassZ(1) grassZ(end)], ...
        "bbox", [min(gc) min(gr) grassZ(1) max(gc)-min(gc)+1 max(gr)-min(gr)+1 numel(grassZ)]);
end

% --- zapis ---
if ~isfolder(outDir), mkdir(outDir); end
old = dir(fullfile(outDir, "*.tif*"));
arrayfun(@(f) delete(fullfile(f.folder, f.name)), old);
stackFile = fullfile(outDir, "stack.tif");

for z = 1:nZ
    if z <= zSub
        slab = true(H, W);
    elseif z <= zTop
        slab = lines;
        if ismember(z, collapseZ), slab(collapseMask) = false; end
        if ismember(z, grassZ),    slab(grassMask)    = true;  end
    else
        slab = false(H, W);
    end
    img = renderPhaseContrast(single(slab), opts.EdgeEnhancement, opts.NoiseSigma);

    if opts.Format == "folder"
        if opts.PadNames, name = sprintf("slice_%04d.tif", z);
        else,             name = sprintf("slice_%d.tif", z); end
        imwrite(img, fullfile(outDir, name), "Compression", "none");
    else
        mode = "append"; if z == 1, mode = "overwrite"; end
        imwrite(img, stackFile, "WriteMode", mode, "Compression", "none");
    end
end

% --- ground truth ---
gt = struct();
gt.format         = opts.Format;
gt.size           = [H W nZ];
gt.pixelSize_um   = px;
gt.pitch_px       = pitchPx;
gt.lineWidth_px   = linePx;
gt.depth_px       = depthPx;
gt.zSubstrateTop  = zSub;
gt.zGratingTop    = zTop;
gt.nLines         = nLines;
gt.defects        = defects;
gt.expected       = "PASS";
if ~isempty(defects), gt.expected = "FAIL"; end
gt.seed           = opts.Seed;

fid = fopen(fullfile(outDir, "ground_truth.json"), "w");
fprintf(fid, "%s", jsonencode(gt, "PrettyPrint", true));
fclose(fid);
end

% -------------------------------------------------------------------------
function img = renderPhaseContrast(slab, k, sigma)
% Uproszczony model: rozmycie PSF + "edge enhancement" (-laplasjan) + szum.
b   = imgaussfilt(slab, 1.0);
L   = 4 * del2(b);
I   = 0.25 + 0.5*b - k*L;
I   = I + sigma * randn(size(I), "single");
I   = min(max(I, 0), 1);
img = uint16(round(I * 60000) + 2000);   % offset jak w realnym detektorze
end
