%% main file to calc teeth projection image segmentation
%% use for test 
close all; clear all; clc;

%% load files
[ mFiles] = RangTraversal( './fig', 'fig' );
sample_count = 1;
sample_index = randperm(length(mFiles), sample_count);% random select several files
% sample_index = 234;
% sample_index = 433;
% sample_index = 447;
% sample_index = 45;
sample_images = {};
for i = 1 : sample_count
    sample_images(i).image = loadfig(cell2mat(mFiles(sample_index(i))));  
end

%% segmentation teeth
figure(1)
B = [0 1 0; 1 1 1; 0 1 0];
for i = 1 : sample_count

    %% edge detection
    bw = filtervalley(sample_images(i).image); %
    [m, n] = size(bw);
    bw2 = bw(3 : m-2, 3 : n-2); 
    edge_threshold = 0.5;%log edge threshold
    bw2(bw2 < edge_threshold) = 0;
    bw2(bw2 > edge_threshold) = 30;

    % edge selection
    % the teeth edge near the up range image border and the second near
    % edge will be selected
    image_out = outer(sample_images(i).image);
    bw3 = sample(bw2, image_out);
    bw3 = link_gap(bw3, 5);
    
    % teeth linked region
    bw3 = ~bw3;
    L = bwlabel(bw3,4);  
    S = regionprops(L, 'area');
    L2 = ismember(L, find([S.Area] >= 20));%delete small region
    L_s = bwlabel(L2,4);
    
    
    % use the out side mask resize the teeth
    L_out =  mask(image_out);
    L_s = L_s .* L_out;

    subplot(sample_count, 2, i * 2 - 1);
    imagesc(L_s + image_out);
    
    % select the region at least part of it near the up border
    L_s = interest_region(L_s, image_out);
    
    % 
    downborder = zeros(1, size(L_s, 2));
    upborder = zeros(1, size(L_s, 2));
    
    x = [];
    y = [];
    %find up/down border for each teeth region
    start_x = 10000;
    end_x = 0;
    for j = 1 : length(downborder)
        teeth_pixel = find(L_s(:, j) ~= 0);
        if ~isempty(teeth_pixel)
            if start_x > j
                start_x = j;
            end
            
            if j > end_x
                end_x = j;
            end
            upborder(j) = min(find(image_out(:, j)~=0));
            downborder(j) = max(teeth_pixel);
%             L_s(downborder(j), j) = 100;
            x = [x, j];
            y = [y, downborder(j)];
        end
    end
    
    yi = spline(x, y, [1 : length(downborder)]);
    yi(floor(yi) <= 0) = 1;
    yi(yi > size(L,1)) = size(L,1);
    downborder = floor(yi);
    upborder_mean = mean(upborder(upborder ~= 0));
    upborder_var = var(upborder(upborder ~= 0));
    for j = start_x : end_x
        if upborder(j) > upborder_mean + 40
            L_s(:, j) = 0;
        end
    end
    
    L = render_link_image(L_s); 
     
    for j = start_x : end_x
        L(floor(yi(j)), j, 1) = L(floor(yi(j)), j ,1) + 10;
        L(upborder(j) + 1, j, 1) = L(upborder(j) + 1, j ,1) + 10;
    end
    
    
    temp_image = sample_images(i).image;
    for j = start_x : end_x
        s = min(find(image_out(:, j)~=0));    
        temp_image( s : floor(yi(j)), j) = 50;
    end
    subplot(sample_count, 2, i * 2);  
%     image(temp_image);
    imagesc(L);
end