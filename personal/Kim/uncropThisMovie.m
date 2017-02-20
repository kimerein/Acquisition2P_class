function movStruct=uncropThisMovie(movStruct,cropHere)

persistent fakeData

% Uncrop, fill with nans
mov=nan(length(cropHere.rows),length(cropHere.columns),size(movStruct.slice.channel.mov,3));
rowInds=find(cropHere.rows==0);
columnInds=find(cropHere.columns==0);
temp=nan(length(cropHere.rows),size(movStruct.slice.channel.mov,2),size(movStruct.slice.channel.mov,3));
for i=1:length(rowInds)
    ri=rowInds(i);
    temp(ri,:,:)=movStruct.slice.channel.mov(i,:,:);
end
for i=1:length(columnInds)
    ci=columnInds(i);
    mov(:,ci,:)=temp(:,i,:);
end

if isempty(fakeData)
   fakeData=randi(2,1,size(mov,3)); 
else
   if length(fakeData)~=size(mov,3)
       fakeData=randi(2,1,size(mov,3)); 
   end
end

% Check that no pixels are always zero
% This check is required for movie to work with CNMF Ca2+ source detection
movsum=reshape(sum(mov,3),size(mov,1),size(mov,2));
[rowind,columnind]=find(movsum==0 | all(isnan(movsum),3));
mov(isnan(mov))=0;
for i=1:length(rowind)
    mov(rowind(i),columnind(i),:)=mov(rowind(i),columnind(i),:)+reshape(fakeData,1,1,length(fakeData));
end

movStruct.slice.channel.mov=mov;