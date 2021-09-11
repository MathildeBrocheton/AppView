function hdff = uiloadhdf
import matlab.io.hdf4.*
[file,pathname] = uigetfile('*.hdf');
% open the file in lecture mode, the file is associated to an identifier : sd_id
sd_id = matlab.io.hdf4.sd.start([pathname,file],'read'); 

% data set selection, association with the identifier sds_id
sds_id = matlab.io.hdf4.sd.select(sd_id,0); % 0 corresponds to the first dataset, 1 to the second ...

% get informations from the dataset in this order :
% Name Character          								Array
% Number of dimensions    								Scalar
% Size of each dimension  								Vector
% Data type of the data stored in the array 	        Character array
% Number of attributes associated with the data set  	Scalar

[ds_name, ds_dims] = matlab.io.hdf4.sd.getInfo(sds_id);

% Extraction of the data corresponding to the dataset sds_id
ds_start = zeros(1,2); 
ds_stride = []; 
[hdf_] = matlab.io.hdf4.sd.readData(sds_id,ds_start, ds_dims, ds_stride);

% Dataset and Datafile closure
matlab.io.hdf4.sd.endAccess(sds_id);
matlab.io.hdf4.sd.close(sd_id);

hdff=double(hdf_')+1;