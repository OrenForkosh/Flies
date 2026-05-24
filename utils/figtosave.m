function figtosave(expName, mainDir, figName)
tosavePDF = sprintf("%s.pdf", figName);
tosaveFIG = sprintf("%s.fig", figName);
tosaveEPS = sprintf("%s.eps", figName);
if ismac
cd(sprintf("%s/Figs/%s", mainDir, expName))
else
cd(sprintf("%s\\Figs\\%s", mainDir, expName))
end
exportgraphics(gcf, tosavePDF, 'Resolution', 1000);
savefig(gcf, tosaveFIG);
print(figName, '-dpng', '-r1000');
print(figName, '-depsc', '-r1000');
end
