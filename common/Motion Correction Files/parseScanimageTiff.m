function [movStruct, nSlices, nChannels] = parseScanimageTiff(mov, siStruct)

global isSabatiniScanImage

% Check for scanimage version before extracting metainformation

% KR 20160627
% Note that siStruct for Janelia ScanImage 3 has the following fields
% siStruct = 
% 
%     configPath: 'C:\MATLAB_Local\janelia_imaging'
%     configName: '512x154_0.5ms_BiDi_10Hz'
%       software: [1x1 struct]
%            acq: [1x1 struct]
%           init: [1x1 struct]
%          cycle: [1x1 struct]
%          motor: [1x1 struct]
%       internal: [1x1 struct]
% 
% Need to appropriately format/fill-in metadata for Sabatini ScanImage
% siStruct
% 
% Structure of Sabatini ScanImage metadata is
% 
% siStruct.sabaMetadata
% 
% ans = 
% 
%           user: 'KR'
%          epoch: 2
%      epochName: ''
%       software: [1x1 struct]
%       internal: [1x1 struct]
%         pulses: [1x1 struct]
%          files: [1x1 struct]
%          cycle: [1x1 struct]
%     configName: '512 x 128 Green Square 2 ms'
%          pcell: [1x1 struct]
%        blaster: [1x1 struct]
%            acq: [1x1 struct]
%          motor: [1x1 struct]
%          piezo: [1x1 struct]
%           phys: [1x1 struct]
%             lm: [1x1 struct]
if isSabatiniScanImage==1
    fZ = 0;
    nSlices = siStruct.sabaMetadata.acq.numberOfZSlices;
    nChannels = sum([siStruct.sabaMetadata.acq.savingChannel1 siStruct.sabaMetadata.acq.savingChannel2 siStruct.sabaMetadata.acq.savingChannel3 siStruct.sabaMetadata.acq.savingChannel4]);
elseif isfield(siStruct, 'SI4')
    siStruct = siStruct.SI4;
    % Nomenclature: frames and slices refer to the concepts used in
    % ScanImage.
    fZ              = siStruct.fastZEnable;
    nChannels       = numel(siStruct.channelsSave);
    nSlices         = siStruct.stackNumSlices + (fZ*siStruct.fastZDiscardFlybackFrames); % Slices are acquired at different locations (e.g. depths).
elseif isfield(siStruct,'SI5')
     siStruct = siStruct.SI5;
    % Nomenclature: frames and slices refer to the concepts used in
    % ScanImage.
    fZ              = siStruct.fastZEnable;
    nChannels       = numel(siStruct.channelsSave);
    nSlices         = siStruct.stackNumSlices + (fZ*siStruct.fastZDiscardFlybackFrames); % Slices are acquired at different locations (e.g. depths).
elseif isfield(siStruct, 'software') && siStruct.software.version < 4 %ie it's a scanimage 3 file
    fZ = 0;
    nSlices = 1;
    nChannels = siStruct.acq.numberOfChannelsSave;
else
    error('Movie is from an unidentified scanimage version, or metadata is improperly formatted'),
end


% Copy data into structure:
if nSlices>1
    for sl = 1:nSlices-(fZ*siStruct.fastZDiscardFlybackFrames) % Slices, removing flyback.
        for ch = 1:nChannels % Channels
            frameInd = ch + (sl-1)*nChannels;
            movStruct.slice(sl).channel(ch).mov = mov(:, :, frameInd:(nSlices*nChannels):end);
        end
    end
    nSlices = nSlices-(fZ*siStruct.fastZDiscardFlybackFrames);
else
    for sl = 1;
        for ch = 1:nChannels % Channels
            frameInd = ch + (sl-1)*nChannels;
            movStruct.slice(sl).channel(ch).mov = mov(:, :, frameInd:(nSlices*nChannels):end);
        end
    end
end