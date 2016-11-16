%% pick up all the image files
file_name=dir(strcat('../singlepedestrians/*.png'));
file_name1=dir(strcat('../multiplepedestrians/*.png'));

feat_time = zeros(size(file_name,1),1);
feat_time1 = zeros(size(file_name1,1),1);
for i=1:size(file_name,1) 
  im=strcat('../singlepedestrians/',file_name(i).name);
  im1=strcat('../multiplepedestrians/',file_name1(i).name);
  %%imshow(im);
  feat_time(i,1) = pedestrian(im);
  waitforbuttonpress();
%% Uncomment this part of the code to run single and multiple pedestrian dataset simultaneously  
%   feat_time1(i,1) = pedestrian(im1);
%   waitforbuttonpress();
  
  close all;
end
 
%% Uncomment this code to plot the graph
% figure;
% plot(1:size(feat_time,1),feat_time,'r',1:size(feat_time1,1),feat_time1,'g');
% xlabel('Number of images');
% ylabel('Feature Time');
% title('single vs multiple pedestrians');
% legend('single','multiple');

