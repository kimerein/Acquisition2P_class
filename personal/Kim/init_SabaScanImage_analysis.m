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
state.highMeansShutterOff=true; % If a high TTL value in shutter voltage command means shutter is closed; set to "false" if low value engages shutter
state.shutterOpeningTime=9+54; % in ms, the time it takes the shutter to open mechanically after receiving command to open