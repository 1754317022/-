function synth_operators(clean,rrdamping,rrstma,rrdampingst,rrdampingma,rrdampingstma)
% Author      : Oboue et al. 2020
%               Zhejiang University
% 
% Date        : January, 2021
% Requirements: RSF (http://rsf.sourceforge.net/) with Matlab API
%    
%  Copyright (C) 2020 Zhejiang University
%  Copyright (C) Oboue et al. 2020
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

%% load data
load ob_synth5d.mat
d=synth5d;d=d/max(max(max(max(max(d)))));
[nt,nhx,nhy,nx,ny]=size(d);

%% simultaneous denoising and reconstruction
randn('state',201314);
var=0.3;
dn=d+var*randn(size(d));

%% decimate
[nt,nhx,nhy,nx,ny]=size(d);
ratio=0.3;
mask=yc_genmask(reshape(d,nt,nhx*nhy*nx*ny),ratio,'c',201415);
mask=reshape(mask,nt,nhx,nhy,nx,ny);
d0=dn.*mask;

% RR+DAMPING
flow=0;fhigh=100;dt=0.004;N=6;NN=2;Niter=10;mode=1;verb=1;iflb=0; 
a=(Niter-(1:Niter))/(Niter-1);
d1=drr5d_lb_recon(d0,mask,flow,fhigh,dt,N,NN,Niter,eps,verb,mode,iflb,a);

% RR+ST+MA
K=30; e=0.964; ws=1;
d2=rr_st_ma5d_lb_recon(d0,mask,flow,fhigh,dt,N,Niter,eps,verb,mode,a,K,e,ws);

% RR+DAMPING+ST
K=0;
d3=drr_st5d_lb_recon(d0,mask,flow,fhigh,dt,N,NN,Niter,eps,verb,mode,iflb,a,K);

% RR+DAMPING+MA
e=0.975; ws=1;
d4=drr_ma5d_lb_recon(d0,mask,flow,fhigh,dt,N,NN,Niter,eps,verb,mode,iflb,a,e,ws);

% RR+DAMPING+ST+MA
K=3.3; 
e=0.972; 
ws=1;
d5=rdrr5d_lb_recon(d0,mask,flow,fhigh,dt,N,NN,Niter,eps,verb,mode,iflb,a,K,e,ws);

SNR(d, dn)
SNR(d, d0)
SNR(d, d1)
SNR(d, d2)
SNR(d, d3)
SNR(d, d4)
SNR(d, d5)

%% save data
% fid1=fopen('synth_clean5d.bin','w');
% fwrite(fid1,d,'float');
% fid2=fopen('synth_noisy5d.bin','w');
% fwrite(fid2,dn,'float');
% fid3=fopen('synth_obs5d.bin','w');
% fwrite(fid3,d0,'float');
% fid4=fopen('synth_rr5d.bin','w');
% fwrite(fid4,d1,'float');
% fid5=fopen('synth_irr5d.bin','w');
% fwrite(fid5,d2,'float');
%% from Matlab to Madagascar


rsf_create(clean,size(d)');
rsf_write(d,clean);

%rsf_create(noisy,size(dn)');
%rsf_write(dn,noisy);

%rsf_create(obs,size(d0)');
%rsf_write(d0,obs);

rsf_create(rrdamping,size(d1)');
rsf_write(d1,rrdamping);

rsf_create(rrstma,size(d2)');
rsf_write(d2,rrstma);

rsf_create(rrdampingst,size(d3)');
rsf_write(d3, rrdampingst);

rsf_create(rrdampingma,size(d4)');
rsf_write(d4,rrdampingma);

rsf_create(rrdampingstma,size(d5)');
rsf_write(d5,rrdampingstma);
















