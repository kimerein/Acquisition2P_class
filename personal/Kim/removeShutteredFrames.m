function mov=removeShutteredFrames(obj,mov,shutterData,times)
% Removes shuttered frames from movie

% Get times associated with each movie frame
frameDuration=(obj.sabaMetadata.acq.msPerLine/1000)*obj.sabaMetadata.acq.linesPerFrame;
movieDuration=frameDuration*obj.sabaMetadata.acq.numberOfFrames;
movieTimes=0:frameDuration:frameDuration*obj.sabaMetadata.acq.numberOfFrames-frameDuration;

if length(movieTimes)~=size(mov,3)
    error('Movie size does not match Sabatini metadata');
end

% For windows when shutter is closed, remove movie frames
% Find windows when shutter is closed
% Shutter command is assumed to be TTL
shutterStateChanges=find(abs(diff(shutterData))>2.5);
shutterOffWindows=[];
if obj.sabaMetadata.highMeansShutterOff==1
    if shutterData(1)<2.5
        % Shutter starts on
        % Thus shutter off windows are
        for i=1:2:length(shutterStateChanges)
            if i+1>length(shutterStateChanges)
                shutterOffWindows=[shutterOffWindows; shutterStateChanges(i) length(shutterStateChanges)];
            else
                shutterOffWindows=[shutterOffWindows; shutterStateChanges(i) shutterStateChanges(i+1)];
            end
        end
    else
        % Shutter starts off
        % Thus shutter off windows are
        for i=1:2:length(shutterStateChanges)
            if i-1<1
                shutterOffWindows=[shutterOffWindows; 0 shutterStateChanges(1)];
            else
                shutterOffWindows=[shutterOffWindows; shutterStateChanges(i-1) shutterStateChanges(i)];
            end
        end
    end
elseif obj.sabaMetadata.highMeansShutterOff==0
    if shutterData(1)>2.5
        % Shutter starts on
        % Thus shutter off windows are
        for i=1:2:length(shutterStateChanges)
            if i+1>length(shutterStateChanges)
                shutterOffWindows=[shutterOffWindows; shutterStateChanges(i) length(shutterStateChanges)];
            else
                shutterOffWindows=[shutterOffWindows; shutterStateChanges(i) shutterStateChanges(i+1)];
            end
        end
    else
        % Shutter starts off
        % Thus shutter off windows are
        for i=1:2:length(shutterStateChanges)
            if i-1<1
                shutterOffWindows=[shutterOffWindows; 0 shutterStateChanges(1)];
            else
                shutterOffWindows=[shutterOffWindows; shutterStateChanges(i-1) shutterStateChanges(i)];
            end
        end
    end
end
shutterOffWindows=shutterOffWindows+1; % Shift for indexing into times
shutterOffTimes=reshape(times(shutterOffWindows(1:end)),size(shutterOffWindows,1),size(shutterOffWindows,2));

% Take into account mechanical delay in shutter opening
shutterOffTimes(:,2)=shutterOffTimes(:,2)+(obj.sabaMetadata.shutterOpeningTime/1000); % shutterOpeningTime was given in ms, convert to s
% Take into account duration of acquisition of each frame
shutterOffTimes(:,1)=shutterOffTimes(:,1)-frameDuration;

% Remove shuttered frames from movie
isShutteredFrame=zeros(size(movieTimes));
for i=1:size(shutterOffTimes,1)
    isShutteredFrame(movieTimes>=shutterOffTimes(i,1) & movieTimes<=shutterOffTimes(i,2))=1;
end
mov=mov(:,:,isShutteredFrame==0);
    
    