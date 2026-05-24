% groups = unique([data1.Group; data1.("Control Group")]);

nGroups = numel(conditionNames);
pMatrix = NaN(nGroups, nGroups);

for i = 1:height(data1)
    
    rowIdx = find(strcmp(conditionNames, data1.Group{i}));
    colIdx = find(strcmp(conditionNames, data1.("Control Group"){i}));
    pMatrix(rowIdx, colIdx) = data1.Pvalue(i);
    pMatrix(colIdx, rowIdx) = data1.Pvalue(i); 
end

starMatrix = strings(size(pMatrix)); 

starMatrix(pMatrix > 0.05) = "n.s.";             
starMatrix(pMatrix <= 0.05 & pMatrix > 0.01) = "*";   
starMatrix(pMatrix <= 0.01 & pMatrix > 0.001) = "**"; 
starMatrix(pMatrix <= 0.001) = "***";        
starMatrix(isnan(pMatrix)) = "-";

starTable = array2table(starMatrix, 'RowNames', conditionNames, 'VariableNames', matlab.lang.makeValidName(conditionNames));
