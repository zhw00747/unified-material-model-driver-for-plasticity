c*************************************************************
c     JANCAE/UMMDp : Kinematic Hardening Functions 
c*************************************************************
c-------------------------------------------------------------
c     calc. kinematic hardening function
c
      subroutine jancae_kinematic ( vk,dvkdp,
     &                              dvkds,dvkdx,dvkdxt,
     &                              p,s,x,xt,
     &                              nttl,nnrm,nshr,
     &                              mxpbs,npbs,
     &                              prkin,ndkin,
     &                              pryld,ndyld )
c-------------------------------------------------------------
      implicit real*8 (a-h,o-z)
      dimension vk(    npbs,nttl),
     &          dvkdp( npbs,nttl),
     &          dvkdx( npbs,npbs,nttl,nttl),
     &          dvkds( npbs,nttl,nttl),
     &          dvkdxt(npbs,nttl,nttl),
     &          s(nttl),x(mxpbs,nttl),xt(nttl),
     &          prkin(ndkin),pryld(ndyld)
c
c
      ntkin=nint(prkin(1))
c                                   --- initialize
      do i=1,npbs
        do j=1,nttl
          vk(  i,j)=0.0
          dvkdp(i,j)=0.0
          do k=1,nttl
            dvkds( i,j,k)=0.0
            dvkdxt(i,j,k)=0.0
            do l=1,npbs
              dvkdx( i,l,j,k)=0.0
            enddo
          enddo
        enddo
      enddo

c
      select case ( ntkin )
c
      case ( 0 )                   ! no kinematic hardening
        return
c
      case ( 1 )                   ! Prager 
        call jancae_kin_prager    ( vk,dvkdp,
     &                              dvkds,dvkdx,dvkdxt,
     &                              p,s,x,xt,
     &                              nttl,nnrm,nshr,
     &                              mxpbs,npbs,
     &                              prkin,ndkin,pryld,ndyld )
c
      case ( 2 )                   ! Ziegrer 
        call jancae_kin_ziegler   ( vk,dvkdp,
     &                              dvkds,dvkdx,dvkdxt,
     &                              p,s,x,xt,
     &                              nttl,nnrm,nshr,
     &                              mxpbs,npbs,
     &                              prkin,ndkin,pryld,ndyld )
c
      case ( 3 )                   ! Armstrong & Frederic 
        call jancae_kin_armstrong ( vk,dvkdp,
     &                              dvkds,dvkdx,dvkdxt,
     &                              p,s,x,xt,
     &                              nttl,nnrm,nshr,
     &                              mxpbs,npbs,
     &                              prkin,ndkin,pryld,ndyld )
c
      case ( 4 )                   ! Chaboche(1979) 
        call jancae_kin_chaboche1979 ( vk,dvkdp,
     &                              dvkds,dvkdx,dvkdxt,
     &                              p,s,x,xt,
     &                              nttl,nnrm,nshr,
     &                              mxpbs,npbs,
     &                              prkin,ndkin,pryld,ndyld )
c
      case ( 5 )                   ! Yoshida-Uemori
        call jancae_kin_yoshida_uemori ( vk,dvkdp,
     &                              dvkds,dvkdx,dvkdxt,
     &                              p,s,x,xt,
     &                              nttl,nnrm,nshr,
     &                              mxpbs,npbs,
     &                              prkin,ndkin,pryld,ndyld )
c
      case default
        write (6,*) 'still not be supported. ntkin=',ntkin
        call jancae_exit ( 9000 )
      end select
c
      return
      end
c
c
c-------------------------------------------------------------
c     dseds and d2seds2 for kinematic hardening
c
      subroutine jancae_dseds_kin ( eta,seta,dseds,d2seds2,
     &                              nttl,nnrm,nshr,
     &                              pryld,ndyld )
c-------------------------------------------------------------
      implicit real*8 (a-h,o-z)
      dimension eta(nttl),
     &          dseds(nttl),d2seds2(nttl,nttl),
     &          pryld(ndyld)
c
c
c               ---- dseds and d2seds2 for plastic strain inc.
      call jancae_yfunc  ( seta,dseds,d2seds2,2,
     &                     eta,nttl,nnrm,nshr,
     &                     pryld,ndyld )
c
c        ---- engineering shear strain -> tensor shear strain
      do i=nnrm+1,nttl
        dseds(i)=0.5d0*dseds(i)
        do j=1,nttl
          d2seds2(i,j)=0.5d0*d2seds2(i,j)
        enddo
      enddo
c                               ---- for plane stress problem
      if ( nnrm.eq.2 ) then
        em1 =        dseds(1)
        em2 =        dseds(2)
        dseds(1)=    dseds(1)    +em1 +em2
        dseds(2)=    dseds(2)    +em2 +em1
        en11=        d2seds2(1,1)
        en12=        d2seds2(1,2)
        en13=        d2seds2(1,3)
        en21=        d2seds2(2,1)
        en22=        d2seds2(2,2)
        en23=        d2seds2(2,3)
        d2seds2(1,1)=d2seds2(1,1)+en11+en21
        d2seds2(1,2)=d2seds2(1,2)+en12+en22
        d2seds2(1,3)=d2seds2(1,3)+en13+en23
        d2seds2(2,1)=d2seds2(2,1)+en21+en11
        d2seds2(2,2)=d2seds2(2,2)+en22+en12
        d2seds2(2,3)=d2seds2(2,3)+en23+en13
      endif
c
      return
      end
c
c
c
c------------------------------------------------------------
c     print parameters for kinematic hardening 
c
      subroutine jancae_kinematic_print ( prkin,ndkin,npbs )
c------------------------------------------------------------
      implicit real*8 (a-h,o-z)
      dimension prkin(ndkin)
c
      ntkin=nint(prkin(1))
      write (6,*) '*** kinematic hardening',ntkin
      select case ( ntkin )
      case ( 0 )
        write (6,*) 'no kinematic hardening'
      case ( 1 )
        write (6,*) 'Prager dX=(2/3)*c*{dpe}'
        write (6,*) 'c =',prkin(1+1)
      case ( 2 )
        write (6,*) 'Zieger dX=dp*c*{{s}-{X}}'
        write (6,*) 'c =',prkin(1+1)
      case ( 3 )
        write (6,*) 'Armstrog-Frederick'
        write (6,*) 'dX=(2/3)*c*{dpe}-dp*g*{X}'
        write (6,*) 'c =',prkin(1+1)
        write (6,*) 'g =',prkin(1+2)
      case ( 4 )
        write (6,*) 'Chaboche 1979'
        write (6,*) 'dx(j)=c(j)*(2/3)*{dpe}-dp*g(j)*{x(j)}'
        write (6,*) 'no. of x(j) =',npbs
        do i=1,npbs
          n0=(i-1)*2
          write (6,*) 'c(',i,')=',prkin(1+n0+1)
          write (6,*) 'g(',i,')=',prkin(1+n0+2)
        enddo
      case ( 5 )
        write (6,*) 'Yoshida-Uemori'
        write (6,*) 'no. of x(j) =',npbs
        write (6,*) 'C=',prkin(1+1)
        write (6,*) 'Y=',prkin(1+2)
        write (6,*) 'a=',prkin(1+3)
        write (6,*) 'k=',prkin(1+4)
        write (6,*) 'b=',prkin(1+5)
      end select
c
      return
      end
c
c
c-------------------------------------------------------------
c     Prager
c
      subroutine jancae_kin_prager ( vk,dvkdp,
     &                               dvkds,dvkdx,dvkdxt,
     &                               p,s,x,xt,
     &                               nttl,nnrm,nshr,
     &                               mxpbs,npbs,
     &                               prkin,ndkin,
     &                               pryld,ndyld )
c-------------------------------------------------------------
      implicit real*8 (a-h,o-z)
      dimension vk(    npbs,nttl),
     &          dvkdp( npbs,nttl),
     &          dvkdx( npbs,npbs,nttl,nttl),
     &          dvkds( npbs,nttl,nttl),
     &          dvkdxt(npbs,nttl,nttl),
     &          s(nttl),x(mxpbs,nttl),xt(nttl),
     &          prkin(ndkin),pryld(ndyld)
c
      dimension eta(nttl),dseds(nttl),d2seds2(nttl,nttl)
c
      c=prkin(2)/3.0d0*2.0d0
c
      do i=1,nttl
        eta(i)=s(i)-xt(i)
      enddo
c
      call jancae_dseds_kin ( eta,seta,dseds,d2seds2,
     &                        nttl,nnrm,nshr,
     &                        pryld,ndyld )
c
      n=1
c
      do i=1,nttl
        vk(n,i)=c*dseds(i)
      enddo
c
      dcdp=0.0d0
      do i=1,nttl
        dvkdp(n,i)=dcdp*dseds(i)
      enddo
c
      do i=1,nttl
        do j=1,nttl
          dvkds( n,  i,j)= c*d2seds2(i,j)
          dvkdx( n,n,i,j)=-c*d2seds2(i,j)
          dvkdxt(n,  i,j)= 0.0
        enddo
      enddo
c
      return
      end
c
c
c
c-------------------------------------------------------------
c     Ziegler
c
      subroutine jancae_kin_ziegler ( vk,dvkdp,
     &                                dvkds,dvkdx,dvkdxt,
     &                                p,s,x,xt,
     &                                nttl,nnrm,nshr,
     &                                mxpbs,npbs,
     &                                prkin,ndkin,
     &                                pryld,ndyld )
c-------------------------------------------------------------
      implicit real*8 (a-h,o-z)
      dimension vk(    npbs,nttl),
     &          dvkdp( npbs,nttl),
     &          dvkdx( npbs,npbs,nttl,nttl),
     &          dvkds( npbs,nttl,nttl),
     &          dvkdxt(npbs,nttl,nttl),
     &          s(nttl),x(mxpbs,nttl),xt(nttl),
     &          prkin(ndkin),pryld(ndyld)
c
      dimension eta(nttl),am(nttl,nttl)
c
      c=prkin(2)
c
      do i=1,nttl
        eta(i)=s(i)-xt(i)
      enddo
c
      n=1
      do i=1,nttl
        vk(n,i)=c*eta(i)
      enddo
c
      dcdp=0.0
      do i=1,nttl
        dvkdp(n,i)=dcdp*eta(i)
      enddo
c
      call jancae_setunitm ( am,nttl )
      do i=1,nttl
        do j=1,nttl
          dvkds( n,  i,j)= c*am(i,j)
          dvkdx( n,n,i,j)=-c*am(i,j)
          dvkdxt(n,  i,j)= 0.0
        enddo
      enddo
c
      return
      end
c
c
c
c-------------------------------------------------------------
c     Armstrong-Frederick
c
      subroutine jancae_kin_armstrong ( vk,dvkdp,
     &                                  dvkds,dvkdx,dvkdxt,
     &                                  p,s,x,xt,
     &                                  nttl,nnrm,nshr,
     &                                  mxpbs,npbs,
     &                                  prkin,ndkin,
     &                                  pryld,ndyld )
c-------------------------------------------------------------
      implicit real*8 (a-h,o-z)
      dimension vk(    npbs,nttl),
     &          dvkdp( npbs,nttl),
     &          dvkdx( npbs,npbs,nttl,nttl),
     &          dvkds( npbs,nttl,nttl),
     &          dvkdxt(npbs,nttl,nttl),
     &          s(nttl),x(mxpbs,nttl),xt(nttl),
     &          prkin(ndkin),pryld(ndyld)
c
      dimension eta(nttl),dseds(nttl),d2seds2(nttl,nttl),
     &          am(nttl,nttl)
c
      c=prkin(1+1)/3.0d0*2.0d0
      g=prkin(1+2)
c
      do i=1,nttl
        eta(i)=s(i)-xt(i)
      enddo
c
      call jancae_dseds_kin ( eta,seta,dseds,d2seds2,
     &                        nttl,nnrm,nshr,
     &                        pryld,ndyld )
c
c
      n=1
      do i=1,nttl
        vk(n,i)=c*dseds(i)-g*xt(i)
      enddo
c
      dcdp=0.0d0
      dgdp=0.0d0
      do i=1,nttl
        dvkdp(n,i)=dcdp*dseds(i)-dgdp*xt(i)
      enddo
c
      call jancae_setunitm ( am,nttl )
      do i=1,nttl
        do j=1,nttl
          dvkds( n,  i,j)= c*d2seds2(i,j)
          dvkdx( n,n,i,j)=-c*d2seds2(i,j)-g*am(i,j)
          dvkdxt(n,  i,j)= 0.0
        enddo
      enddo
c
      return
      end
c
c
c
c-------------------------------------------------------------
c     Chaboche(1979)
c
      subroutine jancae_kin_chaboche1979 ( vk,dvkdp,
     &                                     dvkds,dvkdx,dvkdxt,
     &                                     p,s,x,xt,
     &                                     nttl,nnrm,nshr,
     &                                     mxpbs,npbs,
     &                                     prkin,ndkin,
     &                                     pryld,ndyld )
c-------------------------------------------------------------
      implicit real*8 (a-h,o-z)
      dimension vk(    npbs,nttl),
     &          dvkdp( npbs,nttl),
     &          dvkdx( npbs,npbs,nttl,nttl),
     &          dvkds( npbs,nttl,nttl),
     &          dvkdxt(npbs,nttl,nttl),
     &          s(nttl),x(mxpbs,nttl),xt(nttl),
     &          prkin(ndkin),pryld(ndyld)
c
      dimension eta(nttl),dseds(nttl),d2seds2(nttl,nttl),
     &          am(nttl,nttl)
c
      do i=1,nttl
        eta(i)=s(i)-xt(i)
      enddo
c
      call jancae_dseds_kin ( eta,seta,dseds,d2seds2,
     &                        nttl,nnrm,nshr,
     &                        pryld,ndyld )
c
      call jancae_setunitm ( am,nttl )
      do n=1,npbs
        n0=(n-1)*2
        c=prkin(1+n0+1)/3.0d0*2.0d0
        g=prkin(1+n0+2)
        do i=1,nttl
          vk(n,i)=c*dseds(i)-g*x(n,i)
        enddo
        dcdp=0.0d0
        dgdp=0.0d0
        do i=1,nttl
          dvkdp(n,i)=dcdp*dseds(i)-dgdp*x(n,i)
        enddo
        do i=1,nttl
          do j=1,nttl
            dvkds( n,  i,j)= c*d2seds2(i,j)
            dvkdx( n,n,i,j)=-g*am(i,j)
            dvkdxt(n,  i,j)=-c*d2seds2(i,j)
          enddo
        enddo
      enddo
c
      return
      end
c
c
c
c-------------------------------------------------------------
c     Yoshida_Uemori (***)
c
      subroutine jancae_kin_yoshida_uemori ( vk,dvkdp,
     &                                     dvkds,dvkdx,dvkdxt,
     &                                     p,s,x,xt,
     &                                     nttl,nnrm,nshr,
     &                                     mxpbs,npbs,
     &                                     prkin,ndkin,
     &                                     pryld,ndyld )
c-------------------------------------------------------------
      implicit real*8 (a-h,o-z)
      dimension vk(    npbs,nttl),
     &          dvkdp( npbs,nttl),
     &          dvkdx( npbs,npbs,nttl,nttl),
     &          dvkds( npbs,nttl,nttl),
     &          dvkdxt(npbs,nttl,nttl),
     &          s(nttl),x(mxpbs,nttl),xt(nttl),
     &          prkin(ndkin),pryld(ndyld)
c
      dimension eta(nttl),dseds(nttl),d2seds2(nttl,nttl),
     &          am(nttl,nttl)
c
      pc=prkin(1+1)  ! C
      py=prkin(1+2)  ! Y
      pa=prkin(1+3)  ! a
      pk=prkin(1+4)  ! k
      pb=prkin(1+5)  ! b
c
      do i=1,nttl
        eta(i)=s(i)-xt(i)
      enddo
c
      call jancae_dseds_kin ( eta,seta,dseds,d2seds2,
     &                        nttl,nnrm,nshr,
     &                        pryld,ndyld )
      call jancae_setunitm ( am,nttl )
c
      n=1
      do i=1,nttl
        vk(n,i)=pc*( (pa/py)*eta(i) - sqrt(pa/seta)*x(n,i) )
      enddo      
      do i=1,nttl
        dvkdp(n,i)=0.0
      enddo
      do i=1,nttl
        do j=1,nttl
          dvkds( n,  i,j)= pc*pa/py*am(i,j)
          dvkdxt(n,  i,j)=-pc*pa/py*am(i,j)
          dvkdx( n,n,i,j)= pc*sqrt(pa)*
     &                    ( -am(i,j)/sqrt(seta)
     &                      +x(n,i)*dseds(j)/(2.0d0*seta**(1.5d0)) )
        enddo
      enddo
c
      n=2
      do i=1,nttl
        vk(n,i)=pk*( 2.0d0/3.0d0*pb*dseds(i)-x(n,i) )
      enddo
      do i=1,nttl
        dvkdp(n,i)=0.0
      enddo
      do i=1,nttl
        do j=1,nttl
          dvkds( n,  i,j)= 2.0d0/3.0d0*pb+pk*d2seds2(i,j)
          dvkdxt(n,  i,j)=-2.0d0/3.0d0*pb+pk*d2seds2(i,j)
          dvkdx( n,n,i,j)= -pk*am(i,j)
        enddo
      enddo
c
      return
      end
c
c
c
