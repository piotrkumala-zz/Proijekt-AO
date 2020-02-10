function result_string =plate_detection(im)
%Wczytujemy obraz z ktorego ma zostac wykryta tablica
%dziala dobrze rejestracja5,6,7
carImg = im;
carImg = imresize(carImg,0.5);
%Konwersja na skale szaro�ci
carGray = rgb2gray(carImg);
[rows , cols] = size(carGray);

% Convert Image to binary Image
% Remove all the objects containing less than 20 pixels
%imshow(carGray);


% 
% %Operacja otwarcia na obrazie
se = strel('disk',4);
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
        if(difference > 40)
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
% figure(2);
% plot(horizontal);
%Stosujemy filtr dolnoprzepustowy �eby wyg�adzi� histogram
sum = 0;
horizontal_lowpass = horizontal;
for i = 41:(cols-41)
    sum=0;
    for j = (i-40):(i+40)
        sum = sum + horizontal(j);
    end
    horizontal_lowpass(i) = sum /81;
end
%histogram po filtrze dolnoprzepustowym
% figure(3);
% plot(horizontal_lowpass);
%dynamic tresholding
for i = 1:cols
    if(horizontal_lowpass(i) < avg)
        horizontal_lowpass(i) = 0;
        for j = 1:rows
            carGray(j,i) =0;
        end
    end
end
% figure(4);
% plot(horizontal_lowpass);
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
% figure(5);
% plot(vertical);
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
% figure(6);
% imshow(carGray);
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
% figure(6);
% imshow(carGray);

%wycinanie rejestracji
se = strel('disk',10);
imageToCrop = carGray;
imageToCrop = imbinarize(imageToCrop);
imageToCrop = imclose(imageToCrop,se);
Iprops=regionprops(imageToCrop,'BoundingBox','Area', 'Image');
info = regionprops(imageToCrop,'Boundingbox','Area', 'Image') ;
maximumArea = 0;
rectangleBox = [0, 0, 0, 0];
for k = 1 : length(Iprops)
     BB = info(k).Area;
     BP = info(k).BoundingBox;
     if maximumArea < BB
         maximumArea = BB;
         rectangleBox =[BP(1),BP(2),BP(3),BP(4)];
     end
end
croppedImage = imcrop(carGray,rectangleBox);


%template matching

test = croppedImage;
test = ~imbinarize(test);
[h, w] = size(test);

% imshow(test);

Iprops=regionprops(test,'BoundingBox','Area', 'Image'); %Szukamy boundingboxow dla znakow rejestracji
count = numel(Iprops);

img2 = test;
info = regionprops(img2,'Boundingbox','Area', 'Image') ;

%Bounding boxy (mniejsze niz np 1/7 szerokosci i wieksze niz 1/2 albo 1/3 wysokosci)
%zeby lapalo tylko znaki a nie reszte
%wybrane bounding boxy przyrownujemy do naszych szablonow
% imshow(img2)
% hold on
for k = 1 : length(info)
     BB = info(k).BoundingBox;
%      rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','r','LineWidth',2);
end


letters = "";
for i=1:count
   ow = length(Iprops(i).Image(1,:));
   oh = length(Iprops(i).Image(:,1));
   if ow<(w/7) && oh>(h/3)
       letters = letters + (Letter_detection(Iprops(i).Image));
   end
end
    if letters == ""
        letters = "Błąd odczytu";
    end      
	result_string = letters;
end