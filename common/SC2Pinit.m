function SC2Pinit(obj)
%Example of an Acq2P Initialization Function. Allows user selection of
%movies to form acquisition, sorts alphabetically, assigns an acquisition
%name and default directory, and assigns the object to a workspace variable
%named after the acquisition name

% If data was acquired using Sabatini ScanImage, initialize data analysis
% pipeline to deal with structure of saved Sabatini ScanImage data
button=questdlg('Was data acquired using Sabatini ScanImage (as opposed to Janelia ScanImage)?');
if strcmp(button,'Cancel') || isempty(button)
    disp('User canceled initialization.');
    return
elseif strcmp(button,'Yes')
    obj.sabaMetadata=init_SabaScanImage_analysis;
elseif strcmp(button,'No')
end

%Initialize user selection of multiple tif files
[movNames, movPath] = uigetfile('*.tif','MultiSelect','on');

%Set default directory to folder location,
obj.defaultDir = movPath;

% For Saba scanimage, sort movies by number at end of file name -- this
% number indicates order in which movies were acquired
if strcmp(button,'Yes')
    % Sort based on number at end of file name
    % Assumes that file name always ends with a number
    movNumbers=nan(1,length(movNames));
    for i=1:length(movNames)
        currMovName=movNames{i};
        currMovName=fliplr(currMovName);
        startInd=regexp(currMovName,'\.','once'); 
        currMovName=currMovName(startInd+1:end);
        isNumberInd=regexp(currMovName,'\d');
        numberEnds=find(diff(isNumberInd)>1.05,1,'first');
        numberMovName=currMovName(1:numberEnds);
        numberMovName=fliplr(numberMovName);
        movNumbers(i)=str2num(numberMovName);
    end
    [~,inds]=sort(movNumbers); 
    movNames=movNames(inds);
else
    %sort movie order alphabetically for consistent results
    movNames = sort(movNames);
end

%Attempt to automatically name acquisition from movie filename, raise
%warning and create generic name otherwise
try
    acqNamePlace = find(movNames{1} == '_',1);
    obj.acqName = movNames{1}(1:acqNamePlace-1);
catch
    obj.acqName = sprintf('%s_%.0f',date,now);
    warning('Automatic Name Generation Failed, using date_time')
end

%Attempt to add each selected movie to acquisition in order
for nMov = 1:length(movNames)
    obj.addMovie(fullfile(movPath,movNames{nMov}));
end

%Automatically fill in fields for motion correction
obj.motionRefMovNum = floor(length(movNames)/2);
obj.motionRefChannel = 1;
obj.binFactor = 1;
obj.motionCorrectionFunction = @withinFile_withinFrame_lucasKanade;

%Assign acquisition object to acquisition name variable in workspace
assignin('base',obj.acqName,obj);

%Notify user of success
fprintf('Successfully added %03.0f movies to acquisition: %s\n',length(movNames),obj.acqName),