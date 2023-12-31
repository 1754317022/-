function [ D1 ] = mrc5d_lb_recon_synth(D,MASK,flow,fhigh,dt,K,NN,N,Niter,eps,verb,mode,iflb,a)
%  MRC5D: Mixed rank-constrained model (MRC) for simultaneous denoising and reconstruction of 5-D seismic data
%          with Lanczos bidiagonalization
%
%  IN   D:   	intput 5D data
%       MASK:   sampling mask (consistent with the POCS based approaches)
%       flow:   processing frequency range (lower)
%       fhigh:  processing frequency range (higher)
%       dt:     temporal sampling interval
%       K:      number of singular value to be preserved in the matrix
%       NN:     damping factor
%       N:      number of singular value to be preserved in the tensor
%       Niter:  number of maximum iteration
%       eps:    tolerence (||S(n)-S(n-1)||_F<eps*S(n))
%       verb:   verbosity flag (default: 0)
%       mode:   mode=1: denoising and reconstruction
%               mode=0: reconstruction only
%       iflb:   default 0;
%               1: with LB, MGS orthogonalized
%               0: traditional
%       a:      scalar
%
%  OUT  D1:  	output data
%
%  Copyright (C) 2015 The University of Texas at Austin
%  Copyright (C) 2015 Yangkang Chen
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published
%  by the Free Software Foundation, either version 3 of the License, or
%  any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details: http://www.gnu.org/licenses/
%

%  [1] Oboue and Chen 2021, Mixed rank-constrained model (MRC) for simultaneous denoising and reconstruction of 5-D seismic data, TGRS.
%  [2] Bai et al., 2020, Seismic signal enhancement based on the lowrank methods, Geophysical Prospecting, 68, 2783-2807.
%  [3] Chen et al., 2020, Five-dimensional seismic data reconstruction using the optimally damped rank-reduction method, Geophysical Journal International, 222, 1824-1845.
%  [4] Chen, Y., W. Huang, D. Zhang, W. Chen, 2016, An open-source matlab code package for improved rank-reduction 3D seismic data denoising and reconstruction, Computers & Geosciences, 95, 59-66.
%  [5] Chen, Y., D. Zhang, Z. Jin, X. Chen, S. Zu, W. Huang, and S. Gan, 2016, Simultaneous denoising and reconstruction of 5D seismic data via damped rank-reduction method, Geophysical Journal International, 206, 1695-1717.
%  [6] Huang, W., R. Wang, Y. Chen, H. Li, and S. Gan, 2016, Damped multichannel singular spectrum analysis for 3D random noise attenuation, Geophysics, 81, V261-V270.
%  [7] Chen et al., 2017, Preserving the discontinuities in least-squares reverse time migration of simultaneous-source data, Geophysics, 82, S185-S196.
%  [8] Chen et al., 2019, Obtaining free USArray data by multi-dimensional seismic reconstruction, Nature Communications, 10:4434.

addpath('../matfun/tensor_toolbox_2.4');

if nargin==0
    error('Input data must be provided!');
end

if nargin==2
    flow=0;
    fhigh=125;
    dt=0.004;
    N=1;
    Niter=30;
    eps=0.00001;
    verb=0;
    mode=1;
    iflb=0;
end;

if mode==0;
    a=ones(1,Niter);
end

mask=squeeze(MASK(1,:,:,:,:));

[nt,nx,ny,nhx,nhy]=size(D);
D1=zeros(nt,nx,ny,nhx,nhy);

nf=2^nextpow2(nt);

% Transform into F-X domain
DATA_FX=fft(D,nf,1);
DATA_FX0=zeros(nf,nx,ny,nhx,nhy);

% First and last nts of the DFT.
ilow  = floor(flow*dt*nf)+1;

if ilow<1;
    ilow=1;
end;

ihigh = floor(fhigh*dt*nf)+1;

if ihigh > floor(nf/2)+1;
    ihigh=floor(nf/2)+1;
end

lx=floor(nx/2)+1;
lxx=nx-lx+1;
ly=floor(ny/2)+1;
lyy=ny-ly+1;
lhx=floor(nhx/2)+1;
lhxx=nhx-lhx+1;
lhy=floor(nhy/2)+1;
lhyy=nhy-lhy+1;
M=zeros(lx*ly*lhx*lhy,lxx*lyy*lhxx,lhyy);

% main loop
for k=ilow:ihigh
    
    S_obs=squeeze(squeeze(DATA_FX(k,:,:,:,:)));
%     Sn_1=S_obs;
    Nway=[size(S_obs,1), size(S_obs,2), size(S_obs,3),size(S_obs,4)];

    for n = 1:4
        coNway(n) = prod(Nway)/Nway(n);
    end
    
 % size(coNway);
    for i = 1:4
        Y0{i} = Unfold(S_obs,Nway,i);
        Y0{i} = Y0{i}';
        X0{i}= ones(coNway(i), N(i));
        A0{i}= rand(N(i),Nway(i));
    end
    rho=1;
    rho1=rho;
    rho2=rho;
    rho3=rho;
    Y_p=Y0;
    X_p=X0;
    A_p=A0;      
    
temp=A_p{1}*A_p{1}'+rho1*(eye(size(A_p{1}*A_p{1}')));
        X{1}=(Y_p{1}*A_p{1}'+rho1*X_p{1})*pinv(temp);

        temp=A_p{2}*A_p{2}'+rho1*(eye(size(A_p{2}*A_p{2}')));
        X{2}=(Y_p{2}*A_p{2}'+rho1*X_p{2})*pinv(temp);
        
        temp=A_p{3}*A_p{3}'+rho1*(eye(size(A_p{3}*A_p{3}')));
        X{3}=(Y_p{3}*A_p{3}'+rho1*X_p{3})*pinv(temp);

        temp=A_p{4}*A_p{4}'+rho1*(eye(size(A_p{4}*A_p{4}')));
        X{4}=(Y_p{4}*A_p{4}'+rho1*X_p{4})*pinv(temp);
      
        % updata A
        temp=X{1}'*X{1}+rho2*eye(size(X{1}'*X{1}));
        A{1}= pinv(temp)*(X{1}'*Y_p{1}+rho2*A_p{1});

        temp=X{2}'*X{2}+rho2*eye(size(X{2}'*X{2}));
        A{2}= pinv(temp)*(X{2}'*Y_p{2}+rho2*A_p{2});

        temp=X{3}'*X{3}+rho2*eye(size(X{3}'*X{3}));
        A{3}= pinv(temp)*(X{3}'*Y_p{3}+rho2*A_p{3});

        temp=X{4}'*X{4}+rho2*eye(size(X{4}'*X{4}));
        A{4}= pinv(temp)*(X{4}'*Y_p{4}+rho2*A_p{4});

        % update Y 
        Y{1} = (X{1}*A{1}+rho3*Y_p{1})/(1+rho3); Y1 = Fold(Y{1}', Nway, 1);

        Y{2} = (X{2}*A{2}+rho3*Y_p{2})/(1+rho3); Y2 = Fold(Y{2}', Nway, 2); 

       Y{3} = (X{3}*A{3}+rho3*Y_p{3})/(1+rho3); Y3 = Fold(Y{3}', Nway, 3);

        Y{4} = (X{4}*A{4}+rho3*Y_p{4})/(1+rho3); Y4 = Fold(Y{4}', Nway, 4);

        Sn_1 = Y1+Y2+Y3+Y4;  

    for iter=1:Niter
        M=P_H(Sn_1,lx,ly,lhx,lhy);
        if iflb~=1
            M=P_R(M,K,iflb,NN);
        else
            M=P_R(M,K,iflb);
        end
        
        if 1==0 %for outputing the Hankel matrix for comparison
            if iter==1 && k==floor(ihigh/3);
                M_irr=M;
                save irr_H.mat M_irr
                fprintf('output irr_H done\n');
            end
        end
        size(M);
        Sn=P_A(M,nx,ny,nhx,nhy,lx,ly,lhx,lhy);
        DD = tensor(Sn,[nx,ny,nhx,nhy]);
        D1 = yc_tucker_als(DD,[N(1),N(2),N(3),N(4)]);
                         Sn = double(D1);
        Sn=a(iter)*S_obs+(1-a(iter))*mask.*Sn+(1-mask).*Sn;
        if norm(reshape(Sn-Sn_1,nhx*nhy*nx*ny,1),'fro')<eps
            break;
        end
        Sn_1=Sn;
    end
    DATA_FX0(k,:,:,:,:)=DATA_FX0(k,:,:,:,:)+reshape(Sn,1,nx,ny,nhx,nhy);
    
    if(mod(k,5)==0 && verb==1)
        fprintf( 'F %d is done!\n\n',k);
    end
end

% Honor symmetries
for k=nf/2+2:nf
    DATA_FX0(k,:,:,:,:) = conj(DATA_FX0(nf-k+2,:,:,:,:));
end

% Back to TX (the output)
D1=real(ifft(DATA_FX0,[],1));
D1=D1(1:nt,:,:,:,:);
return

function W = Fold(W, dim, i)
        dim = circshift(dim, [1-i, 1-i]);
        W = shiftdim(reshape(W, dim), length(dim)+1-i);
return

function W = Unfold(W, dim, i)
        W = reshape(shiftdim(W,i-1), dim(i), []);
return


function [dout]=P_H(din,lx,ly,lhx,lhy)
% forming block Hankel matrix (5D version)
[nx,ny,nhx,nhy]=size(din);
lxx=nx-lx+1;
lyy=ny-ly+1;
lhxx=nhx-lhx+1;
lhyy=nhy-lhy+1;

for ky=1:nhy
    for kx=1:nhx
        for j=1:ny
            r1=hankel(din(1:lx,j,kx,ky),[din(lx:nx,j,kx,ky)]);
            if j<ly
                for id=1:j
                    r1o(1+(j-1)*lx-(id-1)*lx:j*lx-(id-1)*lx,1+(id-1)*lxx:lxx+(id-1)*lxx) = r1;
                end
            else
                for id=1:(ny-j+1)
                    r1o((ly-1)*lx+1-(id-1)*lx:ly*lx-(id-1)*lx,(j-ly)*lxx+1+(id-1)*lxx:(j-ly+1)*lxx+(id-1)*lxx)=r1;
                end
            end
        end
        r2=r1o;r1o=[];
        if kx<lhx
            for id=1:kx
                r2o(1+(kx-1)*lx*ly-(id-1)*lx*ly:kx*lx*ly-(id-1)*lx*ly,1+(id-1)*lxx*lyy:lxx*lyy+(id-1)*lxx*lyy) = r2;
            end
        else
            for id=1:(nhx-kx+1)
                r2o((lhx-1)*lx*ly+1-(id-1)*lx*ly:lhx*lx*ly-(id-1)*lx*ly,(kx-lhx)*lxx*lyy+1+(id-1)*lxx*lyy:(kx-lhx+1)*lxx*lyy+(id-1)*lxx*lyy)=r2;
            end
        end
    end
    r3=r2o;r2o=[];
    if ky<lhy
        for id=1:ky
            r3o(1+(ky-1)*lx*ly*lhx-(id-1)*lx*ly*lhx:ky*lx*ly*lhx-(id-1)*lx*ly*lhx,1+(id-1)*lxx*lyy*lhxx:lxx*lyy*lhxx+(id-1)*lxx*lyy*lhxx) = r3;
        end
    else
        for id=1:(nhy-ky+1)
            r3o((lhy-1)*lx*ly*lhx+1-(id-1)*lx*ly*lhx:lhy*lx*ly*lhx-(id-1)*lx*ly*lhx,(ky-lhy)*lxx*lyy*lhxx+1+(id-1)*lxx*lyy*lhxx:(ky-lhy+1)*lxx*lyy*lhxx+(id-1)*lxx*lyy*lhxx)=r3;
        end
    end
end
dout=r3o;
return

function [dout]=P_R(din,K,iflb,NN)
% Rank reduction on the block Hankel matrix
[n1,n2]=size(din);
switch iflb
    case 0
        if NN~=Inf
%         [U,B,V]=svds(din,N+1); % a little bit slower for small matrix
        [U,B,V]=svd(din); % a little bit slower for small matrix
        for j=1:K
            B(j,j)=B(j,j)*(1-B(K+1,K+1)^NN/B(j,j)^NN);
        end
        
        %              dout=U*D*V';
        % %
        %         [U,B,V]=svd(din);
        
        dout=U(:,1:K)*B(1:K,1:K)*(V(:,1:K)');
        else
%           [U,B,V]=svds(din,N);
          [U,B,V]=svd(din)
          dout=U(:,1:K)*B(1:K,1:N)*(V(:,1:K)');
        end
    case 1 %LB
        [U,B,V]=yc_lb(din,randn(n1,1),K,1);
        dout=U(:,1:K)*B(1:N,1:K)*(V(:,1:K)');
    case 2 % use damped optshrink
        
        dout=optshrinkcyk_damp(din,K,NN);
    case 3 % use optshrink
        
        dout=optshrinkcyk(din,K);
    otherwise
        error('Invalid argument value.');
end
return

function [dout]=P_A(din,nx,ny,nhx,nhy,lx,ly,lhx,lhy)
% Averaging the block Hankel matrix to output the result (5D version)
lxx=nx-lx+1;
lyy=ny-ly+1;
lhxx=nhx-lhx+1;
lhyy=nhy-lhy+1;
dout=zeros(nx,ny,nhx,nhy);


for ky=1:nhy
    r3o=zeros(lx*ly*lhx,lxx*lyy*lhxx);
    if ky<lhy
        for id=1:ky
            r3o=r3o+din(1+(ky-1)*lx*ly*lhx-(id-1)*lx*ly*lhx:ky*lx*ly*lhx-(id-1)*lx*ly*lhx,1+(id-1)*lxx*lyy*lhxx:lxx*lyy*lhxx+(id-1)*lxx*lyy*lhxx)/ky;
        end
    else
        for id=1:(nhy-ky+1)
            r3o=r3o+din((lhy-1)*lx*ly*lhx+1-(id-1)*lx*ly*lhx:lhy*lx*ly*lhx-(id-1)*lx*ly*lhx,(ky-lhy)*lxx*lyy*lhxx+1+(id-1)*lxx*lyy*lhxx:(ky-lhy+1)*lxx*lyy*lhxx+(id-1)*lxx*lyy*lhxx)/(nhy-ky+1);
        end
    end
    for kx=1:nhx
        r2o=zeros(lx*ly,lxx*lyy);
        if kx<lhx
            for id=1:kx
                r2o=r2o+ r3o(1+(kx-1)*lx*ly-(id-1)*lx*ly:kx*lx*ly-(id-1)*lx*ly,1+(id-1)*lxx*lyy:lxx*lyy+(id-1)*lxx*lyy)/kx;
            end
        else
            for id=1:(nhx-kx+1)
                r2o=r2o+ r3o((lhx-1)*lx*ly+1-(id-1)*lx*ly:lhx*lx*ly-(id-1)*lx*ly,(kx-lhx)*lxx*lyy+1+(id-1)*lxx*lyy:(kx-lhx+1)*lxx*lyy+(id-1)*lxx*lyy)/(nhx-kx+1);
            end
        end
        for j=1:ny
            if j<ly
                for id=1:j
                    dout(:,j,kx,ky) =dout(:,j,kx,ky)+ ave_antid(r2o(1+(j-1)*lx-(id-1)*lx:j*lx-(id-1)*lx,1+(id-1)*lxx:lxx+(id-1)*lxx))/j;
                end
            else
                for id=1:(ny-j+1)
                    dout(:,j,kx,ky) =dout(:,j,kx,ky)+ ave_antid(r2o((ly-1)*lx+1-(id-1)*lx:ly*lx-(id-1)*lx,(j-ly)*lxx+1+(id-1)*lxx:(j-ly+1)*lxx+(id-1)*lxx))/(ny-j+1);
                end
            end
        end
    end
end
return


function [dout] =ave_antid(din);
% averaging along antidiagonals

[n1,n2]=size(din);
nout=n1+n2-1;
dout=zeros(nout,1);
for i=1:nout
    if i<n1
        for id=1:i
            dout(i)=dout(i) + din(i-(id-1),1+(id-1))/i;
        end
    else
        for id=1:nout+1-i
            dout(i)=dout(i) + din(n1-(id-1),1+(i-n1)+(id-1))/(nout+1-i);
        end
    end
end
return







