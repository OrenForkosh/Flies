function [p_value_permutation comparison gnames] = permutationTestOneWayANOVA(data,group, numPermutations)

    [observedF,tbl,stats] = anova1(data, group,"off");
    % Initialize an array to store permuted F-statistics
    permutedF = ones(numPermutations, 1);

    % Permutation test
    for i = 1:numPermutations
        % Shuffle the observations among groups
        shuffledData = data(randperm(size(data, 1)));

        % Calculate the F-statistic for the permuted data
        permutedF(i) = anova1(shuffledData, group, 'off');
    end
  
    % Calculate p-value by comparing observed F-statistic to permuted values
    p_value_permutation = sum(permutedF < observedF) / numPermutations;
    %if p_value_permutation<0.05
        [comparison,~ ,~,gnames] = multcompare(stats, 'CType', 'tukey-kramer');%,'GroupNamws
      
    %else
       % comparison = "pvalue isnt sig"
    %end
%end
