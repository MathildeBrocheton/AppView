RC5R2=uiloadhdf();      % browsing the desired .hdl file        % "R" : round holes
L=size(RC5R2);
I=1;J=L(1);

for i=1:L(1)                                    % to crop the zero-data part of the whole image
    if max(RC5R2(:,i))==1 && RC5R2(1,1) == 1
        I=i;
    end
    if max(RC5R2(:,i))==1 && RC5R2(1,1) ~= 1 && J>i
        J=i-1;
    end
end
if RC5R2(1,1) == 1
    imRC5R2 = zeros(L(1),I);
    for i=1:L(1)
        for j=1:(L(1)-I)
            imRC5R2(i,j) = RC5R2(i,j+I);
        end
    end
end
if RC5R2(1,1) ~= 1
    imRC5R2 = zeros(L(1),J);
    for i=1:L(1)
        for j=1:J
            imRC5R2(i,j) = RC5R2(i,j);
        end
    end
end

%--- color bar settings (load all the following files before plotting)
MAX=max(max([imLC8R4,imC9R2,imC8R8,imC8R7,imC8R4,imC8R21,imC7R987,imC6R876,imC5R432,imC5R21,imC4R6543,imC2R3,imC2R9_8,imC3R43,imC3R76,imC10R4,imC10R87,imLC2R32]));
MIN=min(min([imLC8R4,imC9R2,imC8R8,imC8R7,imC8R4,imC8R21,imC7R987,imC6R876,imC5R432,imC5R21,imC4R6543,imC2R3,imC2R9_8,imC3R43,imC3R76,imC10R4,imC10R87,imLC2R32]));
h=0.35; b=1.4;          % factor applied to the color bar limits
LMAX=max(max([imLC8R4,imLC2R32,imLC4R8]));
LMIN=min(min([imLC8R4,imLC2R32,imLC4R8]));
lh=0.6; lb=1.3;
%---

%--- Profile plot
y=40;       % position of the structures' center
S = size(imRC5R2(:,y));
l_RC5R2=zeros(1,S(1));
for i=1:S(1)
    l_RC5R2(i)= (imRC5R2(i,y-1)+imRC5R2(i,y)+imRC5R2(i,y+1))/3;     % average of 1 pixel from the center
    l_RC5R2(i)= (imRC5R2(i,y-2)+imRC5R2(i,y-1)+imRC5R2(i,y)+imRC5R2(i,y+1)+imRC5R2(i,y+2))/5;       % average of pixel from the center
end
plot(l_RC5R2)
title('1H C5R2')
%---

                %--- EH C2
figure(2)
Max = (max(max(imC2R3))+max(max(imC2R9_8)))/2;
Min = (min(min(imC2R3))+min(min(imC2R9_8)))/2;
subplot(121)
imagesc(imC2R3)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
hold on
scatter(44,100)     % used to found the center position on the plotted image
xlabel('C2R3')

subplot(122)
im=imC2R9_8;
imagesc(im)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C2R9 - C2R8')
                %--- 

                %--- EH C3
figure(3) 
subplot(121)
Max = max(max(imC3R43));
Min = min(min(imC3R43));
imagesc(imC3R43)
colorbar
colormap(hot);
axis image;
caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
hold on
scatter(131,237,'green')
xlabel('C3R4-C3R3')

subplot(122)
Max = max(max(imC3R76));
Min = min(min(imC3R76));
imagesc(imC3R76)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C3R7-C3R6')
                %---

                %--- EH C4
figure(4) 
subplot(122)
Max = max(max(imC4R6543));
Min = min(min(imC4R6543));
imagesc(imC4R6543)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C4R6-C4R5-C4R4-C4R3')

subplot(121)
Max = max(max(imC4R109));
Min = min(min(imC4R109));
imagesc(imC4R109)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C4R10-C4R9')
                %---

                %--- EH C5
figure(5)
Max = (max(max(imC5R21))+max(max(imC5R432)))/2;
Min = (min(min(imC5R21))+min(min(imC5R432)))/2;
subplot(121)
im=imC5R21;
imagesc(im)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.65*Max])
caxis([b*MIN,h*MAX])
xlabel('C5R2-C5R1')

subplot(122)
im=imC5R432;
imagesc(im)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.45*Max])
caxis([b*MIN,h*MAX])
xlabel('C5R4-C5R3-C5R2')
                %---

                %--- EH C6
figure(6)  
Max = max(max(imC6R876));
Min = min(min(imC6R876));
im=imC6R876;
imagesc(im)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C6R8-C6R7-C6R6')
                %---
                
                %--- EH C7
figure(7) 
Max = max(max(imC7R987));
Min = min(min(imC7R987));
im=imC7R987;
imagesc(im)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C7R9-C7R8-C7R7')
                %---
                
                %--- EH C8
figure(8)
Max = (max(max(imC8R21))+max(max(imC8R4))+max(max(imC8R8))+max(max(imC8R7)))/4;
Min = (min(min(imC8R21))+min(min(imC8R4))+min(min(imC8R8))+min(min(imC8R7)))/4;
subplot(141)
im=imC8R21;
imagesc(im)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C8R2-C8R1')

subplot(142)
imagesc(imC8R4)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
% hold on
% scatter(49,150,'green');
xlabel('C8R4')

subplot(143)
im=imC8R7;
imagesc(im)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C8R7')

subplot(144)
im=imC8R8;
imagesc(im)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
xlabel('C8R8')
                 %---
                 
                 %--- EH C9
figure(9)  
Max = max(max(imC9R2));
Min = min(min(imC9R2));
im=imC9R2;
imagesc(im)
colorbar
colormap(hot);
axis image;
caxis([1.3*Min,0.7*Max])
caxis([b*MIN,h*MAX])
% hold on
% scatter(47,150,'green');
xlabel('C9R2')
%                 %---
               
%                 %--- EH C10
figure(10) 
subplot(121)
Max = max(max(imC10R4));
Min = min(min(imC10R4));
imagesc(imC10R4)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.6*Max])
caxis([b*MIN,h*MAX])
xlabel('C10R4')

subplot(122)
Max = max(max(imLC8R4));
Min = min(min(imLC8R4));
imagesc(imLC8R4)
colorbar
colormap(hot);
axis image;
% caxis([1.3*Min,0.6*Max])
caxis([b*MIN,h*MAX])
xlabel('C10R8-C10R7')
                %---
              
                %--- EL C2
figure(13)  
Max = max(max(imLC2R32));
imagesc(imLC2R32)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% caxis([lb*LMIN,lh*LMAX])
xlabel('LC2R3-LC2R2')
                %---        
                
                %--- EL C4
figure(15)  
Max = max(max(imLC4R8));
imagesc(imLC4R8)
colorbar
colormap(hot);
axis image;
% caxis([b*MIN,h*MAX])
caxis([lb*LMIN,lh*LMAX])
xlabel('LC4R8')
                %---
                
                %--- EL C8
figure(19)  
Max = max(max(imLC8R4));
imagesc(imLC8R4)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
xlabel('LC8R4')
                %---
                
                %--- H C1
figure(23)  
Max = max(max(imRC1R9));    % "R" : trous ronds
imagesc(imRC1R9)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
hold on
scatter(44,140,'green')
xlabel('1H C1R9')
                %---
               
                %--- H C2
figure(24)  
subplot(121)
Max = max(max(imRC2R1));
imagesc(imRC2R1)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(34,140,'green')
xlabel('1H C2R1')

subplot(122)
Max = max(max(imRC2R2));
imagesc(imRC2R2)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(40,140,'green')
xlabel('1H C2R2')
                %---
                
                %--- H C3
figure(25)  
Max = max(max(imRC3R3));    % "R" : trous ronds
imagesc(imRC3R3)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
hold on
scatter(29,30,'green')
xlabel('1H C3R3')
                %---
                
                %--- H C4
figure(26)  
subplot(121)
Max = max(max(imRC4R4));
imagesc(imRC4R4)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(43,130,'green')
xlabel('1H C4R4')

subplot(122)
Max = max(max(imRC4R7));
imagesc(imRC4R7)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(46,130,'green')
xlabel('1H C4R7')

                %---
                
                %--- H C5
figure(27)  
subplot(161)
Max = max(max(imRC5R1));
imagesc(imRC5R1)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(41,130,'green')
xlabel('1H C5R1')

imagesc(imRC5R2)
colorbar
colormap(hot);
axis image;
% caxis([b*MIN,h*MAX])
% hold on
% scatter(41,130,'green')
xlabel('1H C5R2')

subplot(162)
Max = max(max(imRC5R3));
imagesc(imRC5R3)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(37,130,'green')
xlabel('1H C5R3')

subplot(163)
Max = max(max(imRC5R5));
imagesc(imRC5R5)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(36,130,'green')
xlabel('1H C5R5')

subplot(164)
Max = max(max(imRC5R7));
imagesc(imRC5R7)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(33,130,'green')
xlabel('1H C5R7')

subplot(165)
Max = max(max(imRC5R9));
imagesc(imRC5R9)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(36,130,'green')
xlabel('1H C5R9')

subplot(166)
Max = max(max(imRC5R11));
imagesc(imRC5R11)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
% hold on
% scatter(48,130,'green')
xlabel('1H C5R11')
                %---
                
                %--- H C8
figure(30)  
Max = max(max(imRC8R3));
imagesc(imRC8R3)
colorbar
colormap(hot);
axis image;
caxis([b*MIN,h*MAX])
hold on
scatter(37,40,'green')
xlabel('1H C8R3')
                %---