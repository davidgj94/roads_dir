function [] = road_segmentation(folder)

img = logical(imread(strcat(folder, '/mask.png')));
sat = imread(strcat(folder, '/sat.png'));

W = 2^8 + 1;
L = 2^7 + 21;

img = img(1:1200,:);
sat = sat(1:1200,:,:);
img = padarray(img,[500,  500]);
sat = padarray(sat,[500, 500]);

imwrite(img, strcat(folder,'/mask_padded.png'));
imwrite(sat, strcat(folder,'/sat_padded.png'));

%figure, imshow(img)
sz = size(img);

se = strel('disk',10);
closed_img = imclose(img,se);


segment_road(closed_img, sat, L, W, folder)

function [tang_angle] = get_tang_angle(skel, x, y, block_size)

    block_dist = floor(block_size./2);
    y_dist = block_dist(1);
    x_dist = block_dist(2);
    block = skel(y-y_dist:y+y_dist, x-x_dist:x+x_dist);
    rp = regionprops(block,'Orientation');
    tang_angle = rp.Orientation;
    
end

function [end_points] = navigate_skel(skel)

    sz = size(skel);
    
    E = bwmorph(skel, 'endpoints');
    [y_e, x_e] = find(E);
    
    D = bwdistgeodesic(logical(skel), x_e(1), y_e(1));
    D(isnan(D)) = Inf;
    [y, x] = find(D < Inf);
    v_dist = D(sub2ind(sz, y, x));
    [~, indices] = sort(v_dist);
    
    y_ref = y(indices(1));
    x_ref = x(indices(1));
    
    end_points = [];
    end_points =  [end_points, sub2ind(sz, y_ref, x_ref)];
    
    ref_angle = get_tang_angle(skel, x_ref, y_ref, [31, 31]);
    
    thresh = 4.5;
    
    for k = 2:length(indices)
        y_k = y(indices(k));
        x_k = x(indices(k));
        tang_angle = get_tang_angle(skel, x_k, y_k, [31, 31]);
        if abs(tang_angle - ref_angle) > thresh
            y_ref = y_k;
            x_ref = x_k;
            ref_angle = tang_angle;
            end_points =  [end_points, sub2ind(sz, y_ref, x_ref)];
        end
    end
    
    end_points =  [end_points, sub2ind(sz, y(indices(end)), x(indices(end)))];
    
end

function rotation_angle = get_rotation_angle(points, sz)

    [Y,X] = ind2sub(sz,points);
    p1 = [X(1), Y(1)];
    p2 = [X(2), Y(2)];
    rotation_angle = 90 - atand((p1(2)-p2(2))/(p1(1)-p2(1))); 
    
end

function midpoint = get_midpoint(points, sz)

    [Y,X] = ind2sub(sz,points);
    midpoint = uint16([mean(X),mean(Y)]);
    
end

function enhanced_img = enhance_contrast(img)

    hsv = rgb2hsv(img);
    v = hsv(:,:,3);
    
    v_eq = adapthisteq(v);
    hsv_eq = hsv;
    hsv_eq(:,:,3) = v_eq;
    
    enhanced_img = hsv2rgb(hsv_eq);
    
    %figure, imshow(img)
    %figure, imshow(enhanced_img);

end

function height = get_height(point_pair, sz, pad)

    [Y,X] = ind2sub(sz, point_pair);
    height = hypot((Y(2) - Y(1)), (X(2) - X(1)));
    height = uint16(height) + pad;
    height = height + uint16(~mod(height,2));  
    
end


function [] = segment_road(img, sat, L, W, folder)
    
    sz = size(img);
    skel = bwmorph(img,'skel',Inf);
    %figure, imshow(skel)
    B = bwmorph(skel, 'branchpoints');
    E = bwmorph(skel, 'endpoints');

    [y,x] = find(E);
    B_loc = find(B);

    Dmask = false(size(skel));
    for k = 1:numel(x)
        D = bwdistgeodesic(skel,x(k),y(k));
        distanceToBranchPt = min(D(B_loc));
        if distanceToBranchPt > 2*L
            continue
        end
        Dmask(D < distanceToBranchPt) = true;
    end
    skelD = skel - Dmask;
    
    %figure, imshow(skelD)
    
    BD = bwmorph(logical(skelD), 'branch');
    [y,x,v] = find(BD);
    branch_mask = ones(sz);
    for k = 1:length(v)
        branch_mask(y(k)-1:y(k)+1, x(k)-1:x(k)+1) = 0;
    end
    disconnected_skel = skelD .* branch_mask;
    CC = bwconncomp(disconnected_skel);
    
    roads_struct = struct();
    num_subsecs = zeros(1, CC.NumObjects);
    
    for sec_idx = 1:CC.NumObjects
        
        new_folder = strcat(folder,'/sec_',num2str(sec_idx));
        mkdir(new_folder);
        
        sec = zeros(sz);
        sec(CC.PixelIdxList{sec_idx}) = 1;
        imwrite(sec, strcat(new_folder,'/sec_skel.png'));
        
        end_points = navigate_skel(sec);
        end_points_pairs = end_points(bsxfun(@plus,(1:2),(0:1:length(end_points)-2)'));
        [num_pairs,~] = size(end_points_pairs);
        
        subsecs = {};
        
        for pair_idx = 1:num_pairs
            
            height = get_height(end_points_pairs(pair_idx,:), sz, 2);
            if height < (L/4)
                continue
            end
            
            num_subsecs(sec_idx) = num_subsecs(sec_idx) + 1;
            subsecs = [subsecs, end_points_pairs(pair_idx,:)];
            
            rotation_angle = get_rotation_angle(end_points_pairs(pair_idx,:), sz);
            center = get_midpoint(end_points_pairs(pair_idx,:), sz);
            
            rpatch = uint8(extractRotatedPatch(sat, double(center), double(W), double(height), rotation_angle));
            rpatch_eq = enhance_contrast(rpatch);
            rpatch_skel = logical(extractRotatedPatch(sec, double(center), double(W), double(height), rotation_angle));
            
            folder_sub_sec = strcat(new_folder,'/sec_',num2str(sec_idx),'_',num2str(num_subsecs(sec_idx)));
            mkdir(folder_sub_sec);
            
            imwrite(rpatch, strcat(folder_sub_sec,'/sat.png'));
            imwrite(rpatch_eq, strcat(folder_sub_sec,'/sat_eq.png'));
            imwrite(rpatch_skel, strcat(folder_sub_sec,'/skel.png'));
            
            
        end
        
        roads_struct.(strcat('sec_',num2str(sec_idx))) = subsecs;
        
    end
    
    roads_struct.num_subsecs = num_subsecs;
    
    save(strcat(folder, '/roads_struct.mat'),'roads_struct');
    
end

end
