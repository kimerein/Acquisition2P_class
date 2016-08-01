function [shutterData,times]=findShutteredFrames(obj,movieOrder)
% If using command to shutter PMTs, get data on when PMTs are shuttered

% Look for PMT shutter command in same path as selected movie files
movName=obj.Movies{1};
dirBreaks=regexp(movName,'\','start');
shutterPath=movName(1:dirBreaks(end));
listing=dir([shutterPath obj.sabaMetadata.nameShutterCommand '*.mat']);
listingnames=cell(1,length(listing));
for i=1:length(listing)
    listingnames{i}=listing(i).name;
end

shutterData=[];
if ~isempty(listing)
    % PMT shutter command saved during acquisition
    % For each movie file, get associated PMT shutter command
    
    for i=1:length(movieOrder)
        ci=movieOrder(i);
        s=obj.Movies{ci};
        parts=regexp(s,'\','split');
        movName=parts{end};
        fi=regexp(movName,'.tif');
        movName=movName(1:fi-1);
        movNumber=movName(end-2:end);
        % Check that expected file is in directory
        shutterFile=[obj.sabaMetadata.nameShutterCommand '_' num2str(str2num(movNumber)) '.mat'];
        if any(strcmp(listingnames,shutterFile))
            warning('off','MATLAB:unknownObjectNowStruct'); % import wave as struct
            % Load command to shutter
            w=load([shutterPath shutterFile]);
            warning('on','MATLAB:unknownObjectNowStruct'); 
            f=fieldnames(w);
            w=w.(f{1});
            if isempty(shutterData)
                shutterData=nan(length(movieOrder),length(w.data));
            end
            shutterData(i,:)=w.data;
%             if length(w.data)>length(shutterData(i,:))
%                 temp=shutterData;
%                 shutterData=[temp nan(length(movieOrder),length(w.data)-length(shutterData(i,:)))];
%             elseif length(w.data)<length(shutterData(i,:))
%                 shutterData(i,1:length(w.data))=w.data;
%             else
%                 shutterData(i,:)=w.data;
%             end
        else
            disp(['Missing ' obj.sabaMetadata.nameShutterCommand ' file from movie directory']);
        end
    end
end

if isempty(shutterData)
    % No shutter data 
    disp('No shutter data found - using full movies');
    times=[];
    return
else
    samplingRate=obj.sabaMetadata.phys.settings.inputRate; % Get sampling rate of shutterData
    times=0:1/samplingRate:(1/samplingRate)*size(shutterData,2)-(1/samplingRate);
    status=mkdir([shutterPath obj.sabaMetadata.saveShutterDataFolder]);
    if status==1
        save([shutterPath obj.sabaMetadata.saveShutterDataFolder '\shutterData.mat'],'shutterData');
        save([shutterPath obj.sabaMetadata.saveShutterDataFolder '\shutterData_times.mat'],'times');
    else
        disp('Could not save shutter data');
    end
end
    
    
end
    
    
        