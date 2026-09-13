%% LEAF IMAGE PROCESSING ASSIGNMENT

clear; 
clc; 
close all

inputFolder = 'C:\Users\DELL\Desktop\GROUP_13_PICKED_LEAVES';
currentDirectory = pwd;
outputFolder = fullfile(currentDirectory,'MATLAB_GROUP_13_Leaf_Results');

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

files = dir(fullfile(inputFolder,'*.jpeg'));
files = files(startsWith(lower({files.name}),'leaf'));

% Sort images by leaf number
numbers = zeros(numel(files),1);
for k = 1:numel(files)
    txt = regexp(files(k).name,'\d+','match','once');
    numbers(k) = str2double(txt);
end
[~,idx] = sort(numbers);
files = files(idx);
numbers = numbers(idx);

% Structure array
LeafData = struct('ID',{},'FileName',{},'OriginalImage',{}, ...
    'GrayImage',{},'EnhancedImage',{},'Mask',{},'ProcessedImage',{}, ...
    'Area_px',{},'Perimeter_px',{},'Centroid_xy',{}, ...
    'BoundingBox_xywh',{},'MajorAxis_px',{},'MinorAxis_px',{}, ...
    'AspectRatio',{},'Eccentricity',{},'Solidity',{}, ...
    'Extent',{},'MeanRGB',{},'MeanHSV',{},'ShapeDescription',{});

for k = 1:numel(files)

    % Read original image
    original = imread(fullfile(files(k).folder,files(k).name));

    % Convert to grayscale and enhance contrast
    gray = rgb2gray(original);
    enhanced = adapthisteq(gray);

    % Segment green leaf from background
    rgb = im2double(original);
    hsvImage = rgb2hsv(rgb);

    R = rgb(:,:,1);
    G = rgb(:,:,2);
    B = rgb(:,:,3);

    excessGreen = 2*G - R - B;

    mask = ((hsvImage(:,:,1) > 0.16 & hsvImage(:,:,1) < 0.52 & ...
             hsvImage(:,:,2) > 0.10) | excessGreen > 0.035);

    % Clean mask
    mask = imopen(mask,strel('disk',3));
    mask = imclose(mask,strel('disk',9));
    mask = imfill(mask,'holes');
    mask = bwareaopen(mask,500);

    % Keep largest object only
    CC = bwconncomp(mask);
    objectSizes = cellfun(@numel,CC.PixelIdxList);

    if isempty(objectSizes)
        warning('Leaf %d was not segmented.',numbers(k));
        continue
    end

    [~,largest] = max(objectSizes);
    finalMask = false(size(mask));
    finalMask(CC.PixelIdxList{largest}) = true;
    finalMask = imfill(finalMask,'holes');

    % Create processed image with white background
    processed = original;
    processed(repmat(~finalMask,1,1,3)) = 255;

    % Extract leaf properties
    properties = regionprops(finalMask,'Area','Perimeter','Centroid', ...
        'BoundingBox','MajorAxisLength','MinorAxisLength', ...
        'Eccentricity','Solidity','Extent');

    s = properties(1);

    % Average colour of leaf pixels only
    rgbPixels = reshape(im2double(original),[],3);
    hsvPixels = reshape(hsvImage,[],3);
    insideLeaf = finalMask(:);

    % Classify basic shape
    aspectRatio = s.MajorAxisLength / s.MinorAxisLength;

    if s.Solidity < 0.80
        description = 'Deeply lobed or compound';
    elseif aspectRatio > 3
        description = 'Long and narrow';
    elseif aspectRatio > 1.65
        description = 'Elliptic or oval';
    else
        description = 'Broad or rounded';
    end

    % Store all details in structural array
    LeafData(k).ID = numbers(k);
    LeafData(k).FileName = files(k).name;
    LeafData(k).OriginalImage = original;
    LeafData(k).GrayImage = gray;
    LeafData(k).EnhancedImage = enhanced;
    LeafData(k).Mask = finalMask;
    LeafData(k).ProcessedImage = processed;

    LeafData(k).Area_px = s.Area;
    LeafData(k).Perimeter_px = s.Perimeter;
    LeafData(k).Centroid_xy = s.Centroid;
    LeafData(k).BoundingBox_xywh = s.BoundingBox;
    LeafData(k).MajorAxis_px = s.MajorAxisLength;
    LeafData(k).MinorAxis_px = s.MinorAxisLength;
    LeafData(k).AspectRatio = aspectRatio;
    LeafData(k).Eccentricity = s.Eccentricity;
    LeafData(k).Solidity = s.Solidity;
    LeafData(k).Extent = s.Extent;
    LeafData(k).MeanRGB = mean(rgbPixels(insideLeaf,:),1);
    LeafData(k).MeanHSV = mean(hsvPixels(insideLeaf,:),1);
    LeafData(k).ShapeDescription = description;

    % Save images
    leafName = sprintf('Leaf_%02d',numbers(k));

    imwrite(original,fullfile(outputFolder,[leafName '_original.jpeg']));
    imwrite(finalMask,fullfile(outputFolder,[leafName '_mask.png']));
    imwrite(enhanced,fullfile(outputFolder,[leafName '_enhanced.png']));
    imwrite(processed,fullfile(outputFolder,[leafName '_processed.png']));

    % Display original, mask and processed result
    figure;
    subplot(1,3,1), imshow(original), title('Original Image')
    subplot(1,3,2), imshow(finalMask), title('Binary Mask')
    subplot(1,3,3), imshow(processed), title('Processed Leaf')
end

% Create summary table
Summary = table([LeafData.ID]', string({LeafData.FileName})', ...
    [LeafData.Area_px]', [LeafData.Perimeter_px]', ...
    [LeafData.MajorAxis_px]', [LeafData.MinorAxis_px]', ...
    [LeafData.AspectRatio]', [LeafData.Eccentricity]', ...
    [LeafData.Solidity]', string({LeafData.ShapeDescription})', ...
    'VariableNames',{'LeafID','FileName','Area_px','Perimeter_px', ...
    'MajorAxis_px','MinorAxis_px','AspectRatio','Eccentricity', ...
    'Solidity','ShapeDescription'});

% Save the structural array and measurements
save(fullfile(outputFolder,'LeafData.mat'),'LeafData','Summary','-v7.3');
writetable(Summary,fullfile(outputFolder,'leaf_measurements.csv'));

disp(Summary)
fprintf('Results saved in: %s\n',outputFolder);