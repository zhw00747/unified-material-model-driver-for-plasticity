c***********************************************************************
c
c     UMMDp : Uncoupled Rupture Criteria
c
c**********************************************************************
c
c      0 : No Rupture Criterion
c
c      1 : Equivalent Plastic Strain
c      2 : Cockroft and Latham
c      3 : Rice and Tracey
c      4 : Ayada
c      5 : Brozzo
c
c-----------------------------------------------------------------------
c     calculated rupture criteria
c
      subroutine jancae_rupture ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,jmac,
     &                            jmatyp,matlayo,laccfla,nt,
     &                            ndrup,prrup )
c
c-----------------------------------------------------------------------
      implicit real*8 (a-h,o-z)
c
      dimension UVAR1(NUVARM),JMAC(*),JMATYP(*)
      dimension sdv(nsdv),uvar2(nuvarm),prrup(ndrup)
			real*8 lim,wlimnorm
c-----------------------------------------------------------------------
c
c      prrup(1) : criteria id
c      prrup(2) : flag to terminate analysis if limit is reached
c      prrup(3) : rupture limit
c
c 																		       ---- rupture criteria limit
			lim = prrup(3)
c                                           ---- select rupture criteria
			ntrup = nint(prrup(1))
      select case ( ntrup )
c
      case ( 0 )                                  ! No Rupture Criterion
        return
c
      case ( 1 )                             ! Equivalent Plastic Strain
        call jancae_rup_eqstrain ( sdv,nsdv,uvar2,uvar1,nuvarm,nt,
     &                             lim,wlimnorm )
c
      case ( 2 )                                   ! Cockroft and Latham
        call jancae_rup_cockroft ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,
     &                             jmac,jmatyp,matlayo,laccfla,nt,
     &                             lim,wlimnorm )
c
      case ( 3 )                                       ! Rice and Tracey
        call jancae_rup_rice ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,
     &                         jmac,jmatyp,matlayo,laccfla,nt,
     &                         lim,wlimnorm )
c
      case ( 4 )                                                 ! Ayada
        call jancae_rup_ayada ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,
     &                          jmac,jmatyp,matlayo,laccfla,nt,
     &                          lim,wlimnorm )
c
      case ( 5 )                                                ! Brozzo
        call jancae_rup_brozzo ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,
     &                           jmac,jmatyp,matlayo,laccfla,nt,
     &                           lim,wlimnorm )
c
      case default
        write (6,*) 'error in jancae_rupture'
        write (6,*) 'ntrup error :',ntrup
        call jancae_exit ( 9000 )
      end select
c
c                    ---- terminate analysis if rupture limit is reached
			end = nint(prrup(2))
			if ( end .eq. 1 ) then
				if ( wlimnorm .ge. 1.0d0 ) call jancae_exit( 10000 )
			end if
c
      return
      end
c
c
c
c-----------------------------------------------------------------------
c     print parameters for uncoupled rupture criteria
c
      subroutine jancae_rupture_print ( prrup,ndrup )
c
c-----------------------------------------------------------------------
      implicit real*8 (a-h,o-z)
c
      dimension prrup(ndrup)
c-----------------------------------------------------------------------
c
      ntrup = nint(prrup(1))
      write (6,*)
      write (6,*) '*** Uncoupled Rupture Criterion',ntrup
      select case ( ntrup )
c
      case ( 0 ) 										   	! No Uncoupled Rupture Criterion
        write (6,*) 'No Uncoupled Rupture Criterion'
c
      case ( 1 ) 														 ! Equivalent Plastic Strain
        write (6,*) 'Equivalent Plastic Strain'
        write (6,*) 'W=int[dp]'
				write (6,*) 'Wl=',prrup(3)
c
      case ( 2 )  																 ! Cockroft and Latham
        write (6,*) 'Cockroft and Latham'
        write (6,*) 'W=int[(sp1/se)*dp]'
				write (6,*) 'Wl=',prrup(3)
c
      case ( 3 ) 																	     ! Rice and Tracey
        write (6,*) 'Rice and Tracey'
        write (6,*) 'W=int[exp(1.5*sh/se)*dp]'
				write (6,*) 'Wl=',prrup(3)
c
      case ( 4 ) 																						     ! Ayada
        write (6,*) 'Ayada'
        write (6,*) 'W=int[(sh/se)*dp]'
				write (6,*) 'Wl=',prrup(3)

      case ( 5 ) 																							  ! Brozzo
        write (6,*) 'Brozzo'
        write (6,*) 'W=int[(2/3)*(sp1/(sp1-se))*dp]'
				write (6,*) 'Wl=',prrup(3)
      end select
c
      return
      end
c
c
c
c-----------------------------------------------------------------------
c     Equivalent Plastic Strain
c
      subroutine jancae_rup_eqstrain ( sdv,nsdv,uvar2,uvar1,nuvarm,nt,
     &                                 lim,wlimnorm )
c
c-----------------------------------------------------------------------
      implicit real*8 (a-h,o-z)
c
      dimension sdv(nsdv),uvar2(nuvarm),uvar1(nuvarm)
      real*8 lim,peeq
c-----------------------------------------------------------------------
c
c     nuvarm : 2
c
c     uvar(2+nt+1) : equivalent plastic strain
c     uvar(2+nt+2) : rupture criterion normalised
c
c                                            ---- get uvar before update
      wlimnorm  = uvar1(2+nt+2)
c
c                                              ---- get sdv after update
      peeq = sdv(1)
c
c                                                       ---- update uvar
      uvar2(2+nt+1) = peeq
      uvar2(2+nt+2) = peeq / lim
c
      return
      end
c
c
c
c-----------------------------------------------------------------------
c     Cockroft and Latham
c
      subroutine jancae_rup_cockroft ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,
     &                                 jmac,jmatyp,matlayo,laccfla,nt,
     &                                 lim,wlimnorm )
c
c-----------------------------------------------------------------------
      implicit real*8 (a-h,o-z)
c
      dimension UVAR1(NUVARM),JMAC(*),JMATYP(*)
      dimension ARRAY(15),JARRAY(15)
      dimension sdv(nsdv),uvar2(nuvarm)
      character*3 FLGRAY(15)
      real*8 lim,wlimnorm
      real*8 se1,peeq1,maxsp1,maxsp1se1,wlim1
      real*8 se2,peeq2,maxsp2,maxsp2se2,wlim2
c-----------------------------------------------------------------------
c
c     nuvarm : 4
c
c     uvar(1)      : equivalent stress
c     uvar(2+nt+1) : equivalent plastic strain
c     uvar(2+nt+2) : maximum principal stress
c     uvar(2+nt+3) : rupture criterion
c     uvar(2+nt+4) : rupture criterion normalised
c
c                                            ---- get uvar before update
      se1    = uvar1(1)
      peeq1  = uvar1(2+nt+1)
      maxsp1 = uvar1(2+nt+2)
      wlim1  = uvar1(2+nt+3)
c
			wlimnorm  = uvar1(2+nt+4)
c
c                                     ---- get sdv and uvar after update
      se2 = uvar2(1)
      peeq2 = sdv(1)
c
c                                 ---- get principal stress after update
      call getvrm ('SP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,JMATYP,
     &                  MATLAYO,LACCFLA )
      if ( JRCD .ne. 0 ) then
        write (6,*) 'request error in uvarm for sp'
        write (6,*) 'stop in uvrm.'
        call jancae_exit ( 9000 )
      end if
      maxsp2 = array(3)
c
c                                                 ---- rupture criterion
      maxsp1se1 = 0.0d0
      maxsp2se2 = 0.0d0
      if ( se1 .gt. 0.0d0 ) maxsp1se1 = maxsp1 / se1
      if ( se2 .gt. 0.0d0 ) maxsp2se2 = maxsp2 / se2
c
      wlim2 = wlim1 + (maxsp2se2+maxsp1se1)*(peeq2-peeq1)/2.0d0
c
c                                                       ---- update uvar
      uvar2(2+nt+1) = peeq2
      uvar2(2+nt+2) = maxsp2
      uvar2(2+nt+3) = wlim2
      uvar2(2+nt+4) = wlim2/lim
c
      return
      end
c
c
c
c-----------------------------------------------------------------------
c     Rice and Tracey
c
      subroutine jancae_rup_rice ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,
     &                             jmac,jmatyp,matlayo,laccfla,nt,
     &                             lim,wlimnorm )
c
c-----------------------------------------------------------------------
      implicit real*8 (a-h,o-z)
c
      dimension UVAR1(NUVARM),JMAC(*),JMATYP(*)
      dimension ARRAY(15),JARRAY(15)
      dimension sdv(nsdv),uvar2(nuvarm)
      character*3 FLGRAY(15)
      real*8 lim,wlimnorm
      real*8 se1,peeq1,shyd1,shyd1se1,wlim1
      real*8 se2,peeq2,shyd2,shyd2se2,wlim2
c-----------------------------------------------------------------------
c
c     nuvarm : 4
c
c     uvar(1)      : equivalent stress
c     uvar(2+nt+1) : equivalent plastic strain
c     uvar(2+nt+2) : hydrostatic stress
c     uvar(2+nt+3) : rupture criterion
c     uvar(2+nt+4) : rupture criterion normalised
c
c                                            ---- get uvar before update
      se1   = uvar1(1)
      peeq1 = uvar1(2+nt+1)
      shyd1 = uvar1(2+nt+2)
      wlim1 = uvar1(2+nt+3)
c
			wlimnorm  = uvar1(2+nt+4)
c
c                                     ---- get sdv and uvar after update
      se2 = uvar2(1)
      peeq2 = sdv(1)
c
c                               ---- get hydrostatic stress after update
      call getvrm ('SINV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,JMATYP,
     &                    MATLAYO,LACCFLA )
      if ( JRCD .ne. 0 ) then
        write (6,*) 'request error in uvarm for sinv'
        write (6,*) 'stop in uvrm.'
        call jancae_exit ( 9000 )
      end if
      shyd2 = -array(3)
c
c                                                 ---- rupture criterion
      shyd1se1 = 0.0d0
      shyd2se2 = 0.0d0
      if ( se1 .gt. 0.0d0 ) shyd1se1 = exp(1.5d0*shyd1/se1)
      if ( se2 .gt. 0.0d0 ) shyd2se2 = exp(1.5d0*shyd2/se2)
c
      wlim2 = wlim1 + (shyd1se1+shyd2se2)*(peeq2-peeq1)/2.0d0
c
c                                                       ---- update uvar
      uvar2(2+nt+1) = peeq2
      uvar2(2+nt+2) = shyd2
      uvar2(2+nt+3) = wlim2
      uvar2(2+nt+4) = wlim2/lim
c
      return
      end
c
c
c
c-----------------------------------------------------------------------
c     Ayada
c
      subroutine jancae_rup_ayada ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,
     &                              jmac,jmatyp,matlayo,laccfla,nt,
     &                              lim,wlimnorm )
c
c-----------------------------------------------------------------------
      implicit real*8 (a-h,o-z)
c
      dimension UVAR1(NUVARM),JMAC(*),JMATYP(*)
      dimension ARRAY(15),JARRAY(15)
      dimension sdv(nsdv),uvar2(nuvarm)
      character*3 FLGRAY(15)
      real*8 lim,wlimnorm
      real*8 se1,peeq1,shyd1,shyd1se1,wlim1
      real*8 se2,peeq2,shyd2,shyd2se2,wlim2
c-----------------------------------------------------------------------
c
c     nuvarm : 4
c
c     uvar(1)      : equivalent stress
c     uvar(2+nt+1) : equivalent plastic strain
c     uvar(2+nt+2) : hydrostatic stress
c     uvar(2+nt+3) : rupture criterion
c     uvar(2+nt+4) : rupture criterion normalised
c
c                                            ---- get uvar before update
      se1   = uvar1(1)
      peeq1 = uvar1(2+nt+1)
      shyd1 = uvar1(2+nt+2)
      wlim1 = uvar1(2+nt+3)
c
			wlimnorm  = uvar1(2+nt+4)
c
c                                     ---- get sdv and uvar after update
      se2 = uvar2(1)
      peeq2 = sdv(1)
c
c                               ---- get hydrostatic stress after update
      call getvrm ('SINV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,JMATYP,
     &                    MATLAYO,LACCFLA )
      if ( JRCD .ne. 0 ) then
        write (6,*) 'request error in uvarm for sinv'
        write (6,*) 'stop in uvrm.'
        call jancae_exit ( 9000 )
      end if
      shyd2 = -array(3)
c
c                                                 ---- rupture criterion
      shyd1se1 = 0.0d0
      shyd2se2 = 0.0d0
      if ( se1 .gt. 0.0d0 ) shyd1se1 = shyd1 / se1
      if ( se2 .gt. 0.0d0 ) shyd2se2 = shyd2 / se2
c
      wlim2 = wlim1 + (shyd1se1+shyd2se2)*(peeq2-peeq1)/2.0d0
c
c                                                       ---- update uvar
      uvar2(2+nt+1) = peeq2
      uvar2(2+nt+2) = shyd2
      uvar2(2+nt+3) = wlim2
      uvar2(2+nt+4) = wlim2/lim
c
      return
      end
c
c
c
c-----------------------------------------------------------------------
c     Brozzo
c
      subroutine jancae_rup_brozzo ( sdv,nsdv,uvar2,uvar1,nuvarm,jrcd,
     &                               jmac,jmatyp,matlayo,laccfla,nt,
     &                               lim,wlimnorm )
c
c-----------------------------------------------------------------------
      implicit real*8 (a-h,o-z)
c
      dimension UVAR1(NUVARM),JMAC(*),JMATYP(*)
      dimension ARRAY(15),JARRAY(15)
      dimension sdv(nsdv),uvar2(nuvarm)
      character*3 FLGRAY(15)
      real*8 lim,wlimnorm
      real*8 se1,peeq1,shyd1,maxsp1,maxsp1shyd1,wlim1
      real*8 se2,peeq2,shyd2,maxsp2,maxsp2shyd2,wlim2
c-----------------------------------------------------------------------
c
c     nuvarm : 5
c
c     uvar(2+nt+1) : equivalent plastic strain
c     uvar(2+nt+2) : maximum principal stress
c     uvar(2+nt+3) : hydrostatic stress
c     uvar(2+nt+4) : rupture criterion
c     uvar(2+nt+5) : rupture criterion normalised
c
c                                            ---- get uvar before update
      peeq1  = uvar1(2+nt+1)
      maxsp1 = uvar1(2+nt+2)
      shyd1  = uvar1(2+nt+3)
      wlim1  = uvar1(2+nt+4)
c
			wlimnorm  = uvar1(2+nt+5)
c
c                                              ---- get sdv after update
      peeq2 = sdv(1)
c
c                                 ---- get principal stress after update
      call getvrm ('SP',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,JMATYP,
     &                  MATLAYO,LACCFLA )
      if ( JRCD .ne. 0 ) then
        write (6,*) 'request error in uvarm for sp'
        write (6,*) 'stop in uvrm.'
        call jancae_exit ( 9000 )
      end if
      maxsp2 = array(3)
c
c                               ---- get hydrostatic stress after update
      call getvrm ('SINV',ARRAY,JARRAY,FLGRAY,JRCD,JMAC,JMATYP,
     &                    MATLAYO,LACCFLA )
      if ( JRCD .ne. 0 ) then
        write (6,*) 'request error in uvarm for sinv'
        write (6,*) 'stop in uvrm.'
        call jancae_exit ( 9000 )
      end if
      shyd2 = -array(3)
c
c                                                 ---- rupture criterion
      maxsp1shyd1 = 0.0d0
      maxsp2shyd2 = 0.0d0
      if ( shyd1 .gt. 0.0d0 ) then
        maxsp1shyd1 = (2.0d0/3.0d0) * maxsp1 / (maxsp1-shyd1)
      end if
      if ( shyd2 .gt. 0.0d0 ) then 
        maxsp2shyd2 = (2.0d0/3.0d0) * maxsp2 / (maxsp2-shyd2)
      end if
c
      wlim2 = wlim1 + (maxsp2shyd2+maxsp1shyd1)*(peeq2-peeq1)/2.0d0
c
c                                                       ---- update uvar
      uvar2(2+nt+1) = peeq2
      uvar2(2+nt+2) = maxsp2
      uvar2(2+nt+3) = shyd2
      uvar2(2+nt+4) = wlim2
      uvar2(2+nt+5) = wlim2/lim
c
      return
      end
c
c
c