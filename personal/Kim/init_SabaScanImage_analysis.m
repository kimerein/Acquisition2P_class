function state=init_SabaScanImage_analysis()
% Initializes analysis pipeline to accept data acquired with Sabatini
% ScanImage
% Begun KR 20610627

global isSabatiniScanImage

% Indicates that data was acquired using Sabatini ScanImage
isSabatiniScanImage=logical(true);

% Get Sabatini metadata
[file,pathname]=uigetfile('.txt','Choose one example file containing Sabatini metadata');
fid=fopen([pathname file]);
tline=fgetl(fid);
while ischar(tline)
    try
        eval(tline);
    catch
        eval([tline '[]']);
    end
    tline=fgetl(fid);
end
fclose(fid);
% Sabatini metadata is now stored in state variable

% For removing shuttered frames in movies prior to motion correction
state.nameShutterCommand='Opto_Coming'; % This is the string/name given to the voltage command that shutters the PMTs
state.nameOptoStim='Opto_Stim'; % This is the string/name given to the voltage command to the opto laser
state.highMeansShutterOff=true; % If a high TTL value in shutter voltage command means shutter is closed; set to "false" if low value engages shutter
% state.shutterOpeningTime=9+54; % 65 mm shutter: in ms, the time it takes the shutter to open mechanically after receiving command to open
state.shutterOpeningTime=3+9; % 25 mm shutters: in ms, the time it takes the shutter to open mechanically after receiving command to open
state.saveShutterDataFolder='ShutterData'; % Folder name in which to save shutter data associated with the Acquisition2P instance
state.firstFrameOn=false; % If the first frame of each trial is imaged (should be included); "false" if count first frame as shuttered
state.optoShuttersImaging=true; % If a command to turn on the optogenetic stimulus causes imaging to be shuttered (as a result of hard-wiring of rig)
state.optoCommandThresh=1; % In Volts, the size of command to opto laser below which laser does not turn on at all
state.optoScaleFactor=100; % When read in opto command, what is scaling of input with respect to output? -- 1 if no scaling
state.turnAroundBlank_side1=70; % When bidi, part of image may be blank; number of pixels that are blanked -- code will also ask user to verify this in cropMovies.m
state.turnAroundBlank_side2=10; % When bidi, part of image may be blank; number of pixels that are blanked -- code will also ask user to verify this in cropMovies.m