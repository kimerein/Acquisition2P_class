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

