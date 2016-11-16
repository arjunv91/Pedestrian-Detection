function draw_det(image, win_posw,win_posh,winw,winh,scores, threshold)
    indx = find(scores > threshold);
    %draw the figure
    %figure;
    imshow(imresize(imread(image),[256 320])); 
    hold on;
    edge_colors={'r','g','b','c','m','y'};
    for i = 1:length(indx)
            ii = indx(i);
            det_rect = [win_posw(ii), win_posh(ii), winw(ii), winh(ii)];
            cindx = randperm(length(edge_colors));
            rectangle('Position',det_rect,'EdgeColor',edge_colors{cindx(1)},'LineWidth',2);
            text(win_posw(ii),win_posh(ii),sprintf('%0.2f',scores(ii)),'Color','y');
    end
end