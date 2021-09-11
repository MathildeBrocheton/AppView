# AppView
(Matlab R2020b)

AppView files :
AppView is the app used to display the image recorded by the Andor Camera, and sending the binning of these images to Proscan via a DAC (0-5V); in live. AppView was created with AppDesigner, under Matlab R2020b. Both .m and .mlapp are given. 
Andor SDK for Matlab is required : the SDK2 for Matlab, 2.104.30000.0, was used.

uiloadhdf.m file :
Matlab code used to extract the data from the hdf file saved by Proscan after the scanning and image creation.

ImageHDF.m file :
Matlab code to plot the fluorescence images; with a common scale (colorbar limits). 
