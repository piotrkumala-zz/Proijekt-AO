function plate_detection(im)
%Wczytujemy obraz z ktorego ma zostac wykryta tablica
carImg = im;
%Konwersja na skale szaro�ci
carGray = rgb2gray(carImg);
[rows , cols] = size(carGray);
%Operacja otwarcia na obrazie
se = strel('disk',3);
carGray = imopen(carGray,se);
%imshow(carGray);
%figure(1);

difference = 0;
sum = 0;
total_sum = 0;
difference = uint32(difference);
%Wykrywanie kraw�dzi poziomych
max_horizontal = 0;
maximum = 0;
horizontal(cols-1) = zeros();
for i = 2:cols
    sum = 0;
    for j = 2:rows
        if(carGray(j,i) > carGray(j-1,i))
            difference = uint32(carGray(j,i) - carGray(j-1,i));
        else
            difference = uint32(carGray(j-1,i) - carGray(j,i));
        end
        %Tutaj pozmieniac wartosc i zobaczyc jak bedzie najlepiej
        if(difference > 20)
            sum = sum + difference;
        end
    end
    horizontal(i) = sum;
    %Szukamy najwy�szej wartosci
    if(sum > maximum)
        max_horizontal = i;
        maximum = sum;
    end
    total_sum = total_sum + sum;
end
avg = total_sum / cols;
%histogram dla poziomych
%figure(2);
%plot(horizontal);
%Stosujemy filtr dolnoprzepustowy �eby wyg�adzi� histogram
sum = 0;
horizontal_lowpass = horizontal;
for i = 21:(cols-21)
    sum=0;
    for j = (i-20):(i+20)
        sum = sum + horizontal(j);
    end
    horizontal_lowpass(i) = sum /41;
end
%histogram po filtrze dolnoprzepustowym
%figure(3);
%plot(horizontal_lowpass);
%dynamic tresholding
for i = 1:cols
    if(horizontal_lowpass(i) < avg)
        horizontal_lowpass(i) = 0;
        for j = 1:rows
            carGray(j,i) =0;
        end
    end
end
%figure(4);
%plot(horizontal_lowpass);
%wykrywanie kraw�dzi pionowych
difference = 0;
total_sum = 0;
difference = uint32(difference);
maximum = 0;
max_vertical = 0;
vertical(rows-1) = zeros();
for i = 2:rows
    sum=0;
    for j=2:cols
        if(carGray(i,j) > carGray(i,j-1))
            difference = uint32(carGray(i,j) - carGray(i,j-1));
        end
        if(carGray(i,j) <= carGray(i,j-1))
            difference = uint32(carGray(i,j-1) - carGray(i,j));
        end
        if(difference > 20)
            sum = sum + difference;
        end
    end
    vertical(i)=sum;
    %Szukamy najwy�szej warto�ci
    if(sum > maximum)
        max_vertical = i;
        maximum = sum;
    end
    total_sum = total_sum + sum;
end
avg = total_sum / rows;
%histogram dla pionowych krawedzi
%figure(5);
%plot(vertical);
%znowu uzywamy filtru dolnoprzepustowego
sum = 0;
vertical_lowpass = vertical;
for i = 21:(rows-21)
    sum=0;
    for j = (i-20):(i+20)
        sum = sum + vertical(j);
    end
    vertical_lowpass(i) = sum / 41;
end
%dynamic tresholding
for i = 1:rows
    if(vertical_lowpass(i) < avg)
        vertical_lowpass(i) = 0;
        for j = 1:cols
            carGray(i,j)=0;
        end
    end
end
%figure(6);
%imshow(carGray);
%Szukamy mo�liwych obszar�w dla naszej tablicy rejestracyjnej
j = 1;
for i = 2:cols-2
    if(horizontal_lowpass(i) ~= 0 && horizontal_lowpass(i-1) == 0 && horizontal_lowpass(i+1) == 0) 
        column(j) = i;
        column(j+1) = i;
        j = j + 2;
    elseif(horizontal_lowpass(i) ~= 0 && horizontal_lowpass(i-1) == 0) || (horizontal_lowpass(i) ~= 0 && horizontal_lowpass(i+1) == 0)
        column(j)=i;
        j=j+1;
    end
end
j = 1;
for i = 2:rows-2
    if(vertical_lowpass(i) ~= 0 && vertical_lowpass(i-1) == 0 && vertical_lowpass(i+1) == 0) 
        row(j) = i;
        row(j+1) = i;
        j = j + 2;
    elseif(vertical_lowpass(i) ~= 0 && vertical_lowpass(i-1) == 0) || (vertical_lowpass(i) ~= 0 && vertical_lowpass(i+1) == 0)
        row(j)=i;
        j=j+1;
    end
end
[tmp, col_size] = size(column);
if(mod(col_size,2))
    column(col_size+1) = cols;
end
[tmp , row_size] = size(row);
if(mod(row_size,2))
    row(row_size+1) = rows;
end
for i = 1:2:row_size
    for j = 1:2:col_size
        if(~((max_horizontal >= column(j) && max_horizontal <= column(j+1)) && (max_vertical >=row(i) && max_vertical <= row(i+1))))
            for m = row(i):row(i+1)
                for n = column(j):column(j+1)
                    carGray(m,n) = 0;
                end
            end
        end
    end
end
%figure(6);
%imshow(carGray);

%wycinamy rejestracje tu cos nie dziala do konca :D 
for i = 1:rows
    for j = 1:cols
        if( carGray(i,j) > 0)
            x=i;
            y=j;
            break
        end
    end
end
rowCropped = find(any(carGray,1));
columnCropped = find(any(carGray,2));
rowCropped = size(rowCropped);
columnCropped = size(columnCropped);
size_rowCropped=rowCropped(2);
size_columnCropped = columnCropped(1);
croppedImage = imcrop(carGray,[size_rowCropped, x-size_columnCropped, y, size_columnCropped]);
figure(9), imshow(croppedImage);

format long g;
format compact;
fontSize = 20;

%template matching do rejestracji i tutaj jakis kodzik z neta jest mozna
%cos pokminic z nim
rejestracja = croppedImage;
% Get the dimensions of the image.  numberOfColorBands should be = 3.
[plate_rows, plate_columns, numberOfColorBands] = size(rejestracja);
% Display the original color image.
subplot(2, 2, 1);
imshow(rejestracja, []);
axis on;
caption = sprintf('Original Color Image, %d rows by %d columns.', plate_rows, plate_columns);
title(caption, 'FontSize', fontSize);
% Enlarge figure to full screen.
set(gcf, 'units','normalized','outerposition',[0, 0, 1, 1]);

% Let's get our template by extracting a small portion of the original image.
templateWidth = 43;
templateHeight = 65;
smallimg = imread('templates/N.png');
smallimg = imresize(smallimg,0.55);
smallSubImage = smallimg;
% Get the dimensions of the image.  numberOfColorBands should be = 3.
[plate_rows, plate_columns, numberOfColorBands] = size(smallSubImage);
subplot(2, 2, 2);
imshow(smallSubImage, []);
axis on;
caption = sprintf('Template Image to Search For, %d rows by %d columns.', plate_rows, plate_columns);
title(caption, 'FontSize', fontSize);

% Ask user which channel (red, green, or blue) to search for a match.
% channelToCorrelate = menu('Correlate which color channel?', 'Red', 'Green', 'Blue');
% It actually finds the same location no matter what channel you pick, 
% for this image anyway, so let's just go with red (channel #1).
% Note: If you want, you can get the template from every color channel and search for it in every color channel,
% then take the average of the found locations to get the overall best location.
channelToCorrelate = 1;  % Use the red channel.
correlationOutput = normxcorr2(smallSubImage(:,:,1), rejestracja(:,:, channelToCorrelate));
subplot(2, 2, 3);
imshow(correlationOutput, []);
axis on;
% Get the dimensions of the image.  numberOfColorBands should be = 1.
[plate_rows, plate_columns, numberOfColorBands] = size(correlationOutput);
caption = sprintf('Normalized Cross Correlation Output, %d rows by %d columns.', plate_rows, plate_columns);
title(caption, 'FontSize', fontSize);

% Find out where the normalized cross correlation image is brightest.
[maxCorrValue, maxIndex] = max(abs(correlationOutput(:)));
[yPeak, xPeak] = ind2sub(size(correlationOutput),maxIndex(1))
% Because cross correlation increases the size of the image, 
% we need to shift back to find out where it would be in the original image.
corr_offset = [(xPeak-size(smallSubImage,2)) (yPeak-size(smallSubImage,1))]

% Plot it over the original image.
subplot(2, 2, 4); % Re-display image in lower right.
imshow(rejestracja);
axis on; % Show tick marks giving pixels
hold on; % Don't allow rectangle to blow away image.
% Calculate the rectangle for the template box.  Rect = [xLeft, yTop, widthInColumns, heightInRows]
boxRect = [corr_offset(1) corr_offset(2) templateWidth, templateHeight]
% Plot the box over the image.
rectangle('position', boxRect, 'edgecolor', 'g', 'linewidth',2);
% Give a caption above the image.
title('Template Image Found in Original Image', 'FontSize', fontSize);
uiwait(helpdlg('Done with demo!'));

end