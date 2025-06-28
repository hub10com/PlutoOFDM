classdef OFDMScopeManager < handle
    properties
        params
        spectrumScope
        constellationScope
        berHistory
        cfoHistory
        chEstMSEHistory
        berFig
        cfoFig
        chEstFig
    end

    methods
        function obj = OFDMScopeManager(params)
            obj.params = params;

            obj.berHistory       = [];
            obj.cfoHistory       = [];
            obj.chEstMSEHistory  = [];

            % Başta figure oluşturulmuyor — ihtiyaç olunca açılacak
            obj.berFig    = [];
            obj.cfoFig    = [];
            obj.chEstFig  = [];

            % Spectrum analyzer objesi
            obj.spectrumScope = spectrumAnalyzer( ...
                'SampleRate',            params.BasebandSampleRate, ...
                'SpectrumType',          'Power', ...
                'PlotAsTwoSidedSpectrum', true, ...
                'YLimits',               [-80 10], ...
                'Title',                 'RX Spectrum', ...
                'ShowLegend',            true, ...
                'ChannelNames',          'RX Frame');

            % Constellation diagram objesi
            obj.constellationScope = comm.ConstellationDiagram( ...
                'ReferenceConstellation', getConstellationPoints(params), ...
                'SamplesPerSymbol',       1, ...
                'SymbolsToDisplaySource', 'Property', ...
                'SymbolsToDisplay',       1000, ...
                'ShowTrajectory',         false, ...
                'Title',                  'Constellation Diagram');
        end

        function plotSpectrum(obj, rxFrame)
            obj.spectrumScope(rxFrame(:));
        end

        function updateBER(obj, frameIdx, berValue)
            obj.berHistory(end+1) = berValue;

            if isempty(obj.berFig) || ~isvalid(obj.berFig)
                obj.berFig = figure('Name', 'BER vs Frame', 'NumberTitle', 'off');
            else
                figure(obj.berFig);
            end

            plot(1:frameIdx, obj.berHistory, '-o', 'LineWidth', 2);
            xlabel('Frame Index');
            ylabel('BER');
            grid on;
            title('BER vs Frame');
        end

        function updateCFOEstimate(obj, frameIdx, cfoHz)
            obj.cfoHistory(end+1) = cfoHz;

            if isempty(obj.cfoFig) || ~isvalid(obj.cfoFig)
                obj.cfoFig = figure('Name', 'Çerçeve Başına CFO Tahmini', 'NumberTitle', 'off');
            else
                figure(obj.cfoFig);
            end

            plot(1:frameIdx, obj.cfoHistory, '-o', 'LineWidth', 2);
            xlabel('Çerçeve İndisi');
            ylabel('Tahmin Edilen CFO (Hz)');
            grid on;
            title('Çerçeve Başına CFO Tahmini');
        end

        function updateChannelMSE(obj, frameIdx, mseValue)
            obj.chEstMSEHistory(end+1) = mseValue;

            if isempty(obj.chEstFig) || ~isvalid(obj.chEstFig)
                obj.chEstFig = figure('Name', 'Çerçeve Başına Kanal Tahmini', 'NumberTitle', 'off');
            else
                figure(obj.chEstFig);
            end

            plot(1:frameIdx, obj.chEstMSEHistory, '-o', 'LineWidth', 2);
            xlabel('Çerçeve İndisi');
            ylabel('Kanal Tahmini (MSE)');
            grid on;
            title('Çerçeve Başına Kanal Tahmini');
        end

        function plotConstellation(obj, rxSymbols)
            obj.constellationScope(rxSymbols(:));
        end
    end
end

%% Yardımcı fonksiyon — Modülasyon tipine göre constellation noktalarını ver
function refConst = getConstellationPoints(params)
    switch params.Modulation
        case 'BPSK'
            refConst = [-1 +1];
        case 'QPSK'
            refConst = [ 1+1j, -1+1j, -1-1j, 1-1j ] / sqrt(2);
        case '8PSK'
            refConst = pskmod(0:7, 8);
        case '16PSK'
            refConst = pskmod(0:15, 16);
        case '16QAM'
            re = [-3 -1 1 3];
            [I,Q] = meshgrid(re,re);
            refConst = (I(:) + 1j*Q(:)) / sqrt(10);
        case '64QAM'
            re = [-7 -5 -3 -1 1 3 5 7];
            [I,Q] = meshgrid(re,re);
            refConst = (I(:) + 1j*Q(:)) / sqrt(42);
        otherwise
            warning('Modulation type %s unknown — using default QPSK', params.Modulation);
            refConst = [ 1+1j, -1+1j, -1-1j, 1-1j ] / sqrt(2);
    end
end
