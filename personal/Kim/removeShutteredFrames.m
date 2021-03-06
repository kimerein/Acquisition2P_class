function [mov,isShutteredFrame,shutterData]=removeShutteredFrames(obj,mov,shutterData,times,non_art_range)
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
shutterOnThresh=20;
shutterStateChanges=find(abs(diff(shutterData))>100);
shutterOffWindows=[];
if obj.sabaMetadata.highMeansShutterOff==1
    if shutterData(1)<shutterOnThresh
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
    if shutterData(1)>shutterOnThresh
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

% Remove shuttered frames from movie (according to shutter command)
isShutteredFrame=zeros(size(movieTimes));
for i=1:size(shutterOffTimes,1)
    isShutteredFrame(movieTimes>=shutterOffTimes(i,1) & movieTimes<=shutterOffTimes(i,2))=1;
end

% Remove frames shuttered according to distribution of pixel values
isEmpiricallyShuttered=zeros(size(isShutteredFrame));
temp=mov(:,:,isShutteredFrame==0);
meds=median(double(temp(1:end)));
stds=std(double(temp(1:end)));
for i=1:size(mov,3)
    temp1=mov(:,:,i);
    temp=(nanmean(temp1,2)-meds)/stds; % Z-score: Average of fluorescence in lines
    if any(temp<non_art_range(1)) || any(temp>non_art_range(2))
        isEmpiricallyShuttered(i)=1;
    end   
end

% If first frame is on
if obj.sabaMetadata.firstFrameOn==1
    isEmpiricallyShuttered(1)=0;
else
    if isEmpiricallyShuttered(1)==1
        mov(:,:,1)=mov(:,:,2);
    end
end

% Add empirically shuttered frames to shutter data
empiricallyShuttered_movieTimes=movieTimes(isEmpiricallyShuttered==1);
movieTimeBinSize=(movieTimes(2)-movieTimes(1))-(times(2)-times(1));
for i=1:length(empiricallyShuttered_movieTimes)
    % Find indices into times when movie is empirically shuttered
    useInd=times>=empiricallyShuttered_movieTimes(i) & times<=empiricallyShuttered_movieTimes(i)+movieTimeBinSize;
    shutterData(useInd)=shutterData(useInd)+5; % Add shutter here
end

% % Fill in empirically shuttered frames with preceding image
% theseFrames=find(isEmpiricallyShuttered==1);
% for i=1:length(theseFrames)
%     fillInFrameInd=theseFrames(i);
%     if fillInFrameInd==1
%     else
%         mov(:,:,fillInFrameInd)=mov(:,:,fillInFrameInd-1);
%     end
% end

% Remove shuttered frames from movie
empiricalShutter=(isShutteredFrame==1) | (isEmpiricallyShuttered==1);
mov=mov(:,:,empiricalShutter==0);

movName=obj.Movies{1};
dirBreaks=regexp(movName,'\','start');
shutterPath=[movName(1:dirBreaks(end)) obj.sabaMetadata.saveShutterDataFolder];
listing=what(shutterPath);
q=strfind(listing.mat,'shutterTimesInMovie');
isThere=0;
for i=1:length(q)
    if q{i}==1
        isThere=i;
        load([shutterPath '\' listing.mat{i}]);
        break
    end
end
if isThere==0
    shutterTimesInMovie=cell(0);
end
currlength=length(shutterTimesInMovie);
currlength=currlength+1;
shutterTimesInMovie{currlength}=empiricalShutter;
if length(empiricalShutter(empiricalShutter==0))~=size(mov,3)
    error('Mismatch in sizes of isShutteredFrame and mov in removeShutteredFrames.m');
end
save([shutterPath '\shutterTimesInMovie.mat'],'shutterTimesInMovie');

    