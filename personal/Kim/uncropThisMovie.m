function movStruct=uncropThisMovie(movStruct,cropHere)

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
movStruct.slice.channel.mov=mov;