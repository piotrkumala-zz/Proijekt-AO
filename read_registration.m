% clear; clc;

function result_string = read_registration(image)

	% image need to be processed as an array of doubles
	% but imread reads it as uint8\
        plate_detection(image);
	if (isa(image, 'uint8'))
		image = double(image)/255.0;
	end
	
	threshold = 0.5;

    image = rgb2gray(image);
	image = imbinarize(image, threshold);
	result_string = "test";
end
