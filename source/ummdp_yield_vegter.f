************************************************************************
c
c     YEGTER YIELD FUNCTION
c
c       doi: https://doi.org/10.1016/j.ijplas.2005.04.009
c
      subroutine ummdp_yield_vegter ( s,se,dseds,d2seds2,nreq,pryld,
     1                                ndyld )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: nreq,ndyld
      real*8 ,intent(in) :: s(3),pryld(ndyld)
c
      real*8,intent(out) :: se
      real*8,intent(out) :: dseds(3)
			real*8,intent(out) :: d2seds2(3,3)
c
      integer nf
c-----------------------------------------------------------------------
c
      nf = nint(pryld(2)) - 1
      call ummdp_yield_vegter_core ( s,se,dseds,d2seds2,nreq,pryld,
     1                               ndyld,nf )
c
      return
      end subroutine ummdp_yield_vegter
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     VEGTER CORE SUBROUTINE
c
      subroutine ummdp_yield_vegter_core ( s,se,dseds,d2seds2,nreq,
     1                                     pryld,ndyld,nf )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: nreq,ndyld,nf
      real*8 ,intent(in) :: s(3),pryld(ndyld)
c
      real*8,intent(out) :: se
      real*8,intent(out) :: dseds(3)
			real*8,intent(out) :: d2seds2(3,3)
c
      integer i,j,k,m,n,isflag,iareaflag,ithetaflag
      real*8 pi,tol0,tol2,tol,vsqrt,vcos2t,vsin2t,theta,theta_rv,f_bi0,
     1       r_bi0,fun1,fun2,run,fsh1,fsh2,rsh,fps1,fps2,rps,fbi1,fbi2,
     2       rbi,fun1r,fun2r,runr,fps1r,fps2r,rpsr,alfa,beta,aa,bb,cc,
     3       dd,dmdctmp,dndctmp,nnmm,d2mdc2tmp,d2ndc2tmp
      real*8 x(4),a(2),b(2),c(2),mm(2),nn(2),mu,f(2),dphidx(3),dfdmu(2),
     1       dadc(2),dcdc(2),dbdc(2),dndc(2),dmdc(2),P(2),dfdc(2),
     2       d2adc2(2),d2bdc2(2),d2cdc2(2),d2ndc2(2),d2mdc2(2)
      real*8 dxds(3,3),d2phidx2(3,3)
      real*8 phi_un(0:nf),phi_sh(0:nf),phi_ps(0:nf),omg(0:nf),
     1       vvtmp(0:6),vvtmp_rv(0:6)
c-----------------------------------------------------------------------
c                             ---- vegter's parameters from main routine
c     pryld(2) : nf           ! fourier term
c     pryld(3) : f_bi0        ! eq. bi-axial
c     pryld(4) : r_bi0        ! eq. bi-axial
c     i : 1~nf
c     n0=4+i*4
c     test angle  : 90/(nf)*i
c     pryld(n0+1) : phi_un(i) ! uniaxial
c     pryld(n0+2) : phi_sh(i) ! pure shear
c     pryld(n0+3) : phi_ps(i) ! plane strain
c     pryld(n0+4) : omg(   i)
c
c     this program assumes 2 type of tests
c       type 1 : 3 tests (0,45,90 deg)
c                set :phi_un,phi_sh,phi_ps,omg (1 to 3)
c                     phi_un,phi_sh,phi_ps,omg (4 to 6) =0.0
c       type 2 : 6 tests (0,15,30,45,60,75,90 deg)
c                set :phi_un,phi_sh,phi_ps,omg (1 to 6)
c-----------------------------------------------------------------------
c
      pi = acos(-1.0d0)
      tol = 1.0d-4       ! exception treatment tolerance of vsin2t
      tol0 = 1.0d-8      ! exception treatment tolerance of stress state
      tol2 = 1.0d-2      ! se tolerance change f(1) to f(2)
c
      f_bi0 = pryld(3)
      r_bi0 = pryld(4)
      do i = 0,nf
        phi_un(i) = pryld(4+i*4+1)
        phi_sh(i) = pryld(4+i*4+2)
        phi_ps(i) = pryld(4+i*4+3)
        omg(   i) = pryld(4+i*4+4)
      end do
c
      se = 0.0d0
      do i = 1,3
        se = se + s(i)**2
      end do
      if ( se <= 0.0d0 ) then
        se = 0.0d0
        return
      end if

c                                       ---- calc x(i) from eq.(14)~(17)
c     x(i)    : Principal stress(i=1^2)
c             : cos2theta(i=3), sin2theta(i=4)
c     isflag  : 0 s(i,i=1,3)=0
c             : 1 not s(i)=0
c                                 ---- exception treatment if all s(i)=0
c
      if ( (abs(s(1)) <= tol0) .and.
     1     (abs(s(2)) <= tol0) .and.
     2     (abs(s(3)) <= tol0) ) then
      isflag = 0
      x = 0.0d0
      goto 100
c
      else
      isflag=1
      x = 0.0d0
c
c                           ---- exception treatment if s(1)=s(2),s(3)=0
c
      if ( (abs(s(1)-s(2)) <= tol0) .and. (abs(s(3)) <= tol0) ) then
        theta = 0.0d0
        theta_rv = 0.5d0*pi
        x(1) = 0.5d0*(s(1)+s(2))
        x(2) = 0.5d0*(s(1)+s(2))
        x(3) = cos(2.0d0*theta)
        x(4) = sin(2.0d0*theta)
        vcos2t = x(3)
        vsin2t = x(4)
c                                                    ---- normal process
      else
        vsqrt = sqrt((s(1)-s(2))**2+4.0d0*s(3)**2)
        x(1) = 0.5d0*(s(1)+s(2)+vsqrt)
        x(2) = 0.5d0*(s(1)+s(2)-vsqrt)
        x(3) = (s(1)-s(2))/vsqrt
        x(4) = 2.0d0*s(3)/vsqrt
        vcos2t = x(3)
        vsin2t = x(4)
        theta = 0.5d0*acos(vcos2t)
        theta_rv = 0.5d0*pi-theta
        end if
      end if
c                        ---- calc fk(k=un,sh,ps,bi) , rk(k=un,sh,ps,bi)
c
c                                                          ! un=uniaxial
        fun1 = 0.0d0
        fun1r = 0.0d0
        run = 0.0d0
        runr = 0.0d0
      do m = 0,nf
        fun1 = fun1 + phi_un(m)*cos(2.0d0*dble(m)*theta)
        fun1r = fun1r + phi_un(m)*cos(2.0d0*dble(m)*theta_rv)
        run = run + omg(m)*cos(2.0d0*dble(m)*theta)
        runr = runr + omg(m)*cos(2.0d0*dble(m)*theta_rv)
      end do
        fun2 = 0.0d0
        fun2r = 0.0d0
c                                                        ! sh=pure shear
        fsh1 = 0.0d0
        fsh2 = 0.0d0
      do m = 0,nf
        fsh1 = fsh1 + phi_sh(m)*cos(2.0d0*dble(m)*theta)
        fsh2 = fsh2 - phi_sh(m)*cos(2.0d0*dble(m)*theta_rv)
      end do
        rsh = -1.0d0
c                                                      ! ps=plane strain
        fps1 = 0.0d0
        fps1r = 0.0d0
        rps = 0.0d0
        rpsr = 0.0d0
      do m = 0,nf
        fps1 = fps1 + phi_ps(m)*cos(2.0d0*dble(m)*theta)
        fps2 = 0.5d0 * fps1
        fps1r = fps1r + phi_ps(m)*cos(2.0d0*dble(m)*theta_rv)
        fps2r = 0.5d0 * fps1r
      end do
        rps = -0.0d0
        rpsr = 0.0d0
c                                                      ! bi=equi-biaxial
        fbi1 = f_bi0
        fbi2 = fbi1
        rbi = ((r_bi0+1.0d0)+(r_bi0-1.0d0)*vcos2t)/
     1           ((r_bi0+1.0d0)-(r_bi0-1.0d0)*vcos2t)
c
c                                 ---- case distribution by stress state
      if ( x(1) /= 0.0d0 ) then
        alfa = x(2) / x(1)
      end if
      if ( x(2) /= 0.0d0 ) then
        beta = x(1) / x(2)
      end if
c
c     iareaflag    :stress state flag(i=0~6)
c
      if ( (x(1) > 0.0d0) .and.
     1     (alfa < 0.0d0) .and.
     2     (alfa >= fsh2/fsh1)) then
        iareaflag = 1
      else if ( (x(1) > 0.0d0) .and.
     1          (alfa >= 0.0d0) .and.
     2          (alfa < fps2/fps1) ) then
        iareaflag = 2
      else if ( (x(1) > 0.0d0) .and.
     1          (alfa >= fps2/fps1) .and.
     2          (alfa <= 1.0d0) ) then
        iareaflag = 3
c
      else if ( (x(1) < 0.0d0) .and.
     1          (alfa >= 1.0d0) .and.
     2          (alfa < fps1r/fps2r) ) then
        iareaflag = 4
      else if ( (x(1) < 0.0d0) .and.
     1          (beta <= fps2r/fps1r) .and.
     2          (beta > 0.0d0) ) then
        iareaflag = 5
      else if ( (x(1) >= 0.0d0) .and.
     1          (beta <= 0.0d0) .and.
     1          (beta > fsh1/fsh2) ) then
        iareaflag = 6
c
      else
        go to 100
      end if
c
c                                       ---- calc. hingepoint b(i,i=1~2)
      select case ( iareaflag )
c
      case ( 1 )                                           ! iareaflag=1
        a(1) = fsh1
        a(2) = fsh2
        c(1) = fun1
        c(2) = fun2
        nn(1) = 1.0d0
        nn(2) = rsh
        mm(1) = 1.0d0
        mm(2) = run
        call ummdp_yield_vegter_hingepoint ( a,b,c,mm,nn,iareaflag,s )
c
      case ( 2 )                                           ! iareaflag=2
        a(1) = fun1
        a(2) = fun2
        c(1) = fps1
        c(2) = fps2
        nn(1) = 1.0d0
        nn(2) = run
        mm(1) = 1.0d0
        mm(2) = rps
        call ummdp_yield_vegter_hingepoint ( a,b,c,mm,nn,iareaflag,s )
c
      case ( 3 )                                           ! iareaflag=3
        a(1) = fps1
        a(2) = fps2
        c(1) = fbi1
        c(2) = fbi2
        nn(1) = 1.0d0
        nn(2) = rps
        mm(1) = 1.0d0
        mm(2) = rbi
        call ummdp_yield_vegter_hingepoint ( a,b,c,mm,nn,iareaflag,s )
c
      case ( 4 )                                           ! iareaflag=4
        a(1) = -fbi1
        a(2) = -fbi2
        c(1) = -fps2r
        c(2) = -fps1r
        nn(1) = -1.0d0
        nn(2) = -rbi
        mm(1) = -rpsr
        mm(2) = -1.0d0
        call ummdp_yield_vegter_hingepoint ( a,b,c,mm,nn,iareaflag,s )
c
      case ( 5 )                                           ! iareaflag=5
        a(1) = -fps2r
        a(2) = -fps1r
        c(1) = -fun2r
        c(2) = -fun1r
        nn(1) = -rpsr
        nn(2) = -1.0d0
        mm(1) = -runr
        mm(2) = -1.0d0
        call ummdp_yield_vegter_hingepoint ( a,b,c,mm,nn,iareaflag,s )
c
      case ( 6 )                                           ! iareaflag=6
        a(1) = -fun2r
        a(2) = -fun1r
        c(1) = fsh1
        c(2) = fsh2
        nn(1) = -runr
        nn(2) = -1.0d0
        mm(1) = 1.0d0
        mm(2) = rsh
        call ummdp_yield_vegter_hingepoint ( a,b,c,mm,nn,iareaflag,s )
c
      case default
        write (6,*) 'iareaflag error :',iareaflag
        call ummdp_exit (9000)
      end select

c                            ---- calc. fourier coefficient mu(0<=mu<=1)
      call ummdp_yield_vegter_mu ( x,a,b,c,mu,iareaflag,s,theta,aa,
     1                                  bb,cc,dd )
c
c                            ---- calc. normalized yield locus f(i)i=1~2
      call ummdp_yield_vegter_fi ( x,a,b,c,mu,f )
      go to 200
c
c                                                 ---- equivalent stress
  100 continue
      se = 0.0d0
      go to 300
  200 continue
      if ( f(1) <= tol2 ) then
         se = x(2) / f(2)
      else
         se = x(1) / f(1)
      end if
c
      go to 300
c
  300 continue
c
c                                            ---- 1st order differential
c
      if ( nreq >= 1 ) then
c                        ---- set dadc,dcdc,dndc,dmdc for eq.(A.7)^(A.9)
c
      dadc = 0.0d0
      dbdc = 0.0d0
      dcdc = 0.0d0
      dndc = 0.0d0
      dmdc = 0.0d0
c
      select case ( iareaflag )
c
      case ( 1 )                                           ! iareaflag=1
        if ( abs(vsin2t) >= tol ) then
          do m = 0,nf
            dadc(1) = dadc(1) + phi_sh(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta)
     2                             /sin(2.0d0*theta)
            dadc(2) = dadc(2) + phi_sh(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta_rv)
     2                             /sin(2.0d0*theta)
          end do
        else
          do m = 0,nf
            dadc(1) = dadc(1) + phi_sh(m)*dble(m)**2
            dadc(2) = dadc(2) + phi_sh(m)*dble(m)**2
          end do
        end if
c
        if ( abs(vsin2t) >= tol ) then
          do m = 0,nf
            dcdc(1) = dcdc(1) + phi_un(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta)
     2                             /sin(2.0d0*theta)
          end do
        else
          do m = 0,nf
            dcdc(1) = dcdc(1) + phi_un(m)*dble(m)**2
          end do
        end if
c
c
        if ( abs(vsin2t) >= tol ) then
          do m = 0,nf
            dmdc(2) = dmdc(2) + omg(m)*dble(m)
     1                          *sin(2.0d0*dble(m)*theta)
     2                          /sin(2.0d0*theta)
          end do
        else
          do m = 0,nf
            dmdc(2) = dmdc(2) + omg(m)*dble(m)**2
          end do
        end if
        call ummdp_yield_vegter_dbdc ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1                                 dmdc,iareaflag,P,nnmm )
c
      case ( 2 )                                           ! iareaflag=2
        if ( abs(vsin2t) >= tol ) then
          do m = 0,nf
            dadc(1) = dadc(1) + phi_un(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta)
     2                             /sin(2.0d0*theta)
          end do
        else
          do m = 0,nf
            dadc(1) = dadc(1) + phi_un(m)*dble(m)**2
          end do
        end if
c
        if ( abs(vsin2t) >= tol ) then
          do m = 0,nf
            dcdc(1) = dcdc(1) + phi_ps(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta)
     2                             /sin(2.0d0*theta)
          end do
        else
          do m = 0,nf
            dcdc(1) = dcdc(1) + phi_ps(m)*dble(m)**2
          end do
        end if
          dcdc(2) = 0.5d0 * dcdc(1)
c
        if ( abs(vsin2t) >= tol ) then
          do m = 0,nf
            dndc(2) = dndc(2) + omg(m)*dble(m)
     1                           *sin(2.0d0*dble(m)*theta)
     2                           /sin(2.0d0*theta)
          end do
        else
          do m = 0,nf
            dndc(2) = dndc(2) + omg(m)*dble(m)**2
          end do
        end if
c
        call ummdp_yield_vegter_dbdc ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1                                 dmdc,iareaflag,P,nnmm )
c
c
      case ( 3 )                                           ! iareaflag=3
        if ( abs(vsin2t) >= tol ) then
          do m = 0,nf
            dadc(1) = dadc(1) + phi_ps(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta)
     2                             /sin(2.0d0*theta)
          end do
        else
          do m = 0,nf
          dadc(1) = dadc(1) + phi_ps(m)*dble(m)**2
          end do
        end if
        dadc(2) = 0.5d0 * dadc(1)
c
        dmdctmp = r_bi0 + 1.0d0-(r_bi0-1.0d0)*vcos2t
        dmdc(2) = 2.0d0*(r_bi0*r_bi0-1.0d0)/(dmdctmp*dmdctmp)
        call ummdp_yield_vegter_dbdc ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1                                 dmdc,iareaflag,P,nnmm )
c
      case ( 4 )                                           ! iareaflag=4
c
        if ( abs(vsin2t) >= tol ) then
          do m = 0,nf
            dcdc(2) = dcdc(2) + phi_ps(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta_rv)
     2                             /sin(2.0d0*theta)
          end do
        else
          do m = 0,nf
            dcdc(2) = dcdc(2) + phi_ps(m)*dble(m)**2
          end do
        end if
        dcdc(1) = 0.5d0 * dcdc(2)
c
        dndctmp = r_bi0 + 1.0d0-(r_bi0-1.0d0)*vcos2t
        dndc(2) = -2.0d0 * (r_bi0*r_bi0-1.0d0)/(dndctmp*dndctmp)
c
        call ummdp_yield_vegter_dbdc ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1                                 dmdc,iareaflag,P,nnmm)
c
      case ( 5 )                                           ! iareaflag=5
       if(abs(vsin2t)>=TOL) then
        do m=0,nf
          dadc(2)=dadc(2)+phi_ps(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta_rv)
     2                             /sin(2.0d0*theta)
         end do
        else
         do m=0,nf
          dadc(2)=dadc(2)+phi_ps(m)*dble(m)**2
         end do
       end if
          dadc(1)=0.5d0*dadc(2)
c
          dcdc(1)=0.0d0
       if(abs(vsin2t)>=TOL) then
        do m=0,nf
          dcdc(2)=dcdc(2)+phi_un(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta_rv)
     2                             /sin(2.0d0*theta)
         end do
        else
         do m=0,nf
          dcdc(2)=dcdc(2)+phi_un(m)*dble(m)**2
         end do
       end if
c
          dndc(1)=0.0d0
          dndc(2)=0.0d0
c
       if(abs(vsin2t)>=TOL) then
        do m=0,nf
          dmdc(1)=dmdc(1)+omg(m)*dble(m)
     1                          *sin(2.0d0*dble(m)*theta_rv)
     2                          /sin(2.0d0*theta)
         end do
        else
         do m=0,nf
          dmdc(1)=dmdc(1)+omg(m)*dble(m)**2
         end do
       end if
          dmdc(2)=0.0d0
      call ummdp_yield_vegter_dbdc ( a,b,c,dadc,dbdc,dcdc,mm,nn,
     1                               dndc,dmdc,iareaflag,P,nnmm)
c
c
      case ( 6 )                                           ! iareaflag=6
          dadc(1)=0.0d0
       if(abs(vsin2t)>=TOL) then
        do m=0,nf
          dadc(2)=dadc(2)+phi_un(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta_rv)
     2                             /sin(2.0d0*theta)
         end do
        else
         do m=0,nf
          dadc(2)=dadc(2)+phi_un(m)*dble(m)**2
         end do
       end if
c
       if(abs(vsin2t)>=TOL) then
        do m=0,nf
          dcdc(1)=dcdc(1)+phi_sh(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta)
     2                             /sin(2.0d0*theta)
          dcdc(2)=dcdc(2)+phi_sh(m)*dble(m)
     1                             *sin(2.0d0*dble(m)*theta_rv)
     2                             /sin(2.0d0*theta)
         end do
        else
         do m=0,nf
          dcdc(1)=dcdc(1)+phi_sh(m)*dble(m)**2
          dcdc(2)=dcdc(2)+phi_sh(m)*dble(m)**2
         end do
       end if
c
       if(abs(vsin2t)>=TOL) then
        do m=0,nf
          dndc(1)=dndc(1)+omg(m)*dble(m)
     1                          *sin(2.0d0*dble(m)*theta_rv)
     2                          /sin(2.0d0*theta)
         end do
        else
         do m=0,nf
          dndc(1)=dndc(1)+omg(m)*dble(m)**2
         end do
       end if
          dndc(2)=0.0d0
c
          dmdc(1)=0.0d0
          dmdc(2)=0.0d0
      call ummdp_yield_vegter_dbdc ( a,b,c,dadc,dbdc,dcdc,mm,nn,
     1                               dndc,dmdc,iareaflag,P,nnmm)
c
      case default
        write (6,*) 'iareaflag error(dseds) :',iareaflag
        call ummdp_exit (9000)
      end select
c
c
c                             ---- calc. dphidx(i) (i=1~3)  eq.(21)~(23)
      call ummdp_yield_vegter_dphidx ( dphidx,se,a,b,c,dadc,dbdc,dcdc,
     1                      mm,nn,dndc,dmdc,f,iareaflag,mu,x,dfdmu,dfdc)
c
c
c                                   ---- calc. dseds(i) (i=1~3)  eq.(20)
      call ummdp_yield_vegter_dseds ( dseds,x,dphidx,vcos2t,vsin2t,
     1                                iareaflag,isflag,dxds)
c
      end if
c
c
c                                            ---- 2nd order differential
      if ( nreq>=2 ) then
c                     ---- set d2adc2,d2cdc2,d2ndc2,d2mdc2 for d2bdc2(2)
c
      d2adc2 = 0.0d0
      d2bdc2 = 0.0d0
      d2cdc2 = 0.0d0
      d2ndc2 = 0.0d0
      d2mdc2 = 0.0d0
c
c                     ---- define exception treatment condition of theta
c                        ---- if theta<=0.002865deg then apply exception
c
      if(abs(vsin2t)<=TOL) then
         ithetaflag=1
      else
         ithetaflag=0
      end if
c
      if(ithetaflag==1) then
        vvtmp(0)=0.0d0
        vvtmp(1)=0.0d0
        vvtmp(2)=2.0d0
        vvtmp(3)=8.0d0
        vvtmp(4)=20.0d0
        vvtmp(5)=40.0d0
        vvtmp(6)=70.0d0
c
        vvtmp_rv(0)=0.0d0
        vvtmp_rv(1)=0.0d0
        vvtmp_rv(2)=-2.0d0
        vvtmp_rv(3)=8.0d0
        vvtmp_rv(4)=-20.0d0
        vvtmp_rv(5)=40.0d0
        vvtmp_rv(6)=-70.0d0
c
      else
       do m=0,nf
        vvtmp(m)=cos(2.0d0*theta)*sin(2.0d0*dble(m)*theta)/
     1          (sin(2.0d0*theta)**3)-dble(m)*cos(2.0d0*dble(m)*theta)/
     2                                           (sin(2.0d0*theta)**2)
        vvtmp_rv(m)=cos(2.0d0*theta)*sin(2.0d0*dble(m)*theta_rv)/
     1       (sin(2.0d0*theta)**3)+dble(m)*cos(2.0d0*dble(m)*theta_rv)/
     2                                           (sin(2.0d0*theta)**2)
       end do
c
      end if
c
      select case ( iareaflag )
c
      case ( 1 )                                           ! iareaflag=1
         do m=0,nf
          d2adc2(1)=d2adc2(1)+phi_sh(m)*dble(m)*vvtmp(m)
          d2adc2(2)=d2adc2(2)+phi_sh(m)*dble(m)*vvtmp_rv(m)
         end do
c
         do m=0,nf
          d2cdc2(1)=d2cdc2(1)+phi_un(m)*dble(m)*vvtmp(m)
         end do
          d2cdc2(2)=0.0d0
c
          d2ndc2(1)=0.0d0
          d2ndc2(2)=0.0d0
c
          d2mdc2(1)=0.0d0
         do m=0,nf
          d2mdc2(2)=d2mdc2(2)+omg(m)*dble(m)*vvtmp(m)
         end do
      call ummdp_yield_vegter_d2bdc2 ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1     dmdc,iareaflag,d2adc2,d2bdc2,d2cdc2,d2ndc2,d2mdc2,P,nnmm,s)
c
c
      case ( 2 )                                           ! iareaflag=2
         do m=0,nf
          d2adc2(1)=d2adc2(1)+phi_un(m)*dble(m)*vvtmp(m)
         end do
          d2adc2(2)=0.0d0
c
         do m=0,nf
          d2cdc2(1)=d2cdc2(1)+phi_ps(m)*dble(m)*vvtmp(m)
         end do
          d2cdc2(2)=0.5d0*d2cdc2(1)
c
          d2ndc2(1)=0.0d0
         do m=0,nf
          d2ndc2(2)=d2ndc2(2)+omg(m)*dble(m)*vvtmp(m)
         end do
c
          d2mdc2(1)=0.0d0
          d2mdc2(2)=0.0d0
      call ummdp_yield_vegter_d2bdc2 ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1     dmdc,iareaflag,d2adc2,d2bdc2,d2cdc2,d2ndc2,d2mdc2,P,nnmm,s)
c
c
      case ( 3 )                                           ! iareaflag=3
         do m=0,nf
          d2adc2(1)=d2adc2(1)+phi_ps(m)*dble(m)*vvtmp(m)
         end do
          d2adc2(2)=0.5d0*d2adc2(1)
c
          d2cdc2(1)=0.0d0
          d2cdc2(2)=0.0d0
c
          d2ndc2(1)=0.0d0
          d2ndc2(2)=0.0d0
c
          d2mdc2(1)=0.0d0
             d2mdc2tmp=r_bi0+1.0d0-(r_bi0-1.0d0)*vcos2t
          d2mdc2(2)=4.0d0*(r_bi0**2-1.0d0)*(r_bi0-1.0d0)/
     1                                              (d2mdc2tmp**3)
      call ummdp_yield_vegter_d2bdc2 ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1     dmdc,iareaflag,d2adc2,d2bdc2,d2cdc2,d2ndc2,d2mdc2,P,nnmm,s)
c
c
      case ( 4 )                                          !  iareaflag=4
          d2adc2(1)=0.0d0
          d2adc2(2)=0.0d0
c
         do m=0,nf
          d2cdc2(2)=d2cdc2(2)+phi_ps(m)*dble(m)*vvtmp_rv(m)
         end do
          d2cdc2(1)=0.5d0*d2cdc2(2)
c
          d2ndc2(1)=0.0d0
             d2ndc2tmp=r_bi0+1.0d0-(r_bi0-1.0d0)*vcos2t
          d2ndc2(2)=-4.0d0*(r_bi0**2-1.0d0)*(r_bi0-1.0d0)/
     1                                              (d2ndc2tmp**3)
c
          d2mdc2(1)=0.0d0
          d2mdc2(2)=0.0d0
      call ummdp_yield_vegter_d2bdc2 ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1     dmdc,iareaflag,d2adc2,d2bdc2,d2cdc2,d2ndc2,d2mdc2,P,nnmm,s)
c
c
      case ( 5 )                                           ! iareaflag=5
         do m=0,nf
          d2adc2(2)=d2adc2(2)+phi_ps(m)*dble(m)*vvtmp_rv(m)
         end do
          d2adc2(1)=0.5d0*d2adc2(2)
c
          d2cdc2(1)=0.0d0
         do m=0,nf
          d2cdc2(2)=d2cdc2(2)+phi_un(m)*dble(m)*vvtmp_rv(m)
         end do
c
          d2ndc2(1)=0.0d0
          d2ndc2(2)=0.0d0
c
         do m=0,nf
          d2mdc2(1)=d2mdc2(1)+omg(m)*dble(m)*vvtmp_rv(m)
         end do
          d2mdc2(2)=0.0d0
      call ummdp_yield_vegter_d2bdc2 ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1     dmdc,iareaflag,d2adc2,d2bdc2,d2cdc2,d2ndc2,d2mdc2,P,nnmm,s)
c
c
      case ( 6 )                                           ! iareaflag=6
          d2adc2(1)=0.0d0
         do m=0,nf
          d2adc2(2)=d2adc2(2)+phi_un(m)*dble(m)*vvtmp_rv(m)
         end do
c
         do m=0,nf
          d2cdc2(1)=d2cdc2(1)+phi_sh(m)*dble(m)*vvtmp(m)
          d2cdc2(2)=d2cdc2(2)+phi_sh(m)*dble(m)*vvtmp_rv(m)
         end do
cn
         do m=0,nf
          d2ndc2(1)=d2ndc2(1)+omg(m)*dble(m)*vvtmp_rv(m)
         end do
          d2ndc2(2)=0.0d0
c
          d2mdc2(1)=0.0d0
          d2mdc2(2)=0.0d0
      call ummdp_yield_vegter_d2bdc2 ( a,b,c,dadc,dbdc,dcdc,mm,nn,dndc,
     1     dmdc,iareaflag,d2adc2,d2bdc2,d2cdc2,d2ndc2,d2mdc2,P,nnmm,s)
c
      case default
        write (6,*) 'iareaflag error(d2seds2) :',iareaflag
        call ummdp_exit (9000)
      end select
c
c
c                                     ---- calc. d2phidx2(k,l) (k,l=1~3)
      call ummdp_yield_vegter_d2phidx2 (d2phidx2,se,a,b,c,dadc,dbdc,
     1             dcdc,mm,nn,dndc,dmdc,f,iareaflag,mu,x,d2adc2,d2bdc2,
     2            d2cdc2,d2ndc2,d2mdc2,dfdmu,dfdc,s,aa,bb,cc,dd,dphidx)
c
c
c                                      ---- calc. d2seds2(i,j) (i,j=1~3)
      call ummdp_yield_vegter_d2seds2 (d2seds2,d2phidx2,se,a,b,c,mu,x,
     1         vcos2t,vsin2t,iareaflag,dxds,dphidx,isflag,s,dseds,
     2                                 pryld,ndyld)
c
      end if
c
      return
      end subroutine ummdp_yield_vegter_core
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     CALCULATE HINGEPOINT b(i,i=1~2)
c
      subroutine ummdp_yield_vegter_hingepoint ( a,b,c,mm,nn,iareaflag,
     1                                           s )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: iareaflag
      real*8 ,intent(in) :: a(2),c(2),mm(2),nn(2),s(3)
c
      real*8,intent(out) :: b(2)
c
      real*8 tol,bb,b1u,b2u
c-----------------------------------------------------------------------
c
      tol = 1.0d-8
c
      b1u = mm(2)*(nn(1)*a(1)+nn(2)*a(2))-nn(2)*(mm(1)*c(1)+mm(2)*c(2))
      b2u = nn(1)*(mm(1)*c(1)+mm(2)*c(2))-mm(1)*(nn(1)*a(1)+nn(2)*a(2))
c
      bb = nn(1)*mm(2)-mm(1)*nn(2)
      if ( abs(bb) <= TOL ) then
         write (6,*) 'hingepoint singular error! '
         call ummdp_exit (9000)
      end if
c
      b(1) = b1u / bb
      b(2) = b2u / bb
c
      return
      end subroutine ummdp_yield_vegter_hingepoint
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     FOURIER COEFFICIENT
c
      subroutine ummdp_yield_vegter_mu ( x,a,b,c,mu,iareaflag,s,theta,
     1                                   aa,bb,cc,dd)
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: iareaflag
      real*8 ,intent(in) :: theta
      real*8 ,intent(in) :: x(4),a(2),b(2),c(2),s(3)
c
      real*8,intent(out) :: mu
c
      integer imuflag
      real*8 tol1,tol2,aa,bb,cc,dd
      real*8 xx(2)
c-----------------------------------------------------------------------
c
      tol1 = 1.0d-8
      tol2 = 1.0d-8
c
      aa = x(2)*(a(1)+c(1)-2.0d0*b(1))-x(1)*(a(2)+c(2)-2.0d0*b(2))
      bb = 2.0d0*x(2)*(b(1)-a(1))-2.0d0*x(1)*(b(2)-a(2))
      cc = x(2)*a(1)-x(1)*a(2)
c
      if ( abs(aa) <= tol1 ) then
         write (6,*) 'calc. mu singular error! ',abs(aa),iareaflag
         call ummdp_exit (9000)
      end if
c
      dd = bb*bb - 4.0d0*aa*cc
      if ( dd >= 0.0d0 ) then
        xx(1) = 0.5d0 * (-bb+sign(sqrt(dd),-bb))/aa
        xx(2) = cc / (aa*xx(1))
c
      else
         write (6,*) 'negative dd ! ',dd,iareaflag
         call ummdp_exit (9000)
      end if
c
      if ( xx(1) >= 0.0d0 .and. xx(1) <= 1.0000005d0 ) then
        mu = xx(1)
        imuflag = 1
      else if ( xx(2) >= 0.0d0 .and. xx(2) <= 1.0000005d0 ) then
        mu = xx(2)
        imuflag = 2
      else if ( abs(xx(1) ) <= tol2 .or. abs(xx(2)) <= tol2 ) then
        mu = 0.0d0
      else
        write (6,*) 'can not find mu ! solve error ',iareaflag,xx(1)
     1              ,xx(2)
         call ummdp_exit (9000)
      end if
c
      return
      end subroutine ummdp_yield_vegter_mu
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     NORMALIZED YIELD LOCUS
c
      subroutine ummdp_yield_vegter_fi ( x,a,b,c,mu,f )
c
c-----------------------------------------------------------------------
      implicit none
c
      real*8,intent(in) :: mu
      real*8,intent(in) :: x(4),a(2),b(2),c(2)
c
      real*8,intent(out) :: f(2)
c
      integer i
c-----------------------------------------------------------------------
c
      do i = 1,2
        f(i) = a(i)+ 2.0d0*mu*(b(i)-a(i)) + mu*mu*(a(i)+c(i)-2.0d0*b(i))
      end do
c
      return
      end subroutine ummdp_yield_vegter_fi
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     CAKCULATE dbdc(i) (i=1~2) eq.(A.7)
c
      subroutine ummdp_yield_vegter_dbdc ( a,b,c,dadc,dbdc,dcdc,mm,nn,
     1                                     dndc,dmdc,iareaflag,P,nnmm )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: iareaflag
      real*8 ,intent(in) :: a(2),b(2),c(2),dadc(2),dcdc(2),mm(2),
     1                      nn(2),dndc(2),dmdc(2)
c
      real*8,intent(out) :: nnmm
      real*8,intent(out) :: dbdc(2),P(2)
c
      integer i
      real*8 tol,nminv
c-----------------------------------------------------------------------
c
      tol = 1.0d-8
c
      P(1) = nn(1)*dadc(1) + dndc(1)*(a(1)-b(1)) + nn(2)*dadc(2)
     1       + dndc(2)*(a(2)-b(2))
c
      P(2) = mm(1)*dcdc(1) + dmdc(1)*(c(1)-b(1)) + mm(2)*dcdc(2)
     1       + dmdc(2)*(c(2)-b(2))
c
      nnmm = nn(1)*mm(2) - mm(1)*nn(2)
         if ( abs(nnmm) < tol ) then
            write (6,*) 'nnmm too small! ',nnmm
            call ummdp_exit (9000)
         end if
      nminv = 1.0d0 / nnmm
c
      dbdc(1) = nminv * (P(1)*mm(2)-P(2)*nn(2))
      dbdc(2) = nminv * (P(2)*nn(1)-P(1)*mm(1))
c
      return
      end subroutine ummdp_yield_vegter_dbdc
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     CALCULATE dphidx(i) (i=1~3)  eq.(21)~(23)
c
      subroutine ummdp_yield_vegter_dphidx ( dphidx,se,a,b,c,dadc,dbdc,
     1                                       dcdc,mm,nn,dndc,dmdc,f,
     2                                       iareaflag,mu,x,dfdmu,dfdc )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: iareaflag
      real*8 ,intent(in) :: se
      real*8 ,intent(in) :: a(2),b(2),c(2),dadc(2),dbdc(2),dcdc(2),
     1                      mm(2),nn(2),dndc(2),dmdc(2),f(2),mu,x(4)
c
      real*8,intent(out) :: dphidx(3),dfdmu(2),dfdc(2)
c
      integer i
      real*8 tol1,tol2,tol3,dphidxcoe,dphidxcinv,tmp_u,tmp_b,vtan
      real*8 dphidxtmp(3)
c-----------------------------------------------------------------------
c
      tol1 = 0.996515d0         ! =44.9deg
      tol2 = 1.003497d0         ! =45.1deg
      tol3 = 1.0d-8
c                                    ---- calc. dfdc(i) (i=1~2)  eq.(23)
      do i = 1,2
        dfdc(i) = dadc(i) + 2.0d0*mu*(dbdc(i)-dadc(i)) + mu*mu*(dadc(i)
     1            + dcdc(i)-2.0d0*dbdc(i))
      end do
c
c                                   ---- calc. dfdmu(i) (i=1~2)  eq.(22)
      do i = 1,2
        dfdmu(i) = 2.0d0*(b(i)-a(i)) + 2.0d0*mu*(a(i)+c(i)-2.0d0*b(i))
      end do
c
c                            ---- calc. dphidx(i) (i=1~3)  eq.(21),(C.1)
      dphidxcinv = f(1)*dfdmu(2) - f(2)*dfdmu(1)
      if ( abs(dphidxcinv) < tol3 ) then
        write (6,*) 'eq.(21) too small! ',dphidxcinv
        call ummdp_exit (9000)
      end if
      dphidxcoe = 1.0d0 / dphidxcinv
c
c                            ---- if condition to avoid singular eq.(20)
c                                            ---- apply 44.9 to 45.1 deg
c
      if ( iareaflag == 3 .or. iareaflag == 4) then
        vtan = x(2) / x(1)
      end if
c
      if ( iareaflag == 4 .and. vtan >= tol1 .and. vtan <= tol2 ) then
c
        tmp_u = 1.0d0*(2.0d0*(1.0d0-mu)*dbdc(2)+mu*dcdc(2))*dfdmu(1)
     1          - 1.0d0*(2.0d0*(1.0d0-mu)*dbdc(1)+mu*dcdc(1))*dfdmu(2)
c
        tmp_b = 2.0d0*(1.0d0-mu)*(b(1)-b(2)) + mu*(c(1)-c(2))

        dphidxtmp(1) =  dfdmu(2)
        dphidxtmp(2) = -dfdmu(1)
        dphidxtmp(3) = tmp_u / tmp_b
c
      else if ( iareaflag == 3 .and. vtan >= tol1
     1          .and. vtan <= tol2 ) then
c
        tmp_u = 1.0d0*(2.0d0*mu*dbdc(2)+(1.0d0-mu)*dadc(2))*dfdmu(1)
     1          - 1.0d0*(2.0d0*mu*dbdc(1)+(1.0d0-mu)*dadc(1))*dfdmu(2)
c
        tmp_b = 2.0d0*mu*(b(1)-b(2))+(1.0d0-mu)*(a(1)-a(2))

        dphidxtmp(1) =  dfdmu(2)
        dphidxtmp(2) = -dfdmu(1)
        dphidxtmp(3) = tmp_u / tmp_b
c
      else
c
        dphidxtmp(1) =  dfdmu(2)
        dphidxtmp(2) = -dfdmu(1)
        dphidxtmp(3) = se * (dfdc(2)*dfdmu(1)-dfdc(1)*dfdmu(2))
c
      end if
      do i = 1,3
        dphidx(i) = dphidxcoe * dphidxtmp(i)
      end do
c
      return
      end subroutine ummdp_yield_vegter_dphidx
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     1ST ORDER DERIVATIVE
c
      subroutine ummdp_yield_vegter_dseds ( dseds,x,dphidx,vcos2t,
     1                                      vsin2t,iareaflag,isflag,
     2                                      dxds )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: iareaflag,isflag
      real*8 ,intent(in) :: vcos2t,vsin2t
      real*8 ,intent(in) :: x(4),dphidx(3)
c
      real*8,intent(out) :: dseds(3)
      real*8,intent(out) :: dxds(3,3)
c
      integer i,j
      real*8 tol1,tol2,vtan
      real*8 dxds_t(3,3)
c-----------------------------------------------------------------------
c
      tol1 = 0.996515d0       ! =44.9deg
      tol2 = 1.003497d0       ! =45.1deg
c                  ---- set linear transformation matrix dxds(3,3) eq.18
c
c                            ---- if condition to avoid singular eq.(20)
c                                            ---- apply 44.9 to 45.1 deg
c
      if ( iareaflag == 3 .or. iareaflag == 4 ) then
        vtan = x(2) / x(1)
      end if
c
      if ( iareaflag == 3 .and. vtan >= tol1 .and. vtan <= tol2 ) then
        dxds(1,1) = 0.5d0 * (1.0d0+vcos2t)
        dxds(2,1) = 0.5d0 * (1.0d0-vcos2t)
        dxds(3,1) = vsin2t * vsin2t
        dxds(1,2) = 0.5d0 * (1.0d0-vcos2t)
        dxds(2,2) = 0.5d0 * (1.0d0+vcos2t)
        dxds(3,2) = -vsin2t * vsin2t
        dxds(1,3) =  vsin2t
        dxds(2,3) = -vsin2t
        dxds(3,3) = -2.0d0 * vsin2t * vcos2t
        dxds_t = transpose(dxds)
c
      else if ( iareaflag == 4 .and. vtan >= tol1
     1          .and. vtan <= tol2) then
        dxds(1,1) = 0.5d0 * (1.0d0+vcos2t)
        dxds(2,1) = 0.5d0 * (1.0d0-vcos2t)
        dxds(3,1) = vsin2t * vsin2t
        dxds(1,2) = 0.5d0 * (1.0d0-vcos2t)
        dxds(2,2) = 0.5d0 * (1.0d0+vcos2t)
        dxds(3,2) = -vsin2t * vsin2t
        dxds(1,3) =  vsin2t
        dxds(2,3) = -vsin2t
        dxds(3,3) = -2.0d0 * vsin2t * vcos2t
        dxds_t = transpose(dxds)
c
      else
        dxds(1,1) = 0.5d0 * (1.0d0+vcos2t)
        dxds(2,1) = 0.5d0 * (1.0d0-vcos2t)
        dxds(3,1) = vsin2t * vsin2t / (x(1)-x(2))
        dxds(1,2) = 0.5d0 * (1.0d0-vcos2t)
        dxds(2,2) = 0.5d0 * (1.0d0+vcos2t)
        dxds(3,2) = -vsin2t * vsin2t / (x(1)-x(2))
        dxds(1,3) =  vsin2t
        dxds(2,3) = -vsin2t
        dxds(3,3) = -2.0d0 * vsin2t * vcos2t / (x(1)-x(2))
        dxds_t = transpose(dxds)
      end if
c
c                                   ---- calc. dseds(i) (1=1~3)  eq.(20)
      dseds = 0.0d0
      do i = 1,3
        do j = 1,3
          dseds(i) = dseds(i) + dxds_t(i,j)*dphidx(j)
        end do
      end do
c
      return
      end subroutine ummdp_yield_vegter_dseds
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     CALCULATE d2bdc2(i) (i=1~2)
c
      subroutine ummdp_yield_vegter_d2bdc2 ( a,b,c,dadc,dbdc,dcdc,mm,nn,
     1                                       dndc,dmdc,iareaflag,d2adc2,
     2                                       d2bdc2,d2cdc2,d2ndc2,
     3                                       d2mdc2,P,nnmm,s )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: iareaflag
      real*8 ,intent(in) :: nnmm
      real*8 ,intent(in) :: a(2),b(2),c(2),dadc(2),dcdc(2),mm(2),
     1                      nn(2),dndc(2),dmdc(2),dbdc(2),
     2                      d2adc2(2),d2cdc2(2),d2ndc2(2),d2mdc2(2),
     3                      P(2),s(3)
c
      real*8,intent(out) :: d2bdc2(2)
c
      integer i
      real*8 dnnmmdc,dp1m2p2n2,dp2n1p1m1
      real*8 dPdc(2)
c-----------------------------------------------------------------------
c
      dnnmmdc = dndc(1)*mm(2)+nn(1)*dmdc(2)-dmdc(1)*nn(2)-mm(1)*dndc(2)
c
      dPdc(1) = dndc(1)*dadc(1) + nn(1)*d2adc2(1)
     1          + d2ndc2(1)*(a(1)-b(1)) + dndc(1)*(dadc(1)-dbdc(1))
     2          + dndc(2)*dadc(2) + nn(2)*d2adc2(2)
     2          + d2ndc2(2)*(a(2)-b(2)) + dndc(2)*(dadc(2)-dbdc(2))
c
      dPdc(2) = dmdc(1)*dcdc(1) + mm(1)*d2cdc2(1)
     1          + d2mdc2(1)*(c(1)-b(1)) + dmdc(1)*(dcdc(1)-dbdc(1))
     2          + dmdc(2)*dcdc(2) + mm(2)*d2cdc2(2)
     3          + d2mdc2(2)*(c(2)-b(2)) + dmdc(2)*(dcdc(2)-dbdc(2))
c
      dp1m2p2n2 = dPdc(1)*mm(2) + P(1)*dmdc(2) - dPdc(2)*nn(2)
     1            - P(2)*dndc(2)
      dp2n1p1m1 = dPdc(2)*nn(1) + P(2)*dndc(1) - dPdc(1)*mm(1)
     1            - P(1)*dmdc(1)
c
      d2bdc2(1) = -1.0d0*dnnmmdc*(P(1)*mm(2)-P(2)*nn(2))/(nnmm*nnmm)
     1            + dp1m2p2n2/nnmm
      d2bdc2(2) = -1.0d0*dnnmmdc*(P(2)*nn(1)-P(1)*mm(1))/(nnmm*nnmm)
     2            + dp2n1p1m1/nnmm
c
      return
      end subroutine ummdp_yield_vegter_d2bdc2
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     CALCULATE d2phidx2(k,l) (k,l=1~3)
c
      subroutine ummdp_yield_vegter_d2phidx2 ( d2phidx2,se,a,b,c,dadc,
     1                                         dbdc,dcdc,mm,nn,dndc,
     2                                         dmdc,f,iareaflag,mu,x,
     3                                         d2adc2,d2bdc2,d2cdc2,
     4                                         d2ndc2,d2mdc2,dfdmu,dfdc,
     5                                         s,aa,bb,cc,dd,dphidx )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: iareaflag
      real*8 ,intent(in) :: se,mu,aa,bb,cc,dd
      real*8 ,intent(in) :: a(2),b(2),c(2),dadc(2),dbdc(2),dcdc(2),
     1                      mm(2),nn(2),dndc(2),dmdc(2),f(2),x(4),
     2                      d2adc2(2),d2cdc2(2),d2ndc2(2),d2mdc2(2),
     3                      d2bdc2(2),dfdmu(2),dfdc(2),s(3),dphidx(3)
c
      real*8,intent(out) :: d2phidx2(3,3)
c
      integer i,j
      real*8 vcommon,vtmp1,vtmp2,vtmp3,vtmp4,va,vc
      real*8 daadx(3),dbbdx(3),dccdx(3),ddddx(3),dmudx(3),d2fdmu2(2),
     1       d2fdmudc(2),d2fdcdmu(2),d2fdc2(2),dvadx(3),dsedx(3),
     2       dvcdx(3)
c-----------------------------------------------------------------------
c
c                                           ---- calc.  dmudx(i) (i=1~3)
      daadx(1) = -a(2) - c(2) + 2.0d0*b(2)
      dbbdx(1) = -2.0d0 * (b(2)-a(2))
      dccdx(1) = -a(2)
c
      daadx(2) = a(1) + c(1) - 2.0d0*b(1)
      dbbdx(2) = 2.0d0 * (b(1)-a(1))
      dccdx(2) = a(1)
c
      daadx(3) = x(2)*(dadc(1)+dcdc(1)-2.0d0*dbdc(1))
     1           - x(1)*(dadc(2)+dcdc(2)-2.0d0*dbdc(2))
      dbbdx(3) = 2.0d0*x(2)*(dbdc(1)-dadc(1))
     1           - 2.0d0*x(1)*(dbdc(2)-dadc(2))
      dccdx(3) = x(2)*dadc(1) - x(1)*dadc(2)
c
      do i = 1,3
        dmudx(i) = 0.5d0*daadx(i)*(bb+sqrt(dd))/(aa*aa)
     1          + 0.5d0*(-dbbdx(i)-0.5d0/(sqrt(dd))*(2.0d0*bb*dbbdx(i)
     2             - 4.0d0*daadx(i)*cc-4.0d0*aa*dccdx(i)))/aa
      end do
c
c                                         ---- calc.  d2fdmu2(i) (i=1~2)
      do i = 1,2
        d2fdmu2(i) = 2.0d0 * (a(i)+c(i)-2.0d0*b(i))
      end do
c
c                                        ---- calc.  d2fdmudc(i) (i=1~2)
      do i = 1,2
        d2fdmudc(i) = 2.0d0*(dbdc(i)-dadc(i))
     1                 + 2.0d0*mu*(dadc(i)+dcdc(i)- 2.0d0*dbdc(i))
      end do
c
c                                        ---- calc.  d2fdcdmu(i) (i=1~2)
      do i = 1,2
        d2fdcdmu(i)=2.0d0*(dbdc(i)-dadc(i))+2.0d0*mu*(dadc(i)+dcdc(i)
     1                                             -2.0d0*dbdc(i))
      end do
c
c                                          ---- calc.  d2fdc2(i) (i=1~2)
      do i = 1,2
        d2fdc2(i)=d2adc2(i)+2.0d0*mu*(d2bdc2(i)-d2adc2(i))
     &            +mu*mu*(d2adc2(i)+d2cdc2(i)-2.0d0*d2bdc2(i))
      end do
c
c                                                 ---- for d2phidx2(k,l)
c
      vcommon = 1.0d0/(f(1)*dfdmu(2)-f(2)*dfdmu(1))
      vtmp1 = dfdc(1)*dfdmu(2)+f(1)*d2fdmudc(2)
     &                           -dfdc(2)*dfdmu(1)-f(2)*d2fdmudc(1)
      vtmp2 = dfdmu(1)*dfdmu(2)+f(1)*d2fdmu2(2)
     &                           -dfdmu(2)*dfdmu(1)-f(2)*d2fdmu2(1)
      vtmp3 = d2fdcdmu(2)*dfdmu(1)+dfdc(2)*d2fdmu2(1)
     &                     -d2fdcdmu(1)*dfdmu(2)-dfdc(1)*d2fdmu2(2)
      vtmp4 = d2fdc2(2)*dfdmu(1)+dfdc(2)*d2fdmudc(1)
     &                      -d2fdc2(1)*dfdmu(2)-dfdc(1)*d2fdmudc(2)
c
      va=vcommon
      vc=dfdc(2)*dfdmu(1)-dfdc(1)*dfdmu(2)
c
      do i=1,2
        dvadx(i)=-vtmp2*vcommon*vcommon*dmudx(i)
      end do
        dvadx(3)=-vtmp1*vcommon*vcommon
     &           -vtmp2*vcommon*vcommon*dmudx(3)
c
      do i=1,3
        dsedx(i)=dphidx(i)
      end do
c
      do i=1,2
        dvcdx(i)=vtmp3*dmudx(i)
      end do
        dvcdx(3)=vtmp4+vtmp3*dmudx(3)
c
c                                    ---- calc.  d2phidx2(i,j) (i,j=1~3)
      do j=1,2
        d2phidx2(1,j)=(-dfdmu(2)*vtmp2*vcommon*vcommon
     &                             +d2fdmu2(2)*vcommon)*dmudx(j)
      end do
        d2phidx2(1,3)=-dfdmu(2)*vtmp1*vcommon*vcommon
     &                +d2fdmudc(2)*vcommon+(-dfdmu(2)*vtmp2
     &                  *vcommon*vcommon+d2fdmu2(2)*vcommon)*dmudx(3)
c
      do j=1,2
        d2phidx2(2,j)=(dfdmu(1)*vtmp2*vcommon*vcommon
     &                             -d2fdmu2(1)*vcommon)*dmudx(j)
      end do
        d2phidx2(2,3)=dfdmu(1)*vtmp1*vcommon*vcommon
     &                -d2fdmudc(1)*vcommon+(dfdmu(1)*vtmp2
     &                  *vcommon*vcommon-d2fdmu2(1)*vcommon)*dmudx(3)
c
      do j=1,3
        d2phidx2(3,j)=dvadx(j)*se*vc+va*dsedx(j)*vc+va*se*dvcdx(j)
      end do
c
      return
      end subroutine ummdp_yield_vegter_d2phidx2
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     2ND ORDER DERIVATIVES
c
      subroutine ummdp_yield_vegter_d2seds2 ( d2seds2,d2phidx2,se,a,b,c,
     1                                        mu,x,vcos2t,vsin2t,
     2                                        iareaflag,dxds,dphidx,
     3                                        isflag,s,dseds,pryld,
     4                                        ndyld )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: iareaflag,isflag,ndyld
      real*8 ,intent(in) :: se,mu,vcos2t,vsin2t
      real*8 ,intent(in) :: a(2),b(2),c(2),x(4),dphidx(3),s(3),
     1                       dseds(3),pryld(ndyld)
      real*8 ,intent(in) :: d2phidx2(3,3),dxds(3,3)
c
      real*8,intent(out) :: d2seds2(3,3)
c
      integer i,j,k,l,iflag
      real*8 tol1,tol2,tol3a,tol3b,tol4,tol4a,tol4b,vtan,vx1x2
      real*8 d2xds2(3,3,3)
c-----------------------------------------------------------------------
c
      tol1 = 0.996515d0          ! =44.9deg
      tol2 = 1.003497d0          ! =45.1deg
      tol3a = 1.0d-6
      tol3b = 1.0d0 - tol3a
      tol4 = 1.0d-7
      tol4a = 1.0d0 - tol4       !thera<0.012812deg
      tol4b = - 1.0d0 + tol4     !thera>89.98719deg
c                             ---- if condition to apply numerical diff.
c
      if(iareaflag==3.or.iareaflag==4) then
      vtan=x(2)/x(1)
      end if
c
      if(iareaflag==4.and.vtan>=TOL1.and.vtan<=TOL2) then
      iflag=1
c
      else if(iareaflag==3.and.vtan>=TOL1.and.vtan<=TOL2) then
      iflag=2
c
      else if(abs(mu)<=TOL3a.or.abs(mu)>=TOL3b) then
      iflag=3
c
      else if(vcos2t>=TOL4a.or.vcos2t<=TOL4b) then
      iflag=4
c
      else
      vx1x2=x(1)-x(2)
      iflag=0
      end if
c
c                                    ---- set d2xds2(k,i,j)  (k,i,j=1~3)
c
      if (iflag==0) then
c
      d2xds2(1,1,1)=0.5d0*(1.0d0-vcos2t*vcos2t)/vx1x2
      d2xds2(1,1,2)=0.5d0*(vcos2t*vcos2t-1.0d0)/vx1x2
      d2xds2(1,1,3)=-vcos2t*vsin2t/vx1x2
c
      d2xds2(1,2,1)=0.5d0*(vcos2t*vcos2t-1.0d0)/vx1x2
      d2xds2(1,2,2)=0.5d0*(1-vcos2t*vcos2t)/vx1x2
      d2xds2(1,2,3)=vcos2t*vsin2t/vx1x2
c
      d2xds2(1,3,1)=-vcos2t*vsin2t/vx1x2
      d2xds2(1,3,2)=vcos2t*vsin2t/vx1x2
      d2xds2(1,3,3)=-2.0d0*(vsin2t*vsin2t-1.0d0)/vx1x2
c
      d2xds2(2,1,1)=0.5d0*(vcos2t*vcos2t-1.0d0)/vx1x2
      d2xds2(2,1,2)=0.5d0*(1.0d0-vcos2t*vcos2t)/vx1x2
      d2xds2(2,1,3)=vcos2t*vsin2t/vx1x2
c
      d2xds2(2,2,1)=0.5d0*(1.0d0-vcos2t*vcos2t)/vx1x2
      d2xds2(2,2,2)=0.5d0*(vcos2t*vcos2t-1.0d0)/vx1x2
      d2xds2(2,2,3)=-vcos2t*vsin2t/vx1x2
c
      d2xds2(2,3,1)=vcos2t*vsin2t/vx1x2
      d2xds2(2,3,2)=-vcos2t*vsin2t/vx1x2
      d2xds2(2,3,3)=2.0d0*(vsin2t*vsin2t-1.0d0)/vx1x2
c
      d2xds2(3,1,1)=-3.0d0*vcos2t*vsin2t*vsin2t/(vx1x2*vx1x2)
      d2xds2(3,1,2)=3.0d0*vcos2t*vsin2t*vsin2t/(vx1x2*vx1x2)
      d2xds2(3,1,3)=2.0d0*vsin2t*(2.0d0-3.0d0*vsin2t*vsin2t)/
     1                                           (vx1x2*vx1x2)
c
      d2xds2(3,2,1)=3.0d0*vcos2t*vsin2t*vsin2t/(vx1x2*vx1x2)
      d2xds2(3,2,2)=-3.0d0*vcos2t*vsin2t*vsin2t/(vx1x2*vx1x2)
      d2xds2(3,2,3)=-2.0d0*vsin2t*(2.0d0-3.0d0*vsin2t*vsin2t)/
     1                                           (vx1x2*vx1x2)
c
      d2xds2(3,3,1)=2.0d0*vsin2t*(3.0d0*vcos2t*vcos2t-1.0d0)/
     1                                           (vx1x2*vx1x2)
      d2xds2(3,3,2)=-2.0d0*vsin2t*(3.0d0*vcos2t*vcos2t-1.0d0)/
     1                                           (vx1x2*vx1x2)
      d2xds2(3,3,3)=4.0d0*vcos2t*(3.0d0*vsin2t*vsin2t-1.0d0)/
     1                                           (vx1x2*vx1x2)
      end if
c
c                                      ---- calc. d2seds2(i,j) (i,j=1~3)
c
      d2seds2 = 0.0d0
c
      if (iflag/=0) then
        call ummdp_yield_vegter_d2seds2n ( d2seds2,s,dseds,pryld,ndyld,
     1                                     se )
c
      else
        do i=1,3
          do j=1,3
            do k=1,3
              do l=1,3
                d2seds2(i,j) = d2seds2(i,j)
     1                         + d2phidx2(k,l)*dxds(l,j)*dxds(k,i)
              end do
              d2seds2(i,j) = d2seds2(i,j)
     1                       + dphidx(k)*d2xds2(k,i,j)
            end do
          end do
        end do
      end if
c
      return
      end subroutine ummdp_yield_vegter_d2seds2
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     NUMERICAL DIFFERENTIATION FOR 2ND ORDER DERIVATIVES
c
      subroutine ummdp_yield_vegter_d2seds2n ( d2seds2,s,dseds,pryld,
     1                                         ndyld,se )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: ndyld
      real*8 ,intent(in) :: se
      real*8 ,intent(in) :: dseds(3),pryld(ndyld),s(3)
c
      real*8,intent(out) :: d2seds2(3,3)
c
      integer j,k
      real*8 delta,sea,seb,a,b,seba,seaa,sebb,seab,se0
      real*8 s0(3),ss(3)
c-----------------------------------------------------------------------
c
      delta = 1.0d-3
c
      s0(:) = s(:)
      ss(:) = s(:)
      do j=1,3
        do k=1,3
          if ( j==k ) then
            se0=se
            ss(j)=s0(j)-delta
            call ummdp_yield_vegter_yieldfunc ( 3,ss,sea,dseds,d2seds2,
     1                                          0,pryld,ndyld )
            ss(j)=s0(j)+delta
            call ummdp_yield_vegter_yieldfunc ( 3,ss,seb,dseds,d2seds2,
     1                                          0,pryld,ndyld )
            ss(j)=s0(j)
            a=(se0-sea)/delta
            b=(seb-se0)/delta
            d2seds2(j,k)=(b-a)/delta
          else
            ss(j)=s0(j)-delta
            ss(k)=s0(k)-delta
            call ummdp_yield_vegter_yieldfunc ( 3,ss,seaa,dseds,d2seds2,
     1                                         0,pryld,ndyld )
            ss(j)=s0(j)+delta
            ss(k)=s0(k)-delta
            call ummdp_yield_vegter_yieldfunc ( 3,ss,seba,dseds,d2seds2,
     1                                          0,pryld,ndyld )
            ss(j)=s0(j)-delta
            ss(k)=s0(k)+delta
            call ummdp_yield_vegter_yieldfunc ( 3,ss,seab,dseds,d2seds2,
     1                                          0,pryld,ndyld )
            ss(j)=s0(j)+delta
            ss(k)=s0(k)+delta
            call ummdp_yield_vegter_yieldfunc ( 3,ss,sebb,dseds,d2seds2,
     1                                          0,pryld,ndyld )
            ss(j)=s0(j)
            ss(k)=s0(k)
            a=(seba-seaa)/(2.0d0*delta)
            b=(sebb-seab)/(2.0d0*delta)
            d2seds2(j,k)=(b-a)/(2.0d0*delta)
          end if
        end do
      end do
c
      return
      end subroutine ummdp_yield_vegter_d2seds2n
c
c
c
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c     EQUIVALENT STRESS FOR NUMERICAL DIFFERENTIATION
c
      subroutine ummdp_yield_vegter_yieldfunc ( nttl,s,se,dseds,d2seds2,
     1                                          nreq,pryld,ndyld )
c
c-----------------------------------------------------------------------
      implicit none
c
      integer,intent(in) :: nttl,nreq,ndyld
      real*8 ,intent(in) :: s(3),pryld(ndyld)
c
      real*8,intent(out) :: se
      real*8,intent(out) :: dseds(3)
      real*8,intent(out) :: d2seds2(3,3)
c-----------------------------------------------------------------------
c
      call ummdp_yield_vegter ( s,se,dseds,d2seds2,nreq,pryld,ndyld )
c
      return
      end subroutine ummdp_yield_vegter_yieldfunc
c
c
c