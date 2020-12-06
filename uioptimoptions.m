function newOpts = uioptimoptions()
% Function uioptimoptions provides a simple UI for optimoptions
%
% Example: opts = uioptimoptions
% 
% OUTPUT: optim.options.Solvername class
% 
% This function will create a optim.options.Solvername class with the
% settings obtained from the user input in UI
%
% Tested: R2020b
% Author: Mario Malic mario@mariomalic.com
% History:
%   06-Dec-2020, initial release

%% Creating UIFigure window
    
    % UIFigure component
    screenRes = get(groot, 'ScreenSize');
    uiFigPos = [0.1*screenRes(3), 0.1*screenRes(4), ...
        0.3*screenRes(3), 0.6*screenRes(4)];
    uiFig = uifigure('Name', 'uioptimoptions', ...
        'Position', uiFigPos, ...
        'CloseRequestFcn', @uiFigCloseRequest);

    % UITable component
    uiTablePos = [0.05*uiFigPos(3) 0.05*uiFigPos(4) ...
        0.9*uiFigPos(3) 0.85*uiFigPos(4)];
    uiTable = uitable(uiFig, 'Position', uiTablePos, ...
        'ColumnName', {'Property', 'Value'}, ...
        'ColumnEditable', [false, true], ...
        'CellSelectionCallback', @uiTableCellSelected, ...
        'CellEditCallback', @uiTableCellEdit);

    % DropDownMenu component
    ddPos = [0.05*uiFigPos(3) 0.93*uiFigPos(4), ...
        0.4*uiFigPos(3), 0.04*uiFigPos(4)];
    ddItems = {'Select the solver', 'fgoalattain', 'fmincon', ...
        'fminimax', 'fminunc', 'fminunc', 'fseminf', 'fsolve', ...
        'ga', 'gamultiobj', 'intlinprog', 'linprog', 'lsqcurvefit', ...
        'lsqlin', 'lsqnonlin', 'paretosearch', 'particleswarm', ...
        'patternsearch', 'quadprog', 'simulannealbnd', 'surrogateopt'};
    ddInitValue = ddItems{1};
    ddMenu = uidropdown(uiFig, 'Position', ddPos, ...
        'Items', ddItems, ...
        'Value', ddInitValue, ...
        'ValueChangedFcn', @ddMenuValueChanged);

    % Clear button component
    clearButtonPos = [0.55*uiFigPos(3) 0.93*uiFigPos(4), ...
        0.175*uiFigPos(3), 0.04*uiFigPos(4)];
    clearButton = uibutton(uiFig, 'Position', clearButtonPos, ...
        'Text', 'Clear value', 'ButtonPushedFcn', @ClearButtonPushed, ...
        'Tooltip', 'Clears values with uneditable content, such as [1x1 cell]'); %#ok<NASGU>

    % Confirm button component
    confirmButtonPos = [0.775*uiFigPos(3) 0.93*uiFigPos(4), ...
        0.175*uiFigPos(3), 0.04*uiFigPos(4)];
    confirmButton = uibutton(uiFig, 'Position', confirmButtonPos, ...
        'Text', 'Confirm', 'ButtonPushedFcn', @ConfirmButtonPushed); %#ok<NASGU>

    % Nested variables
    tempOpts = [];
    newOpts = [];
    selectedProp = [];

    % Wait until the window is closed
    waitfor (uiFig)

%% Callbacks
    % Value changed function: ddMenu
    function ddMenuValueChanged(~, ~)
        % Callback GetOptimOptions gets default options for chosen solver
        if strcmpi('Select the solver', ddMenu.Value)
            uiTable.Data = [];
        else
            tempOpts = optimoptions(ddMenu.Value);
            DisplayOptimOptions(tempOpts)
        end
    end

    % Cell edit callback: uiTable
    function uiTableCellEdit(src, event)
        % Sets input from the Value column to the corresponding field of
        % temporary options
        propName = src.Data{event.Indices(1), 1}{1,1}; % Property name
        propValIndex = {event.Indices(1), 'propVals'};
        % NewData is the variable type of the table value being changed
        % Identify what is the type of variable selected in the table 
        % and change it to corresponding optimoptions property:
            % 1) Function handles inside cells (empty fields are expected to
            %    be numeric, therefore they need to be changed to function
            %    handles)
            % 2) Function handles that are size of 1 (same as above)
            % 3) Numeric values (default values such as sqrt(eps) is a char array,
            %    therefore NewData will also be a char, need to change to numeric value)
            % 4) Fields that accept char arrays, but their initial values
            %    are empty are treated as numeric array, input the EditData
            % 5) Input error, user inputs a character into property that
            %    accepts numeric value only
        try
        tempOpts.(propName) = event.NewData;
        catch exc
            switch exc.identifier
                case 'optim:options:meta:FcnWithCellType:validate:InvalidFcnWithCellType' % 1)
                    if any(strcmpi(propName, {'HybridFcn', 'JacobianMultiplyFcn', ...
                            'HessianMultiplyFcn'}))
                        propVal = str2func(event.EditData);
                    elseif strcmpi(propName, 'HessianFcn')
                        propVal = event.EditData;
                    else
                        tempVal = strrep(event.EditData, ' ', ''); % removes space in char array
                        tempVal = split(tempVal, ",", 2); % splits char array into cells
                        propVal = cellfun(@str2func, tempVal, 'UniformOutput', false);
                        src.Data{propValIndex{:}}{1,1} = propVal; 
                    end
                case 'optim:options:meta:FcnType:validate:InvalidFcnType' % 2)
                    if any(strcmpi(propName, {'HybridFcn', 'JacobianMultiplyFcn', ...
                            'HessianFcn', 'HessianMultiplyFcn'}))
                        propVal = str2func(event.EditData);
                    else
                        tempVal = split(event.EditData, ",", 2);
                        propVal = cellfun(@str2func, tempVal, 'UniformOutput', false);
                        src.Data{propValIndex{:}}{1,1} = propVal;
                    end
                case 'optim:options:meta:NumericType:validate:InvalidNumericVectorType' % 3)
                    propVal = str2num(event.EditData);
                    src.Data{propValIndex{:}}{1,1} = propVal;
                case 'optim:options:meta:IntegerType:validate:NotANonNegIntegerType' % 3)
                    propVal = str2num(event.EditData);
                    src.Data{propValIndex{:}}{1,1} = propVal;
                case 'optim:options:meta:MatrixStructType:validate:NonRealEntries' % 3)
                    propVal = str2num(event.EditData);
                    src.Data{propValIndex{:}}{1,1} = propVal;
                case 'optim:options:meta:NumericType:validate:InvalidMatrixType' % 3)
                    propVal = str2num(event.EditData);
                    src.Data{propValIndex{:}}{1,1} = propVal;
                case 'optim:options:meta:FileType:validate:FileNameNotScalarText' % 4)
                    propVal = event.EditData;
                    src.Data{propValIndex{:}}{1,1} = propVal;
                case 'optim:options:meta:ToleranceType:validate:NotAToleranceScalar' % 5)
                    uialert(uiFig, exc.message, 'Error');
                otherwise
                    uialert(uiFig, exc.message, 'Error');
            end
        end

        % If known exception has been caught, propVal will exist, otherwise 
        % uialert will show
        if exist('propVal', 'var')
            try
                tempOpts = optimoptions(tempOpts, propName, propVal);
            catch exc % If any other unexpected errors are encountered
                uialert(uiFig, exc.message, 'Error');
            end
        end
        DisplayOptimOptions(tempOpts);
    end

    % Cell selected callback: uiTable
    function uiTableCellSelected(src, event)
        selectedProp = src.Data{event.Indices(1), 'fields'}{1,1}; 
    end

    % Button pushed function: clearButton
    function ClearButtonPushed(~, ~)
        try
        tempOpts = optimoptions(tempOpts, selectedProp, []);
        catch exc % if property value that cannot be empty is cleared
            uialert(uiFig, exc.message, 'Error');
        end
        DisplayOptimOptions(tempOpts)
    end

    % Button pushed function: confirmButton
    function ConfirmButtonPushed(~,~)
        newOpts = tempOpts;
        delete(uiFig);
    end

    % Close request function: uiFig
    function uiFigCloseRequest(~,~)
        disp('Operation aborted by user');
        delete(uiFig);
    end

%% Functions
    % function DisplayOptimOptions receives optimoptions and displays it in
    % the uiTable component
    function DisplayOptimOptions(opts)
        % Get fields, their values and put them in UITable
        fields = fieldnames(opts);          
        propVals = cell(length(fields), 1);
        for ii = 1:length(fields)
            propVals{ii,1} = opts.(fields{ii,1});
        end
        solverTable = table(fields, propVals);
        uiTable.Data = solverTable;
    end

end
