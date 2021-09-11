classdef AppView < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        FullPictureButton               matlab.ui.control.Button
        ZoomInButton                    matlab.ui.control.Button
        StateTextAreaLabel              matlab.ui.control.Label
        StateTextArea                   matlab.ui.control.TextArea
        ViewButton                      matlab.ui.control.Button
        ReadyLampLabel                  matlab.ui.control.Label
        ReadyLamp                       matlab.ui.control.Lamp
        ContrastMinMaxSliderLabel       matlab.ui.control.Label
        ContrastMinMaxSlider            matlab.ui.control.Slider
        Slider                          matlab.ui.control.Slider
        AutoContrastCheckBox            matlab.ui.control.CheckBox
        GainSpinnerLabel                matlab.ui.control.Label
        GainSpinner                     matlab.ui.control.Spinner
        ExposureTimeSpinnerLabel        matlab.ui.control.Label
        ExposureTimeSpinner             matlab.ui.control.Spinner
        MarkerButton                    matlab.ui.control.StateButton
        AcquisitionTimesPanel           matlab.ui.container.Panel
        TransferTimeLabel               matlab.ui.control.Label
        sLabel                          matlab.ui.control.Label
        TransferTimePixelsEditFieldLabel  matlab.ui.control.Label
        TransferTimePixelsEditField     matlab.ui.control.NumericEditField
        TransferTimeLineEditFieldLabel  matlab.ui.control.Label
        TransferTimeLineEditField       matlab.ui.control.NumericEditField
        HzEditFieldLabel                matlab.ui.control.Label
        HzEditField                     matlab.ui.control.NumericEditField
        FullImageminEditFieldLabel      matlab.ui.control.Label
        FullImageminEditField           matlab.ui.control.NumericEditField
        ScanningfrequencyHzEditFieldLabel  matlab.ui.control.Label
        ScanningfrequencyHzEditField    matlab.ui.control.NumericEditField
        AcquisitionTimeminEditFieldLabel  matlab.ui.control.Label
        AcquisitionTimeminEditField     matlab.ui.control.NumericEditField
        EnterLabel                      matlab.ui.control.Label
        Label                           matlab.ui.control.Label
    end

    properties (Access = private)
        s = serialport('COM5',9600);
        XPixelsTot=200; YPixelsTot=100; XPixels=100; YPixels=200; im=zeros(200,100);
        A1=1; A2=1, A3=658; A4=496;
        B1=1; B2=1, B3=1; B4=1;     % copy of A
        BB1=1; BB2=1;       % copy of B1,B2
        C1=0; C2=0;         % save sum of A1,A2 for several "zoom in" (A1+A1+A1...) 
        t=1; 
        useSoftwareTrigger = true;
        CMax=3000; CMin=0;CMaxAuto=3000; CMinAuto=0;MaxAuto=3000; MinAuto=0; iMax=3000; iMin=0;CMaxBis=3000; CMinBis=0;
        expo=0.1; gain=3;       % temps exposition et gain
        M = false;              % Marker State
        XMarker = 200; YMarker = 100;
    end
    methods (Access = private)
        function ViewFcn(app)
            h = imagesc(app.im);
            if app.M == true                    %--- Set Marker
                hold on
                scatter(app.XMarker,app.YMarker,'red');
                hold off
            end                                 %---
            if app.useSoftwareTrigger == true
                [ret] = SendSoftwareTrigger();
                CheckWarning(ret);
                [ret] = WaitForAcquisition();
                CheckWarning(ret);
            end
            [ret, imageData] = GetMostRecentImage(app.XPixels * app.YPixels);
            CheckWarning(ret);
            if ret == atmcd.DRV_SUCCESS         % display the acquired image
                app.im=transpose(reshape(imageData, app.XPixels, app.YPixels));
                set(h,'CData',app.im);
                colorbar;
                app.CMaxAuto = max(max(app.im));
                app.CMinAuto = min(min(app.im));
                if app.t==1
                    app.CMaxBis=app.CMaxAuto; app.CMinBis=app.CMinAuto;
                end
                if app.AutoContrastCheckBox.Value == true         % auto contrast set
                    app.CMax = app.CMaxAuto; app.CMin = app.CMinAuto;
                    for i=0:16000
                        if i<app.CMaxAuto
                            app.MaxAuto=i;
                        end
                        if i<app.CMinAuto
                            app.MinAuto=i;
                        end
                    end
                    app.Slider.Value = app.MaxAuto; app.ContrastMinMaxSlider.Value = app.MinAuto;
                    caxis([app.CMinAuto,app.CMaxAuto]);
                elseif app.AutoContrastCheckBox.Value == false && app.CMin < app.CMax     % change contrast with sliders
                    app.CMax = app.Slider.Value; app.CMin = app.ContrastMinMaxSlider.Value;
                    caxis([app.CMin,app.CMax]);
                    app.iMax=app.CMax; app.iMin=app.CMin;
                end
                axis image;
                drawnow;

                % send value to st interface
                outputSingleValue(app.t) = sum(sum(app.im))/(17000*app.XPixels*app.YPixels)*4095;
                write(app.s,outputSingleValue(app.t),'uint16'); % 0-4095   
                app.t = app.t+1;
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            clear all
            close all
        end

        % Button pushed function: ViewButton
        function ViewButtonPushed2(app, event)
            app.ReadyLamp.Enable = 'off'; app.ViewButton.Enable = 'off';
            app.AutoContrastCheckBox.Enable = 'off'; app.AcquisitionTimesPanel.Enable = 'off';
            app.GainSpinner.Enable = 'off'; app.ExposureTimeSpinner.Enable = 'off';
            app.ExposureTimeSpinner.Value = app.expo;
            
            app.StateTextArea.Value = [sprintf('iCam Live Mode');app.StateTextArea.Value];scroll(app.StateTextArea,'top')
            warning off
            delete(instrfindall);       % ouverture carte st sur COM5
            write(app.s,0,'uint16');    % 0-4095 
            installPath ='C:\Users\manip\Documents\MATLAB\cameraAndor';     % init Andor camera
            addpath(installPath)
            path = fullfile(installPath,'Camera Files');
            app.StateTextArea.Value = [sprintf('AndorInitialize --------------');app.StateTextArea.Value]; scroll(app.StateTextArea,'top');pause(0.005);
            [ret] = AbortAcquisition;           %--- si précédent lancement non abouti
            CheckWarning(ret);
            [ret] = SetShutter(1, 2, 1, 1);
            CheckWarning(ret);
            [ret] = AndorShutDown;
            CheckWarning(ret);                  %---
            ret = AndorInitialize(path);
            CheckError(ret);
            app.StateTextArea.Value = [sprintf('Configuring Acquisition');app.StateTextArea.Value]; scroll(app.StateTextArea,'top');pause(0.005);
            [ret]=CoolerON();                             %   Turn on temperature cooler
            CheckWarning(ret);
            [ret]=SetAcquisitionMode(5);                  %   Set acquisition mode; 5 for RTA (Run Till Abort)
            CheckWarning(ret);
            [ret]=SetExposureTime(app.expo);              %   Set exposure time in second
            CheckWarning(ret);
            [ret]=SetEMCCDGain(app.gain);                 %   Set EMCCD Gain (Default, mode 0 : 0-255)
            CheckWarning(ret);
            [ret]=SetReadMode(4);                         %   Set read mode; 4 for Image
            CheckWarning(ret);
            [ret]=SetTriggerMode(10);                     %   Set Software trigger mode
            app.useSoftwareTrigger = true;
            if ret == atmcd.DRV_INVALID_TRIGGER_MODE
                disp('Software trigger not available, using Internal trigger instead')
                SetTriggerMode(0);                        %   Set internal trigger mode
                app.useSoftwareTrigger = false;
            end
            CheckWarning(ret);
            [ret] = SetShutter(1, 1, 0, 0);                 %   Open Shutter
            CheckWarning(ret);
            [ret,app.XPixels, app.YPixels]=GetDetector;           %   Get the CCD size
            CheckWarning(ret);
            [ret] = SetImage(1, 1, 1, app.XPixels, 1, app.YPixels); %   Set the image size
            CheckWarning(ret);
            
            app.StateTextArea.Value = [sprintf('Starting Acquisition');app.StateTextArea.Value];scroll(app.StateTextArea,'top');
            app.XPixelsTot = app.XPixels; app.YPixelsTot = app.YPixels;
            app.A1=1; app.A2=1; app.A3=app.XPixelsTot; app.A4=app.YPixelsTot;
            [ret] = StartAcquisition();                   
            CheckWarning(ret);
            app.im = zeros(app.YPixels,app.XPixels);
            figure('name','LiveCam')
            h = imagesc(app.im);
            axis image;
            colormap(gray);
            if app.useSoftwareTrigger == true
                [ret] = SendSoftwareTrigger();
                CheckWarning(ret);
                [ret] = WaitForAcquisition();
                CheckWarning(ret);
            end
            [ret, imageData] = GetMostRecentImage(app.XPixels * app.YPixels);
            CheckWarning(ret);
            if ret == atmcd.DRV_SUCCESS             %display the acquired image
                app.im = transpose(reshape(imageData, app.XPixels, app.YPixels));
                set(h,'CData',app.im);
                drawnow;
                app.CMaxAuto = max(max(app.im));
                app.CMinAuto = min(min(app.im));
            end
            app.FullPictureButton.Enable = 'on'; app.ReadyLamp.Enable = 'on';
            app.ZoomInButton.Enable = 'on'; 
            app.AutoContrastCheckBox.Enable = 'on'; app.ContrastMinMaxSlider.Enable = 'on'; app.Slider.Enable = 'on'; app.AcquisitionTimesPanel.Enable = 'on';
            app.GainSpinner.Enable = 'on'; app.ExposureTimeSpinner.Enable = 'on';
            app.MarkerButton.Enable = 'on';
            
            while(isempty(get(groot,'CurrentFigure'))==0)       % Show Live Picture : View(XPixels,YPixels)
                if app.t==1
                    tic;
                end
                ViewFcn(app)
                toc;
                app.TransferTimePixelsEditField.Value = round(toc,4);
                Npixels = 256;
                T_ligne = (toc + app.ExposureTimeSpinner.Value)*Npixels;
                app.TransferTimeLineEditField.Value = T_ligne;    app.HzEditField.Value = 1/T_ligne;
                T_tot = T_ligne*Npixels;
                app.FullImageminEditField.Value = (T_tot/60);
                app.AcquisitionTimeminEditField.Value = (1/app.ScanningfrequencyHzEditField.Value)*Npixels/60;
                tic;
            end
            app.ReadyLamp.Enable = 'off';
            app.AutoContrastCheckBox.Enable = 'off'; app.ContrastMinMaxSlider.Enable = 'off'; app.Slider.Enable = 'off';
            app.ZoomInButton.Enable = 'off';
            app.MarkerButton.Enable = 'off';
            app.FullPictureButton.Enable = 'off';pause(0.001);
            write(app.s,0,'uint16');
            app.StateTextArea.Value = [sprintf('---Acquisition Complete! Cleaning Up and Shutting Down---');app.StateTextArea.Value];scroll(app.StateTextArea,'top');
            [ret] = AbortAcquisition;
            CheckWarning(ret);
            [ret] = SetShutter(1, 2, 1, 1);
            CheckWarning(ret);
            [ret] = AndorShutDown;
            CheckWarning(ret);
            app.ReadyLamp.Enable = 'on'; app.ViewButton.Enable = 'on';
        end

        % Button pushed function: FullPictureButton
        function FullPictureButtonPushed(app, event)
            app.ReadyLamp.Enable = 'off';
            h = imagesc(app.im);
            axis image; colorbar;
            [ret]=AbortAcquisition;
            CheckWarning(ret);
            app.XMarker = app.XMarker + app.C1; app.YMarker = app.YMarker + app.C2;
            app.C1 = 0; app.C2 = 0; % reset sum zoom in
            app.A1 = 1; app.A2 = 1; app.A3 = app.XPixelsTot; app.A4 = app.YPixelsTot;
            app.B1 = 1; app.B2 = 1; app.B3 = 1; app.B4 = 1;
            app.BB1 = app.B1; app.BB2 = app.B2;
            app.XPixels = app.XPixelsTot; app.YPixels = app.YPixelsTot;
            [ret] = SetImage(1, 1, 1, app.XPixels, 1, app.YPixels);   % A = (1,1,XPixelsTot,YPixelsTot) / SetImage(1, 1, A(1), A(1)+ floor(A(3))-1, A(2),A(2)+ floor(A(4))-1)
            CheckWarning(ret);
            app.StateTextArea.Value = [sprintf('Full Picture');app.StateTextArea.Value];scroll(app.StateTextArea,'top'); pause(0.005);
            [ret] = StartAcquisition();                   
            CheckWarning(ret);
            app.im = zeros(app.YPixels,app.XPixels);            
            set(h,'CData',app.im);
            axis image
            colorbar
            if app.useSoftwareTrigger == true
                [ret] = SendSoftwareTrigger();
                CheckWarning(ret);
                [ret] = WaitForAcquisition();
                CheckWarning(ret);
            end
            [ret, imageData] = GetMostRecentImage(app.XPixels*app.YPixels);
            CheckWarning(ret);
            if ret == atmcd.DRV_SUCCESS         %display the acquired image
                app.im = transpose(reshape(imageData, app.XPixels, app.YPixels));
            end
            app.ReadyLamp.Enable = 'on';
        end

        % Button pushed function: ZoomInButton
        function ZoomInButtonPushed(app, event)
            app.ReadyLamp.Enable = 'off';
            figure(gcf)
            h = imagesc(app.im);
            if app.M == true                    %--- Set Marker
                hold on
                scatter(app.XMarker,app.YMarker,'red');
                hold off
            end                                 %---
            axis image;colorbar;
            [ret] = AbortAcquisition;
            CheckWarning(ret);
            app.B1 = app.B1+app.A1-1; app.B2 = app.B2+app.A2-1; app.B3 = app.B3+app.A3-1; app.B4 = app.B4+app.A4-1;     % Limite : 10 pixels
            app.BB1 = app.B1; app.BB2 = app.B2;
            A = getrect(gca);
            app.C1 = app.C1+floor(A(1)); app.C2 = app.C2+floor(A(2));
            if A(3)<10 || A(4)<10
                app.StateTextArea.Value = [sprintf('/!\');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
                app.StateTextArea.Value = [sprintf('Size selected too small (< 10x10 pixels)');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
                app.StateTextArea.Value = [sprintf('/!\');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
                app.ReadyLamp.Enable = 'on';
                [ret]=SetImage(1, 1, app.A1, app.A1+ app.XPixels-1, app.A2,app.A2+ app.YPixels-1);
                CheckWarning(ret);
                [ret] = StartAcquisition();                   
                CheckWarning(ret);
                figure(gcf)
                app.im = zeros(app.YPixels,app.XPixels);            
                set(h,'CData',app.im);
                axis image
                colorbar
                app.ReadyLamp.Enable = 'on';
            else
                app.A1 = floor(A(1)); app.A2 = floor(A(2)); app.A3 = floor(A(3)); app.A4 = floor(A(4));
                app.XMarker = app.XMarker - app.A1; app.YMarker = app.YMarker - app.A2;
                app.XPixels = floor(app.A3); app.YPixels = floor(app.A4);
                if ((app.A3+app.A1)> app.XPixelsTot) || app.A1<0 || ((app.A4+app.A2) > app.YPixelsTot) || (app.A2<0)        % si on déborde de l'image initiale
                    if app.A2<0                                                                                             % pas fini
                        app.YPixels = app.A4+app.A2;
                        app.A2=app.B2;
                    end
                    if app.A1<0
                        app.XPixels = app.A3+app.A1;
                        app.A1=app.B1;
                    end
                    if ((floor(app.A3)+floor(app.A1))> app.XPixelsTot)
                        app.XPixels = app.XPixelsTot - app.A1;
                    end
                    if ((app.A4+app.A2) > app.YPixelsTot)
                        app.YPixels = app.YPixelsTot - app.A2;
                    end
                    app.XMarker = app.XMarker - app.A1; app.YMarker = app.YMarker - app.A2;
                end
                [ret]=SetImage(1, 1, app.A1+app.B1, app.A1+app.B1 + app.XPixels-1, app.A2+app.B2, app.A2+app.B2 + app.YPixels-1);
                CheckWarning(ret);
                app.StateTextArea.Value = [sprintf('Zoom In done');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
                [ret] = StartAcquisition();                   
                CheckWarning(ret);
                figure(gcf)
                app.im = zeros(app.YPixels,app.XPixels);            
                set(h,'CData',app.im);
                axis image
                colorbar
                if app.useSoftwareTrigger == true
                    [ret] = SendSoftwareTrigger();
                    CheckWarning(ret);
                    [ret] = WaitForAcquisition();
                    CheckWarning(ret);
                end
                [ret, imageData] = GetMostRecentImage(app.XPixels*app.YPixels);
                CheckWarning(ret);
                if ret == atmcd.DRV_SUCCESS
                    app.im=transpose(reshape(imageData, app.XPixels, app.YPixels));
                end
                app.ReadyLamp.Enable = 'on';
            end
        end

        % Value changed function: ExposureTimeSpinner
        function ExposureTimeSpinnerValueChanged(app, event)
            app.StateTextArea.Value = [sprintf('Exposure Time Changed');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
        end

        % Value changed function: GainSpinner
        function GainSpinnerValueChanged(app, event)
            app.StateTextArea.Value = [sprintf('Gain Value Changed');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
        end

        % Value changed function: AutoContrastCheckBox
        function AutoContrastCheckBoxValueChanged(app, event)
            if app.AutoContrastCheckBox.Value == true
                app.StateTextArea.Value = [sprintf('Contrast Auto On');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
            elseif app.AutoContrastCheckBox.Value == false
                for i=0:16000           % to set the number i on the slider
                    if i<app.CMaxBis
                        app.iMax=i;
                    end
                    if i<app.CMinBis
                        app.iMin=i;
                    end
                end
                app.Slider.Value = app.iMax; app.ContrastMinMaxSlider.Value = app.iMin;
                app.StateTextArea.Value = [sprintf('Contrast Auto Off');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
            end
        end

        % Value changing function: Slider
        function SliderValueChanging(app, event)
            app.Slider.Value = app.iMax; app.ContrastMinMaxSlider.Value = app.iMin;
            if app.AutoContrastCheckBox.Value == false
                app.CMax = event.Value; app.CMaxBis=app.CMax;
            end
        end

        % Value changing function: ContrastMinMaxSlider
        function ContrastMinMaxSliderValueChanging(app, event)
            app.Slider.Value = app.iMax; app.ContrastMinMaxSlider.Value = app.iMin;
            if app.AutoContrastCheckBox.Value == false
                app.CMin = event.Value; app.CMinBis=app.CMin;
            end
        end

        % Value changing function: ExposureTimeSpinner
        function ExposureTimeSpinnerValueChanging(app, event)
            app.expo = event.Value;
            [ret]=SetExposureTime(app.expo);              %   Set exposure time in second
        end

        % Value changing function: GainSpinner
        function GainSpinnerValueChanging(app, event)
            app.gain = event.Value;
            [ret]=SetEMCCDGain(app.gain);                %   Set EMCCD Gain (Default, mode 0 : 0-255)
        end

        % Value changed function: Slider
        function SliderValueChanged(app, event)
            if app.AutoContrastCheckBox.Value == false
                app.StateTextArea.Value = [sprintf('Contrast Changed (Min)');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
            end
        end

        % Value changed function: ContrastMinMaxSlider
        function ContrastMinMaxSliderValueChanged(app, event)
            if app.AutoContrastCheckBox.Value == false
                app.StateTextArea.Value = [sprintf('Contrast Changed (Max)');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
            end
        end

        % Value changed function: MarkerButton
        function MarkerButtonValueChanged(app, event)
            app.ReadyLamp.Enable = 'off';
            app.StateTextArea.Value = [sprintf('Select Marker Position');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
            app.M = app.MarkerButton.Value;
            if app.M==true
                app.ReadyLamp.Enable = 'off';
                h = imagesc(app.im);
                axis image;colorbar;
                [ret] = AbortAcquisition;
                CheckWarning(ret);
                A=getrect(gca);
                app.XMarker=A(1)+app.BB1-1; app.YMarker=A(2)+app.BB2-1;
                [ret]=SetImage(1, 1, app.A1, app.A1+ app.XPixels-1, app.A2,app.A2+ app.YPixels-1);
                CheckWarning(ret);
                app.StateTextArea.Value = [sprintf('Marker Placed');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
                [ret] = StartAcquisition();                   
                CheckWarning(ret);
                figure(gcf)
                app.im = zeros(app.YPixels,app.XPixels);            
                set(h,'CData',app.im);
                axis image
                colorbar
                if app.useSoftwareTrigger == true
                    [ret] = SendSoftwareTrigger();
                    CheckWarning(ret);
                    [ret] = WaitForAcquisition();
                    CheckWarning(ret);
                end
                [ret, imageData] = GetMostRecentImage(app.XPixels * app.YPixels);
                CheckWarning(ret);
                if ret == atmcd.DRV_SUCCESS
                    app.im=transpose(reshape(imageData, app.XPixels, app.YPixels));
                end
                app.ReadyLamp.Enable = 'on';
            else
                app.BB1=1; app.BB2=1;
                app.StateTextArea.Value = [sprintf('Marker Removed');app.StateTextArea.Value];scroll(app.StateTextArea,'top');pause(0.005);
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Color = [0.9412 0.9412 0.9412];
            app.UIFigure.Position = [100 100 315 957];
            app.UIFigure.Name = 'MATLAB App';

            % Create FullPictureButton
            app.FullPictureButton = uibutton(app.UIFigure, 'push');
            app.FullPictureButton.ButtonPushedFcn = createCallbackFcn(app, @FullPictureButtonPushed, true);
            app.FullPictureButton.BackgroundColor = [0.902 0.902 0.902];
            app.FullPictureButton.Enable = 'off';
            app.FullPictureButton.Position = [29 753 100 22];
            app.FullPictureButton.Text = 'Full Picture';

            % Create ZoomInButton
            app.ZoomInButton = uibutton(app.UIFigure, 'push');
            app.ZoomInButton.ButtonPushedFcn = createCallbackFcn(app, @ZoomInButtonPushed, true);
            app.ZoomInButton.BackgroundColor = [0.902 0.902 0.902];
            app.ZoomInButton.Enable = 'off';
            app.ZoomInButton.Position = [30 724 100 22];
            app.ZoomInButton.Text = 'Zoom In';

            % Create StateTextAreaLabel
            app.StateTextAreaLabel = uilabel(app.UIFigure);
            app.StateTextAreaLabel.HorizontalAlignment = 'right';
            app.StateTextAreaLabel.Position = [6 220 34 22];
            app.StateTextAreaLabel.Text = 'State';

            % Create StateTextArea
            app.StateTextArea = uitextarea(app.UIFigure);
            app.StateTextArea.Position = [55 24 248 220];
            app.StateTextArea.Value = {'DAC COM5'};

            % Create ViewButton
            app.ViewButton = uibutton(app.UIFigure, 'push');
            app.ViewButton.ButtonPushedFcn = createCallbackFcn(app, @ViewButtonPushed2, true);
            app.ViewButton.BackgroundColor = [0.902 0.902 0.902];
            app.ViewButton.Position = [23 899 100 22];
            app.ViewButton.Text = 'View';

            % Create ReadyLampLabel
            app.ReadyLampLabel = uilabel(app.UIFigure);
            app.ReadyLampLabel.HorizontalAlignment = 'right';
            app.ReadyLampLabel.Position = [22 920 40 22];
            app.ReadyLampLabel.Text = 'Ready';

            % Create ReadyLamp
            app.ReadyLamp = uilamp(app.UIFigure);
            app.ReadyLamp.Position = [77 926 10 10];
            app.ReadyLamp.Color = [0.3922 0.8314 0.0745];

            % Create ContrastMinMaxSliderLabel
            app.ContrastMinMaxSliderLabel = uilabel(app.UIFigure);
            app.ContrastMinMaxSliderLabel.HorizontalAlignment = 'right';
            app.ContrastMinMaxSliderLabel.Position = [155 921 110 22];
            app.ContrastMinMaxSliderLabel.Text = ' Contrast : Min/Max';

            % Create ContrastMinMaxSlider
            app.ContrastMinMaxSlider = uislider(app.UIFigure);
            app.ContrastMinMaxSlider.Limits = [0 16000];
            app.ContrastMinMaxSlider.MajorTicks = [0 500 1000 1500 2000 2500 3000 3500 4000 4500 5000 5500 6000 6500 7000 7500 8000 8500 9000 9500 10000 10500 11000 11500 12000 12500 13000 13500 14000 14500 15000 15500 16000];
            app.ContrastMinMaxSlider.MajorTickLabels = {'0', '', '1000', '', '2000', '', '3000', '', '4000', '', '5000', '', '6000', '', '7000', '', '8000', '', '9000', '', '1e+04', '', '1.1e+04', '', '1.2e+04', '', '1.3e+04', '', '1.4e+04', '', '1.5e+04', '', '1.6e+04'};
            app.ContrastMinMaxSlider.Orientation = 'vertical';
            app.ContrastMinMaxSlider.ValueChangedFcn = createCallbackFcn(app, @ContrastMinMaxSliderValueChanged, true);
            app.ContrastMinMaxSlider.ValueChangingFcn = createCallbackFcn(app, @ContrastMinMaxSliderValueChanging, true);
            app.ContrastMinMaxSlider.Enable = 'off';
            app.ContrastMinMaxSlider.Position = [159 261 3 647];

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.Limits = [0 16000];
            app.Slider.MajorTicks = [0 500 1000 1500 2000 2500 3000 3500 4000 4500 5000 5500 6000 6500 7000 7500 8000 8500 9000 9500 10000 10500 11000 11500 12000 12500 13000 13500 14000 14500 15000 15500 16000];
            app.Slider.MajorTickLabels = {'0', '', '1000', '', '2000', '', '3000', '', '4000', '', '5000', '', '6000', '', '7000', '', '8000', '', '9000', '', '1e+04', '', '1.1e+04', '', '1.2e+04', '', '1.3e+04', '', '1.4e+04', '', '1.5e+04', '', '1.6e+04'};
            app.Slider.Orientation = 'vertical';
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
            app.Slider.ValueChangingFcn = createCallbackFcn(app, @SliderValueChanging, true);
            app.Slider.Enable = 'off';
            app.Slider.Position = [242 261 3 647];
            app.Slider.Value = 4000;

            % Create AutoContrastCheckBox
            app.AutoContrastCheckBox = uicheckbox(app.UIFigure);
            app.AutoContrastCheckBox.ValueChangedFcn = createCallbackFcn(app, @AutoContrastCheckBoxValueChanged, true);
            app.AutoContrastCheckBox.Enable = 'off';
            app.AutoContrastCheckBox.Text = 'Auto Contrast';
            app.AutoContrastCheckBox.Position = [44 254 95 22];
            app.AutoContrastCheckBox.Value = true;

            % Create GainSpinnerLabel
            app.GainSpinnerLabel = uilabel(app.UIFigure);
            app.GainSpinnerLabel.HorizontalAlignment = 'right';
            app.GainSpinnerLabel.Position = [25 849 31 22];
            app.GainSpinnerLabel.Text = 'Gain';

            % Create GainSpinner
            app.GainSpinner = uispinner(app.UIFigure);
            app.GainSpinner.ValueChangingFcn = createCallbackFcn(app, @GainSpinnerValueChanging, true);
            app.GainSpinner.Limits = [0 255];
            app.GainSpinner.ValueChangedFcn = createCallbackFcn(app, @GainSpinnerValueChanged, true);
            app.GainSpinner.Position = [76 849 56 22];
            app.GainSpinner.Value = 3;

            % Create ExposureTimeSpinnerLabel
            app.ExposureTimeSpinnerLabel = uilabel(app.UIFigure);
            app.ExposureTimeSpinnerLabel.HorizontalAlignment = 'right';
            app.ExposureTimeSpinnerLabel.Position = [28 821 86 22];
            app.ExposureTimeSpinnerLabel.Text = 'Exposure Time';

            % Create ExposureTimeSpinner
            app.ExposureTimeSpinner = uispinner(app.UIFigure);
            app.ExposureTimeSpinner.Step = 0.005;
            app.ExposureTimeSpinner.ValueChangingFcn = createCallbackFcn(app, @ExposureTimeSpinnerValueChanging, true);
            app.ExposureTimeSpinner.Limits = [0 10];
            app.ExposureTimeSpinner.ValueChangedFcn = createCallbackFcn(app, @ExposureTimeSpinnerValueChanged, true);
            app.ExposureTimeSpinner.Position = [65 800 65 22];
            app.ExposureTimeSpinner.Value = 0.1;

            % Create MarkerButton
            app.MarkerButton = uibutton(app.UIFigure, 'state');
            app.MarkerButton.ValueChangedFcn = createCallbackFcn(app, @MarkerButtonValueChanged, true);
            app.MarkerButton.Enable = 'off';
            app.MarkerButton.Text = 'Marker';
            app.MarkerButton.BackgroundColor = [0.902 0.902 0.902];
            app.MarkerButton.Position = [31 682 100 22];

            % Create AcquisitionTimesPanel
            app.AcquisitionTimesPanel = uipanel(app.UIFigure);
            app.AcquisitionTimesPanel.AutoResizeChildren = 'off';
            app.AcquisitionTimesPanel.Enable = 'off';
            app.AcquisitionTimesPanel.Title = 'Acquisition Times';
            app.AcquisitionTimesPanel.Position = [6 306 149 353];

            % Create TransferTimeLabel
            app.TransferTimeLabel = uilabel(app.AcquisitionTimesPanel);
            app.TransferTimeLabel.Position = [12 211 86 22];
            app.TransferTimeLabel.Text = 'Transfer Time /';

            % Create sLabel
            app.sLabel = uilabel(app.AcquisitionTimesPanel);
            app.sLabel.Position = [4 234 25 22];
            app.sLabel.Text = '(s)';

            % Create TransferTimePixelsEditFieldLabel
            app.TransferTimePixelsEditFieldLabel = uilabel(app.AcquisitionTimesPanel);
            app.TransferTimePixelsEditFieldLabel.HorizontalAlignment = 'right';
            app.TransferTimePixelsEditFieldLabel.Position = [6 301 133 22];
            app.TransferTimePixelsEditFieldLabel.Text = 'Transfer Time / Pixel (s)';

            % Create TransferTimePixelsEditField
            app.TransferTimePixelsEditField = uieditfield(app.AcquisitionTimesPanel, 'numeric');
            app.TransferTimePixelsEditField.Editable = 'off';
            app.TransferTimePixelsEditField.Position = [39 280 100 22];

            % Create TransferTimeLineEditFieldLabel
            app.TransferTimeLineEditFieldLabel = uilabel(app.AcquisitionTimesPanel);
            app.TransferTimeLineEditFieldLabel.HorizontalAlignment = 'right';
            app.TransferTimeLineEditFieldLabel.Position = [28 255 112 22];
            app.TransferTimeLineEditFieldLabel.Text = 'Transfer Time / Line';

            % Create TransferTimeLineEditField
            app.TransferTimeLineEditField = uieditfield(app.AcquisitionTimesPanel, 'numeric');
            app.TransferTimeLineEditField.Editable = 'off';
            app.TransferTimeLineEditField.Position = [21 234 45 22];

            % Create HzEditFieldLabel
            app.HzEditFieldLabel = uilabel(app.AcquisitionTimesPanel);
            app.HzEditFieldLabel.HorizontalAlignment = 'right';
            app.HzEditFieldLabel.Position = [70 234 27 22];
            app.HzEditFieldLabel.Text = '(Hz)';

            % Create HzEditField
            app.HzEditField = uieditfield(app.AcquisitionTimesPanel, 'numeric');
            app.HzEditField.Editable = 'off';
            app.HzEditField.Position = [100 234 43 22];

            % Create FullImageminEditFieldLabel
            app.FullImageminEditFieldLabel = uilabel(app.AcquisitionTimesPanel);
            app.FullImageminEditFieldLabel.HorizontalAlignment = 'right';
            app.FullImageminEditFieldLabel.Position = [50 198 92 22];
            app.FullImageminEditFieldLabel.Text = 'Full Image (min)';

            % Create FullImageminEditField
            app.FullImageminEditField = uieditfield(app.AcquisitionTimesPanel, 'numeric');
            app.FullImageminEditField.Editable = 'off';
            app.FullImageminEditField.Position = [43 177 100 22];

            % Create ScanningfrequencyHzEditFieldLabel
            app.ScanningfrequencyHzEditFieldLabel = uilabel(app.AcquisitionTimesPanel);
            app.ScanningfrequencyHzEditFieldLabel.HorizontalAlignment = 'right';
            app.ScanningfrequencyHzEditFieldLabel.Position = [4 116 138 22];
            app.ScanningfrequencyHzEditFieldLabel.Text = 'Scanning frequency (Hz)';

            % Create ScanningfrequencyHzEditField
            app.ScanningfrequencyHzEditField = uieditfield(app.AcquisitionTimesPanel, 'numeric');
            app.ScanningfrequencyHzEditField.Position = [39 95 100 22];

            % Create AcquisitionTimeminEditFieldLabel
            app.AcquisitionTimeminEditFieldLabel = uilabel(app.AcquisitionTimesPanel);
            app.AcquisitionTimeminEditFieldLabel.HorizontalAlignment = 'right';
            app.AcquisitionTimeminEditFieldLabel.Position = [-13 74 152 22];
            app.AcquisitionTimeminEditFieldLabel.Text = 'Acquisition Time (min)';

            % Create AcquisitionTimeminEditField
            app.AcquisitionTimeminEditField = uieditfield(app.AcquisitionTimesPanel, 'numeric');
            app.AcquisitionTimeminEditField.Editable = 'off';
            app.AcquisitionTimeminEditField.Position = [39 53 100 22];

            % Create EnterLabel
            app.EnterLabel = uilabel(app.AcquisitionTimesPanel);
            app.EnterLabel.Position = [10 128 34 22];
            app.EnterLabel.Text = 'Enter';

            % Create Label
            app.Label = uilabel(app.AcquisitionTimesPanel);
            app.Label.Position = [4 74 25 22];
            app.Label.Text = '=>';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = AppView

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end