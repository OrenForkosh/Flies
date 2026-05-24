
function months = findmonth(filepaths)
%%
    % Initialize an empty array to store the months
    months = strings(1, length(filepaths));
    
    % Loop over each file path
    for n = 1:length(filepaths)
        filePath = filepaths{n};
        % Find the date using regular expression
        datePattern = '\d{8}T\d{6}';
        dateMatch = regexp(filePath, datePattern, 'match');

        % Check if the date was found
        if ~isempty(dateMatch)
            % Extract the date string
            dateStr = dateMatch{1};
            % Extract the month
            monthStr = dateStr(1:6);
            % Store the month in the array
            months(n) = monthStr;
        else
            disp('No date found in the string.');
        end
    end
end

