function [ RawFitResults ] = fitBoxCenters(data,boxCenters,fitParams)
% FIT    populate RawFitResults property
%
% DESCRIPTION:
%   localize single molecules using parameters specified in ParamsFit 
%   property. Regions of interest (ROIs) are either input by user or
%   determined by using boxCenters property and makeROIStack.
%
% EXAMPLE:
%   obj.fit; %load and perform on data
%   obj.fit(ROIStack,XRoiStart,YRoiStart,Frame); %perform on user specified data
%
% Inputs
%   ROIStack: (single array) 3-D image (x,y,roi) of stacked of ROIs
%       dimensions are [obj.ParamsFit.BoxSize obj.ParamsFit.BoxSize nROIs]
%       where nROIs is the number of ROIs
%   XRoiStart: (nROIs by 1) starting x position for all ROIs
%   YRoiStart: (nROIs by 1) starting y position for all ROIs
%   Frame: (nROIs by 1) time frame for all ROIs
%
%
% Populates RawFitResults with the following fields:
%   XRoiStart: (nROIs by 2) starting position for all ROIs [XRoiStart YRoiStart]
%   Coord: (nROIs by 2) estimated positions for each ROI [x y]
%   Photons: (nROIs by 1) estimated photons/frame
%   Bg: (nROIs by 1) estimated background
%   Sigma: (nROIs by 1) estimated PSF sigma
%   Frame: (nROIS by 1) frame number (zero based)
%   CRLB_STD: (nROIS by 2) Cramer Rao Lower Bound for Coord
%   Photons_STD: (nROIS by 1) Cramer Rao Lower Bound for Photons
%   Bg_STD: (nROIS by 1) Cramer Rao Lower Bound for Bg
%   Sigma_STD: (nROIS by 1) Cramer Rao Lower Bound for Sigma
%   LL: (nROIS by 1) Log Likelihood for fit
%
% DEPENDENCIES:
%   gaussmlev3
%
%
% gpuGaussMLEv3 Carlas Smith 2014 (UMASS/TU-DELFT)

%% Extract subregions for fits
Frame = boxCenters(:,3);

[ROIStack, XRoiStart, YRoiStart] = cMakeSubregions(boxCenters(:,1),boxCenters(:,2),boxCenters(:,3),fitParams.BoxSize,single(permute(data,[2 1 3])));
XRoiStart = single(XRoiStart);
YRoiStart = single(YRoiStart);

[P, C, LL] = gpuGaussMLEv3(ROIStack,single(fitParams.PSFSigma),fitParams.Iterations,1,true ); 
P=P';
C=C';

if fitParams.FitSigma
    [P1, C1, ~] = gpuGaussMLEv3(ROIStack,single(fitParams.PSFSigma),fitParams.Iterations,4,true); 

    %replace sigma info with fit results from fitType 2
    P1=P1';    
    C1=C1';
    P(:,5:6) = P1(:,5:6);
    C(:,5:6) = C1(:,5:6);
end

%% Populate RawFitResults
significance_default = 0.05;

%ROI starting positions
RawFitResults.RoiStart = [XRoiStart YRoiStart];
RawFitResults.ROIStack = ROIStack;
%estimted parameters
RawFitResults.Coord(:,1)=double(P(:,1))+double(XRoiStart);
RawFitResults.Coord(:,2)=double(P(:,2))+double(YRoiStart);

RawFitResults.Photons=double(P(:,3));
RawFitResults.Bg=double(P(:,4));
if size(P,2) >= 6
    RawFitResults.Sigma=double(P(:,5:6));
else
    RawFitResults.Sigma=fitParams.PSFSigma.*ones(size(P,1),1); 
end
if size(C,2) >= 6
	RawFitResults.Sigma_STD=double(C(:,5:6));
else
	RawFitResults.Sigma_STD=zeros(size(P,1),1);
end
RawFitResults.Frame=Frame;
%CRB for parameters
RawFitResults.CRLB_STD(:,1)=double(C(:,1));
RawFitResults.CRLB_STD(:,2)=double(C(:,2));
RawFitResults.Photons_STD=double(C(:,3));
RawFitResults.Bg_STD=double(C(:,4));

[ ~,~,pfa_adj ]=fdr_bh(reshape(double(LL(3,:)),[prod(size(LL(3,:))) 1]),significance_default,'dep','no');

RawFitResults.PFA = min(pfa_adj,1);
RawFitResults.LL=double(LL);
