function Syn(d_pwd,d_diff,d_ref,d_lrr,d_lrra,n1,n2,n3,dt,lf,hf,N,N2,NN,n1win,n2win,n3win,r1,r2,r3,ifdamp,verb)
% Author      : Yangkang Chen
% Date        : March, 2020

% Requirements: RSF (http://rsf.sourceforge.net/) with Matlab API

%  Copyright (C) 2020 Zhejiang University
%  Copyright (C) 2020 Yangkang Chen
%  Modified by YC on Jan 24, 2021
% 
%  This program is free software; you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation; either version 2 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program; if not, write to the Free Software
%  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
%
%  REFERENCES
%  Wang et al., 2020, Separation and imaging of seismic diffractions using a localized rank-reduction method with adaptively selected ranks, 85, V497–V506.
%  Chen et al., 2019, Obtaining free USArray data by multi-dimensional seismic reconstruction, Nature Communications, 10:4434.
%  Bai et al., 2020, Seismic signal enhancement based on the lowrank methods, Geophysical Prospecting, 68, 2783-2807.
%  Chen et al., 2020, Five-dimensional seismic data reconstruction using the optimally damped rank-reduction method, Geophysical Journal International, 222, 1824-1845.
%  Chen, Y., W. Huang, D. Zhang, W. Chen, 2016, An open-source matlab code package for improved rank-reduction 3D seismic data denoising and reconstruction, Computers & Geosciences, 95, 59-66.
%  Chen, Y., D. Zhang, Z. Jin, X. Chen, S. Zu, W. Huang, and S. Gan, 2016, Simultaneous denoising and reconstruction of 5D seismic data via damped rank-reduction method, Geophysical Journal International, 206, 1695-1717.
%  Huang, W., R. Wang, Y. Chen, H. Li, and S. Gan, 2016, Damped multichannel singular spectrum analysis for 3D random noise attenuation, Geophysics, 81, V261-V270.
%  Chen et al., 2017, Preserving the discontinuities in least-squares reverse time migration of simultaneous-source data, Geophysics, 82, S185-S196.
% 

%%from Madagascar to Matlab
dpwd=zeros(n1,n2*n3);
rsf_read(dpwd,d_pwd)
dpwd=reshape(dpwd,n1,n2,n3);

dd=zeros(n1,n2*n3);
rsf_read(dd,d_diff)
dd=reshape(dd,n1,n2,n3);

dr=zeros(n1,n2*n3);
rsf_read(dr,d_ref)
dr=reshape(dr,n1,n2,n3);

d=dd+dr;

%%% Main program goes here !
tic
if ~ifdamp
    %% LRR
    d1=fxymssa_win(d,lf,hf,dt,N2,verb,n1win,n2win,n3win,r1,r2,r3);
    %% LDRR
    d2=fxymssa_win_auto2(d,lf,hf,dt,N,N2,verb,n1win,n2win,n3win,r1,r2,r3,2);
    
    d1=reshape(d1,n1,n2,n3);
    d2=reshape(d2,n1,n2,n3);
else
    %% LRRA
    d3=fxydmssa_win(d,lf,hf,dt,N,NN,verb,n1win,n2win,n3win,r1,r2,r3);
    %% LDRRA
    d4=fxydmssa_win_auto2(d,lf,hf,dt,N,N2,NN,verb,n1win,n2win,n3win,r1,r2,r3,2);

    d3=reshape(d3,n1,n2,n3);
    d4=reshape(d4,n1,n2,n3);
end
toc
if ~ifdamp
fprintf('Input: SNR=%g\n',yc_snr(dd(:),d(:)));
fprintf('PWD: SNR=%g\n',yc_snr(dd(:),dpwd(:)));
fprintf('LRR: SNR=%g\n',yc_snr(dd(:),d(:)-d1(:)));
fprintf('LRRA: SNR=%g\n',yc_snr(dd(:),d(:)-d2(:)));
else
fprintf('Input: SNR=%g\n',yc_snr(dd(:),d(:)));
fprintf('PWD: SNR=%g\n',yc_snr(dd(:),dpwd(:)));
fprintf('LRR: SNR=%g\n',yc_snr(dd(:),d(:)-d3(:)));
fprintf('LRRA: SNR=%g\n',yc_snr(dd(:),d(:)-d4(:)));
end



%% from Matlab to Madagascar
if ~ifdamp
    rsf_create(d_lrr,size(d1)');
    rsf_write(d1,d_lrr);
    
    rsf_create(d_lrra,size(d2)');
    rsf_write(d2,d_lrra);
else
    rsf_create(d_lrr,size(d3)');
    rsf_write(d3,d_lrr);
    
    rsf_create(d_lrra,size(d4)');
    rsf_write(d4,d_lrra);
end

return

