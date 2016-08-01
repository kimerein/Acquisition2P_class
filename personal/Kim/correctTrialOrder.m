function correctTrialOrder(fileDir,movieOrder)

load([fileDir '\shutterData.mat']);
load([fileDir '\shutterTimesInMovie.mat']);

[~,si]=sort(movieOrder,'ascend');
shutterData=shutterData(si,:);
shutterTimesInMovie=shutterTimesInMovie(si);

save([fileDir '\shutterData.mat'],'shutterData');
save([fileDir '\shutterTimesInMovie.mat'],'shutterTimesInMovie');