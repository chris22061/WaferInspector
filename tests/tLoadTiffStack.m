classdef tLoadTiffStack < matlab.unittest.TestCase
    % Uruchom: runtests("tests")

    properties
        Dir      % folder testowy (tymczasowy)
        GT
    end

    methods (TestClassSetup)
        function addSrc(tc)
            root = fileparts(fileparts(mfilename("fullpath")));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, "src")));
        end
    end

    methods (TestMethodSetup)
        function makeData(tc)
            f = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            tc.Dir = string(f.Folder);
            tc.GT = synth.makeSyntheticGratingStack(fullfile(tc.Dir, "stack"), ...
                ImageSize=[64 96], NumSlices=30, SubstrateSlices=5, Depth_um=8);
        end
    end

    methods (Test)
        function sizeAndType(tc)
            [vol, meta] = io.loadTiffStack(fullfile(tc.Dir, "stack"));
            tc.verifyClass(vol, "uint16");
            tc.verifySize(vol, tc.GT.size);
            tc.verifyEqual(meta.nZ, tc.GT.size(3));
        end

        function zRangeSubset(tc)
            full = io.loadTiffStack(fullfile(tc.Dir, "stack"));
            [sub, meta] = io.loadTiffStack(fullfile(tc.Dir, "stack"), ZRange=10:15);
            tc.verifySize(sub, [tc.GT.size(1:2) 6]);
            tc.verifyEqual(sub, full(:,:,10:15));
            tc.verifyEqual(meta.zIndices, 10:15);
        end

        function naturalSortOrder(tc)
            % slice_1, slice_2, ..., slice_10 bez zer -> kolejnosc musi byc numeryczna
            d = fullfile(tc.Dir, "nopad");
            synth.makeSyntheticGratingStack(d, ImageSize=[32 48], NumSlices=25, ...
                SubstrateSlices=3, Depth_um=8, PadNames=false);
            [vol, meta] = io.loadTiffStack(d);
            [~, n2] = fileparts(meta.files{2});
            [~, n10] = fileparts(meta.files{10});
            tc.verifyEqual(string(n2), "slice_2");
            tc.verifyEqual(string(n10), "slice_10");
            tc.verifyEqual(vol(:,:,10), imread(fullfile(d, "slice_10.tif")));
        end

        function multipageEqualsFolder(tc)
            d = fullfile(tc.Dir, "mp");
            synth.makeSyntheticGratingStack(d, ImageSize=[64 96], NumSlices=30, ...
                SubstrateSlices=5, Depth_um=8, Format="multipage");
            a = io.loadTiffStack(fullfile(tc.Dir, "stack"));
            b = io.loadTiffStack(fullfile(d, "stack.tif"));
            tc.verifyEqual(a, b);   % ten sam seed -> identyczne dane
        end

        function errorTooLarge(tc)
            tc.verifyError(@() io.loadTiffStack(fullfile(tc.Dir, "stack"), ...
                MaxRAMFraction=1e-12), "WaferInspector:io:TooLarge");
        end

        function errorWrongBitDepth(tc)
            d = fullfile(tc.Dir, "u8"); mkdir(d);
            imwrite(zeros(16, 16, "uint8"), fullfile(d, "slice_1.tif"));
            tc.verifyError(@() io.loadTiffStack(d), "WaferInspector:io:BitDepth");
        end

        function errorEmptyAndMissing(tc)
            d = fullfile(tc.Dir, "empty"); mkdir(d);
            tc.verifyError(@() io.loadTiffStack(d), "WaferInspector:io:EmptyFolder");
            tc.verifyError(@() io.loadTiffStack(fullfile(tc.Dir, "nie_ma")), ...
                "WaferInspector:io:NotFound");
        end

        function errorBadZRange(tc)
            tc.verifyError(@() io.loadTiffStack(fullfile(tc.Dir, "stack"), ZRange=0:3), ...
                "WaferInspector:io:BadZRange");
        end
    end
end
