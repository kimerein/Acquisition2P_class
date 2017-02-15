function motionCorrect(obj,writeDir,motionCorrectionFunction,namingFunction)
%Wrapper function managing motion correction of an acquisition object
%
%motionCorrect(obj,writeDir,motionCorrectionFunction,namingFunction)
%
%writeDir is an optional argument specifying location to write motion
%   corrected data to, defaults to obj.defaultDir\Corrected
%motionCorrectionFunction is a handle to a motion correction function,
%   and is optional only if acquisition already has a function handle
%   assigned to motionCorectionFunction field. If argument is provided,
%   function handle overwrites field in acq obj.
%namingFunction is a handle to a function for naming. If empty, uses
%   default naming function which is a local function of motionCorrect.
%   All naming functions must take in the following arguments (in
%   order): obj.acqName, nSlice, nChannel, movNum.

global isSabatiniScanImage


%% Check whether value of global variable isSabatiniScanImage has been set
if isempty(isSabatiniScanImage)
    button=questdlg('Was data acquired using Sabatini ScanImage (as opposed to Janelia ScanImage)?');
    if strcmp(button,'Cancel') || isempty(button)
        disp('User canceled initialization.');
        return
    elseif strcmp(button,'Yes')
        isSabatiniScanImage=1;
    elseif strcmp(button,'No')
        isSabatiniScanImage=0;
    end
end

%% Error checking and input handling
if ~exist('motionCorrectionFunction', 'var')
    motionCorrectionFunction = [];
end

if nargin < 4 || isempty(namingFunction)
    namingFunction = @defaultNamingFunction;
end

if isempty(motionCorrectionFunction) && isempty(obj.motionCorrectionFunction)
    error('Function for correction not provided as argument or specified in acquisition object');
elseif isempty(motionCorrectionFunction)
    %If no argument but field present for object, use that function
    motionCorrectionFunction = obj.motionCorrectionFunction;
else
    %If using argument provided, assign to obj field
    obj.motionCorrectionFunction = motionCorrectionFunction;
end

if isempty(obj.acqName)
    error('Acquisition Name Unspecified'),
end

if ~exist('writeDir', 'var') || isempty(writeDir) %Use Corrected in Default Directory if non specified
    if isempty(obj.defaultDir)
        error('Default Directory unspecified'),
    else
        writeDir = [obj.defaultDir filesep 'Corrected'];
    end
end

if isempty(obj.defaultDir)
    obj.defaultDir = writeDir;
end

if isempty(obj.motionRefMovNum)
    if length(obj.Movies)==1
        obj.motionRefMovNum = 1;
    else
        error('Motion Correction Reference not identified');
    end
end

%% Load movies and motion correct
%Calculate Number of movies and arrange processing order so that
%reference is first
nMovies = length(obj.Movies);
if isempty(obj.motionRefMovNum)
    obj.motionRefMovNum = floor(nMovies/2);
end
movieOrder = 1:nMovies;
movieOrder([1 obj.motionRefMovNum]) = [obj.motionRefMovNum 1];

% Find when imaging shutter (PMT shutter) is closed
if isSabatiniScanImage==1
    [saba_shutterData,shutterData_times]=findShutteredFrames(obj,movieOrder);
    % Clear existing shutter data saved to this directory
    movName=obj.Movies{1};
    dirBreaks=regexp(movName,'\','start');
    shutterPath=[movName(1:dirBreaks(end)) obj.sabaMetadata.saveShutterDataFolder];
    if exist([shutterPath '\shutterTimesInMovie.mat'],'file')
        delete([shutterPath '\shutterTimesInMovie.mat']);
    end
    % Check for frames shuttered according to distribution of pixel
    % intensities
    [non_artifact_range_min,non_artifact_range_max]=findShutterInMovies(obj,movieOrder);
    non_art_range=[non_artifact_range_min non_artifact_range_max];
end

%Load movies one at a time in order, apply correction, and save as
%split files (slice and channel)
it1=1;
for movNum = movieOrder
    fprintf('\nLoading Movie #%03.0f of #%03.0f\n',movNum,nMovies),
    [mov, scanImageMetadata] = obj.readRaw(movNum,'single');
     
    if isSabatiniScanImage==1
        % Remove movie frames when imaging shutter (PMT shutter) is closed
        [mov,~,temp_shutterData] = removeShutteredFrames(obj,mov,saba_shutterData(movNum==movieOrder,:),shutterData_times,non_art_range);
        saba_shutterData(movNum==movieOrder,:)=temp_shutterData;
        shutterData=saba_shutterData;
        save([shutterPath '\shutterData.mat'],'shutterData'); 
    end
    
    if obj.binFactor > 1
        mov = binSpatial(mov, obj.binFactor);
    end
    
    % Apply line shift:
    fprintf('Line Shift Correcting Movie #%03.0f of #%03.0f\n', movNum, nMovies),
    mov = correctLineShift(mov);
    if isSabatiniScanImage==1
        scanImageMetadata.sabaMetadata=obj.sabaMetadata;
    end
    try
        [movStruct, nSlices, nChannels] = parseScanimageTiff(mov, scanImageMetadata);
    catch
        error('parseScanimageTiff failed to parse metadata'),
    end
    clear mov
    
    % If necessary, crop movie to eliminate no data from turn-around in
    % bidirectional scanning
    % Crop movies only for motion correction, then return movies
    % to normal size before saving for alignment with physiology
    if isSabatiniScanImage==1
        if it1==1
            [movStruct,smallSize,bigSize,cropHere]=cropMovies(movStruct,non_art_range,obj);
            it1=0;
        else
            movStruct=cropThisMovie(movStruct,cropHere);
        end
    end            
    
%     % If necessary, interpolate so that movie appears to be sampled at N
%     % times the actual frame rate -- this may help with motion correction for
%     % GCaMP6f (Fast)
%     Ntimes=4;
%     movStruct=upsampleMovie(movStruct,Ntimes);
    
    % Find motion:
    fprintf('Identifying Motion Correction for Movie #%03.0f of #%03.0f\n', movNum, nMovies),
    obj.motionCorrectionFunction(obj, movStruct, scanImageMetadata, movNum, 'identify');
    
    % Apply motion correction and write separate file for each
    % slice\channel:
    fprintf('Applying Motion Correction for Movie #%03.0f of #%03.0f\n', movNum, nMovies),
    movStruct = obj.motionCorrectionFunction(obj, movStruct, scanImageMetadata, movNum, 'apply');
    
    % Uncrop movie, fill nan outside of cropped movie
    movStruct=uncropThisMovie(movStruct,cropHere);
    
    for nSlice = 1:nSlices
        for nChannel = 1:nChannels
            % Create movie fileName and save in acq object
            movFileName = feval(namingFunction,obj.acqName, nSlice, nChannel, movNum);
            obj.correctedMovies.slice(nSlice).channel(nChannel).fileName{movNum} = fullfile(writeDir,movFileName);
            % Determine 3D-size of movie and store w/ fileNames
            obj.correctedMovies.slice(nSlice).channel(nChannel).size(movNum,:) = ...
                size(movStruct.slice(nSlice).channel(nChannel).mov);            
            % Write corrected movie to disk
            fprintf('Writing Movie #%03.0f of #%03.0f\n',movNum,nMovies),
            try
                tiffWrite(movStruct.slice(nSlice).channel(nChannel).mov, movFileName, writeDir, 'int16');
            catch
                % Sometimes, disk access fails due to intermittent
                % network problem. In that case, wait and re-try once:
                pause(60);
                tiffWrite(movStruct.slice(nSlice).channel(nChannel).mov, movFileName, writeDir, 'int16');
            end
        end
    end
end

% Correct order of trials in shutterData so that first movie/trial is first, not
% reference movie/trial first
movName=obj.Movies{1};
dirBreaks=regexp(movName,'\','start');
shutterPath=[movName(1:dirBreaks(end)) obj.sabaMetadata.saveShutterDataFolder];
correctTrialOrder(shutterPath,movieOrder);

% Store SI metadata in acq object
obj.metaDataSI = scanImageMetadata;

%Assign acquisition to a variable with its own name, and write to same
%directory. Need to ensure that it is a valid variable name:
if verLessThan('matlab', 'R2014a')
    acqVarName = genvarname(obj.acqName);
    eval([acqVarName ' = obj;'])
else
    acqVarName = matlab.lang.makeValidName(obj.acqName);
    eval([acqVarName ' = obj;'])
end

save(fullfile(obj.defaultDir, acqVarName), acqVarName)

display('Motion Correction Completed!')

end

function movFileName = defaultNamingFunction(acqName, nSlice, nChannel, movNum)

movFileName = sprintf('%s_Slice%02.0f_Channel%02.0f_File%03.0f.tif',...
    acqName, nSlice, nChannel, movNum);
end