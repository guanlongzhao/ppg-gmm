function tgPlot(tg, subPlotStartIndex)
% function tgPlot(tg, subPlotStartIndex)
%
% Plots TextGrid.
% 
% subPlotStartIndex: optional argument, it indicates the initial index of
% subplot where the first tier is going to be plotter. It is useful, e.g,
% in a situation when we want to draw a wave in the first position, a
% PitchTier in a second position, and begin tiers of the textgrid in the
% third position. Then, the total number of subplot panels is
% subplot(ntiers + subPlotStartIndex - 1, 1, ...)
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgPlot(tg);
%
%   figure
%   pt = ptRead('demo/H.PitchTier');
%   tgPlot(tg, 2);
%   subplot(tgGetNumberOfTiers(tg)+1, 1, 1);
%   ptPlot(pt);

if nargin  == 1
    subPlotStartIndex = 1;
elseif nargin  == 2
    if ~isInt(subPlotStartIndex) || subPlotStartIndex < 1
        error(['subPlotStartIndex must be integer >= 1 [' num2str(subPlotStartIndex) ']']);
    end
else
    error('Wrong number of arguments.')
end

ntiers = tgGetNumberOfTiers(tg);
if ntiers == 0
    subplot 111
    title('Empty TextGrid')
end

for I = 1: ntiers
    subplot(ntiers + subPlotStartIndex - 1, 1, I + subPlotStartIndex - 1)
    
    if tgIsPointTier(tg, I)
%         title('point tier')
        StemHandle = stem(tg.tier{I}.T, 2*0.5*ones(size(tg.tier{I}.T)), 'fill', 'MarkerSize', 2);
        
        Xd = get(StemHandle, 'XData');
        Yd = get(StemHandle, 'YData');
        for K = 1 : length(Xd)
            lab = tg.tier{I}.Label{K};
            lab = strrep(lab, '\', '\\'); lab = strrep(lab, '_', '\_');
            lab = strrep(lab, '^', '\^'); lab = strrep(lab, '{', '\{');
            lab = strrep(lab, '}', '\}');
            text(Xd(K), Yd(K) * 1.3, lab, 'HorizontalAlignment', 'center');
        end
        axis([tg.tmin tg.tmax 0 2])
        set(gca,'YTick',[])
        
    elseif tgIsIntervalTier(tg, I)
%         title('interval tier')
        StemHandle = stem(tg.tier{I}.T1, 2*0.8*ones(size(tg.tier{I}.T1)), 'MarkerSize', 1);
        hold on
        stem(tg.tier{I}.T2, 2*0.5*ones(size(tg.tier{I}.T2)), 'MarkerSize', 1);
        for K = 1: length(tg.tier{I}.T1)
            plot([tg.tier{I}.T1(K) tg.tier{I}.T2(K)], 2*[0.5 0.5]);
        end
        hold off
        
        Xd = get(StemHandle, 'XData');
        Yd = get(StemHandle, 'YData');
        for K = 1 : length(Xd)
            lab = tg.tier{I}.Label{K};
            lab = strrep(lab, '\', '\\'); lab = strrep(lab, '_', '\_');
            lab = strrep(lab, '^', '\^'); lab = strrep(lab, '{', '\{');
            lab = strrep(lab, '}', '\}');
            text(Xd(K), Yd(K) * (1.3*0.5)/(0.8), lab, 'HorizontalAlignment', 'left');
        end
        axis([tg.tmin tg.tmax 0 2])
        set(gca,'YTick',[])
    else
        error('unknown tier type')
    end
    
    ylabel(tg.tier{I}.name);
end
