classdef tSyntheticGenerator < matlab.unittest.TestCase
    % Sprawdza, czy generator produkuje dane zgodne z wlasnym ground truth.

    properties
        Dir
    end

    methods (TestClassSetup)
        function addSrc(tc)
            root = fileparts(fileparts(mfilename("fullpath")));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, "src")));
        end
    end

    methods (TestMethodSetup)
        function tmp(tc)
            f = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            tc.Dir = string(f.Folder);
        end
    end

    methods (Test)
        function fileCountAndJson(tc)
            d = fullfile(tc.Dir, "a");
            gt = synth.makeSyntheticGratingStack(d, ImageSize=[64 64], NumSlices=60);
            tc.verifyNumElements(dir(fullfile(d, "*.tif")), 60);
            tc.verifyTrue(isfile(fullfile(d, "ground_truth.json")));
            j = jsondecode(fileread(fullfile(d, "ground_truth.json")));
            tc.verifyEqual(j.expected, char(gt.expected));
        end

        function passCaseHasNoDefects(tc)
            gt = synth.makeSyntheticGratingStack(fullfile(tc.Dir, "p"), ...
                ImageSize=[64 64], NumSlices=60, Defects=strings(0));
            tc.verifyEmpty(gt.defects);
            tc.verifyEqual(gt.expected, "PASS");
        end

        function failCaseHasDefects(tc)
            gt = synth.makeSyntheticGratingStack(fullfile(tc.Dir, "f"), ...
                ImageSize=[128 128], NumSlices=60);
            tc.verifyEqual(gt.expected, "FAIL");
            tc.verifyEqual(sort(string({gt.defects.type})), ["collapse" "grass"]);
        end

        function reproducibleWithSeed(tc)
            a = synth.makeSyntheticGratingStack(fullfile(tc.Dir, "s1"), ImageSize=[32 32], NumSlices=60, Seed=7);
            b = synth.makeSyntheticGratingStack(fullfile(tc.Dir, "s2"), ImageSize=[32 32], NumSlices=60, Seed=7);
            tc.verifyEqual(imread(fullfile(tc.Dir, "s1", "slice_0030.tif")), ...
                           imread(fullfile(tc.Dir, "s2", "slice_0030.tif")));
            tc.verifyEqual(a.defects, b.defects);
        end

        function gratingPitchVisibleInImage(tc)
            % Srodkowy przekroj lamel: FFT profilu musi miec pik na 1/pitch
            d = fullfile(tc.Dir, "g");
            gt = synth.makeSyntheticGratingStack(d, ImageSize=[64 256], NumSlices=60, ...
                Defects=strings(0), NoiseSigma=0);
            zMid = round((gt.zSubstrateTop + gt.zGratingTop)/2);
            img  = double(imread(fullfile(d, sprintf("slice_%04d.tif", zMid))));
            p    = mean(img, 1); p = p - mean(p);
            P    = abs(fft(p)); P(1) = 0;
            [~, k] = max(P(1:floor(end/2)));
            measuredPitch = numel(p) / (k-1);
            tc.verifyEqual(measuredPitch, gt.pitch_px, AbsTol=1);
        end

        function substrateBrighterThanAir(tc)
            d = fullfile(tc.Dir, "c");
            gt = synth.makeSyntheticGratingStack(d, ImageSize=[64 64], NumSlices=60);
            sub = imread(fullfile(d, sprintf("slice_%04d.tif", 1)));
            air = imread(fullfile(d, sprintf("slice_%04d.tif", gt.size(3))));
            tc.verifyGreaterThan(mean(sub(:)), mean(air(:)) + 10000);
        end

        function tooShallowStackErrors(tc)
            tc.verifyError(@() synth.makeSyntheticGratingStack(fullfile(tc.Dir, "e"), ...
                NumSlices=10), "synth:TooShallow");
        end
    end
end
