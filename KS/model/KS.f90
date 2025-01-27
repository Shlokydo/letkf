MODULE KSmodel
!=======================================================================
!
! [PURPOSE:] Kuramoto-Sivasinski model
!
! [PUBLIC:]
!   SUBROUTINE tinteg_rk4(kt,xin,xout)
!   SUBROUTINE TL_tinteg_rk4(kt,x9,xin,xout)
!   SUBROUTINE TL_tinteg_rk4_x9out(kt,x9,xin,xout)
!   SUBROUTINE AD_tinteg_rk4(kt,x9,xin,xout)
!   SUBROUTINE tinteg_rk4_ptbmtx(alpha,kt,x9,pa,pf)
!   SUBROUTINE TL_tinteg_rk4_ptbmtx(kt,x9,pa,pf)
!
! [FIRST CREATED:] 08/13/2019 Arata Amemiya
!
! [HISTORY:]
!   08/13/2019 Arata Amemiya  Initial Creation
!
!=======================================================================
  USE common

  PRIVATE

  PUBLIC :: tinteg_rk4, TL_tinteg_rk4, TL_tinteg_rk4_x9out, AD_tinteg_rk4,&
          & tinteg_rk4_ptbmtx, TL_tinteg_rk4_ptbmtx

  INTEGER,PARAMETER,PUBLIC :: nx=64         ! number of grid points
  REAL(r_size),SAVE,PUBLIC :: xlen=35.0     ! domain size 
  REAL(r_size),SAVE,PUBLIC :: dt=0.005d0    ! time of one time step
CONTAINS
!=======================================================================
! [0] Time integration of Perturbation Matrix
!=======================================================================
!-----------------------------------------------------------------------
! [0.1] M P M^T
!-----------------------------------------------------------------------
SUBROUTINE tinteg_rk4_ptbmtx(alpha,kt,x9,pa,pf)
  IMPLICIT NONE

  REAL(r_size),INTENT(IN)  :: alpha ! NL(x+alpha*dx) = NL(x)+alpha*dxf
  INTEGER,INTENT(IN) :: kt
  REAL(r_size),INTENT(IN)  :: x9(1:nx)  ! background state
  REAL(r_size),INTENT(IN)  :: pa(1:nx,1:nx)
  REAL(r_size),INTENT(OUT) :: pf(1:nx,1:nx)

  REAL(r_size),ALLOCATABLE :: work1(:),work2(:)
  INTEGER :: i

  ALLOCATE( work1(1:nx) )
  ALLOCATE( work2(1:nx) )

  CALL tinteg_rk4(kt,x9,work1)
  DO i=1,nx
    work2(:) = pa(:,i) * alpha + x9(:)
    CALL tinteg_rk4(kt,work2,work2)
    pf(:,i) = ( work2 - work1 ) / alpha
  END DO

  DEALLOCATE( work1,work2 )

  RETURN
END SUBROUTINE tinteg_rk4_ptbmtx
!-----------------------------------------------------------------------
! [0.2] M P M^T using TL
!-----------------------------------------------------------------------
SUBROUTINE TL_tinteg_rk4_ptbmtx(kt,x9,pa,pf)
  IMPLICIT NONE

  INTEGER,INTENT(IN) :: kt
  REAL(r_size),INTENT(IN)  :: x9(1:nx)  ! background state
  REAL(r_size),INTENT(IN)  :: pa(1:nx,1:nx)
  REAL(r_size),INTENT(OUT) :: pf(1:nx,1:nx)
  INTEGER :: i

  DO i=1,nx
    CALL TL_tinteg_rk4(kt,x9,pa(:,i),pf(:,i))
  END DO

  RETURN
END SUBROUTINE TL_tinteg_rk4_ptbmtx
!=======================================================================
! [1] Methods of KS equation
!=======================================================================
!-----------------------------------------------------------------------
! [1.1] Time integration of KS equation
!-----------------------------------------------------------------------
SUBROUTINE tinteg_rk4(kt,xin,xout)
  IMPLICIT NONE

  INTEGER,INTENT(IN) :: kt
  REAL(r_size),INTENT(IN)  :: xin(1:nx)
  REAL(r_size),INTENT(OUT) :: xout(1:nx)
  REAL(r_size),ALLOCATABLE :: x(:),xtmp(:),q1(:),q2(:),q3(:),q4(:)
  INTEGER :: k
!--[1.1.1] allocation --------------------------------------------------
  ALLOCATE( x(1:nx) )
  ALLOCATE( xtmp(1:nx) )
  ALLOCATE( q1(1:nx) )
  ALLOCATE( q2(1:nx) )
  ALLOCATE( q3(1:nx) )
  ALLOCATE( q4(1:nx) )
!--[1.1.2] time integration --------------------------------------------
  x(:) = xin(:)
!>>>>> TIME INTEGRATION START
  DO k=1,kt
    xtmp(:) = x(:)
    CALL KS_core(xtmp,q1)
    xtmp(:) = x(:) + 0.5d0 * q1(:)
    CALL KS_core(xtmp,q2)
    xtmp(:) = x(:) + 0.5d0 * q2(:)
    CALL KS_core(xtmp,q3)
    xtmp(:) = x(:) + q3(:)
    CALL KS_core(xtmp,q4)
    x(:) = x(:) + ( q1(:) + 2.0d0 * q2(:) + 2.0d0 * q3(:) + q4(:) ) / 6.0d0
  END DO
!<<<<< TIME INTEGRATION END
  xout(:) = x(:)
!--[1.1.3] tidy up -----------------------------------------------------
  DEALLOCATE( xtmp,q1,q2,q3,q4 )

  RETURN
END SUBROUTINE tinteg_rk4
!-----------------------------------------------------------------------
! [1.2] TL: time integration of Lorenz96
!-----------------------------------------------------------------------
SUBROUTINE TL_tinteg_rk4(kt,x9,xin,xout)
  IMPLICIT NONE

  INTEGER,INTENT(IN) :: kt
  REAL(r_size),INTENT(IN)  :: x9(1:nx)
  REAL(r_size),INTENT(IN)  :: xin(1:nx)
  REAL(r_size),INTENT(OUT) :: xout(1:nx)
  REAL(r_size),ALLOCATABLE :: x(:),x9tmp(:,:)
  INTEGER :: k
!--[1.2.1] allocation --------------------------------------------------
  ALLOCATE( x(1:nx) )
  ALLOCATE( x9tmp(1:nx,1:5) )
!--[1.2.2] time integration --------------------------------------------
  x9tmp(:,1) = x9
  x = xin
  DO k=1,kt
    CALL TL_tinteg_rk4_one(x9tmp,x,x)
    x9tmp(:,1) = x9tmp(:,5)
  END DO
  xout = x
!--[1.2.3] tidy up -----------------------------------------------------
  DEALLOCATE( x,x9tmp )
 
  RETURN
END SUBROUTINE TL_tinteg_rk4
!-----------------------------------------------------------------------
! [1.3] TL (detail x9 out): time integration of Lorenz96
!-----------------------------------------------------------------------
SUBROUTINE TL_tinteg_rk4_x9out(kt,x9,xin,xout)
  IMPLICIT NONE

  INTEGER,INTENT(IN) :: kt
  REAL(r_size),INTENT(INOUT)  :: x9(1:nx,1:4,1:kt)
  REAL(r_size),INTENT(IN)  :: xin(1:nx)
  REAL(r_size),INTENT(OUT) :: xout(1:nx)
  REAL(r_size),ALLOCATABLE :: x(:),x9tmp(:,:)
  INTEGER :: k
!--[1.3.1] allocation --------------------------------------------------
  ALLOCATE( x(1:nx) )
  ALLOCATE( x9tmp(1:nx,1:5) )
!--[1.3.2] time integration --------------------------------------------
  x9tmp(:,1) = x9(:,1,1)
  x = xin
  DO k=1,kt
    CALL TL_tinteg_rk4_one(x9tmp,x,x)
    x9(:,:,k) = x9tmp(:,1:4)
    x9tmp(:,1) = x9tmp(:,5)
  END DO
  xout = x
!--[1.3.3] tidy up -----------------------------------------------------
  DEALLOCATE( x,x9tmp )

  RETURN
END SUBROUTINE TL_tinteg_rk4_x9out
!-----------------------------------------------------------------------
! [1.4] TL one step: time integration of Lorenz96
!-----------------------------------------------------------------------
SUBROUTINE TL_tinteg_rk4_one(x9,xin,xout)
  IMPLICIT NONE

  REAL(r_size),INTENT(INOUT)  :: x9(1:nx,1:5)
  REAL(r_size),INTENT(IN)  :: xin(1:nx)
  REAL(r_size),INTENT(OUT) :: xout(1:nx)
  REAL(r_size),ALLOCATABLE :: x(:),xtmp(:),q1(:),q2(:),q3(:),q4(:)
  REAL(r_size),ALLOCATABLE :: q19(:),q29(:),q39(:),q49(:)
!--[1.4.1] allocation --------------------------------------------------
  ALLOCATE( x(1:nx) )
  ALLOCATE( xtmp(1:nx) )
  ALLOCATE( q1(1:nx) )
  ALLOCATE( q2(1:nx) )
  ALLOCATE( q3(1:nx) )
  ALLOCATE( q4(1:nx) )
  ALLOCATE( q19(1:nx) )
  ALLOCATE( q29(1:nx) )
  ALLOCATE( q39(1:nx) )
  ALLOCATE( q49(1:nx) )
!--[1.4.2] time integration --------------------------------------------
  x(:) = xin(:)
  xtmp(:) = x(:)
  CALL TL_KS_core(x9(:,1),xtmp,q1)
  xtmp = x9(:,1) + x
  CALL KS_core(xtmp,q19)
  x9(:,2) = x9(:,1) + 0.5d0 * q19
  xtmp(:) = x(:) + 0.5d0 * q1(:)
  CALL TL_KS_core(x9(:,2),xtmp,q2)
  xtmp = x9(:,2) + x
  CALL KS_core(xtmp,q29)
  x9(:,3) = x9(:,1) + 0.5d0 * q29
  xtmp(:) = x(:) + 0.5d0 * q2(:)
  CALL TL_KS_core(x9(:,3),xtmp,q3)
  xtmp = x9(:,3) + x
  CALL KS_core(xtmp,q39)
  x9(:,4) = x9(:,1) + q39
  xtmp(:) = x(:) + q3(:)
  CALL TL_KS_core(x9(:,4),xtmp,q4)
  xtmp = x9(:,4) + x
  CALL KS_core(xtmp,q49)
  xout(:) = x(:) + ( q1(:) + 2.0d0 * q2(:) + 2.0d0 * q3(:) + q4(:) ) / 6.0d0
  x9(:,5) = x9(:,1) + ( q19 + 2.0d0 * q29 + 2.0d0 * q39 + q49 ) / 6.0d0
!--[1.4.3] tidy up -----------------------------------------------------
  DEALLOCATE( xtmp,q1,q2,q3,q4 )
  DEALLOCATE( q19,q29,q39,q49 )

  RETURN
END SUBROUTINE TL_tinteg_rk4_one
!-----------------------------------------------------------------------
! [1.5] AD: time integration of Lorenz96 without orography
!-----------------------------------------------------------------------
SUBROUTINE AD_tinteg_rk4(kt,x9,xin,xout)
  IMPLICIT NONE

  INTEGER,INTENT(IN) :: kt
  REAL(r_size),INTENT(IN)  :: x9(1:nx,1:4,1:kt)  ! background state
  REAL(r_size),INTENT(IN)  :: xin(1:nx)
  REAL(r_size),INTENT(OUT) :: xout(1:nx)
  REAL(r_size),ALLOCATABLE :: x(:),xtmp(:),q1(:),q2(:),q3(:),q4(:)
  REAL(r_size),ALLOCATABLE :: q19(:),q29(:),q39(:),q49(:)
  INTEGER :: k
!--[1.5.1] allocation --------------------------------------------------
  ALLOCATE( x(1:nx) )
  ALLOCATE( xtmp(1:nx) )
  ALLOCATE( q1(1:nx) )
  ALLOCATE( q2(1:nx) )
  ALLOCATE( q3(1:nx) )
  ALLOCATE( q4(1:nx) )
  ALLOCATE( q19(1:nx) )
  ALLOCATE( q29(1:nx) )
  ALLOCATE( q39(1:nx) )
  ALLOCATE( q49(1:nx) )
!--[1.5.2] time integration --------------------------------------------
  x = xin
  DO k=kt,1,-1
    q1 = x / 6.0d0
    q2 = x / 3.0d0
    q3 = x / 3.0d0
    q4 = x / 6.0d0

    CALL AD_KS_core(x9(:,4,k),xtmp,q4)
    x = x + xtmp
    q3 = q3 + xtmp
    CALL AD_KS_core(x9(:,3,k),xtmp,q3)
    x = x + xtmp
    q2 = q2 + xtmp * 0.5d0
    CALL AD_KS_core(x9(:,2,k),xtmp,q2)
    x = x + xtmp
    q1 = q1 + xtmp * 0.5d0
    CALL AD_KS_core(x9(:,1,k),xtmp,q1)
    x = x + xtmp
  END DO
  xout = x
!--[1.5.3] tidy up -----------------------------------------------------
  DEALLOCATE( xtmp,q1,q2,q3,q4 )
  DEALLOCATE( q19,q29,q39,q49 )

  RETURN
END SUBROUTINE AD_tinteg_rk4
!=======================================================================
! [2] core part of KS equation
!=======================================================================
!--[2.1] NL ------------------------------------------------------------
SUBROUTINE KS_core(xin,xout)
  IMPLICIT NONE

  REAL(r_size),INTENT(IN) :: xin(1:nx)
  REAL(r_size),INTENT(OUT) :: xout(1:nx)
  INTEGER :: i

  REAL(r_size) :: dxi

  dxi = real(nx)/xlen

    xout(1) = - xin(1) * ( xin(2) - xin(nx) ) * 0.5*dxi - (xin(2)-2.0*xin(1)+xin(nx))*dxi**2 &
              - (xin(3)-4.0*xin(2)+6.0*xin(1)-4.0*xin(nx)+xin(nx-1)) *dxi**4
    xout(2) = - xin(2) * ( xin(3) - xin(1) ) * 0.5*dxi - (xin(3)-2.0*xin(2)+xin(1))*dxi**2 &
              - (xin(4)-4.0*xin(3)+6.0*xin(2)-4.0*xin(1)+xin(nx)) *dxi**4 
  DO i=3,nx-2
    xout(i) = - xin(i) * ( xin(i+1) - xin(i-1) ) * 0.5*dxi - (xin(i+1)-2.0*xin(i)+xin(i-1))*dxi**2 &
              - (xin(i+2)-4.0*xin(i+1)+6.0*xin(i)-4.0*xin(i-1)+xin(i-2)) *dxi**4 
  END DO
    xout(nx-1) = - xin(nx-1) * ( xin(nx) - xin(nx-2) ) * 0.5*dxi - (xin(nx)-2.0*xin(nx-1)+xin(nx-2))*dxi**2 &
              - (xin(1)-4.0*xin(nx)+6.0*xin(nx-1)-4.0*xin(nx-2)+xin(nx-3)) *dxi**4 
    xout(nx) = - xin(nx) * ( xin(1) - xin(nx-1) ) * 0.5*dxi - (xin(1)-2.0*xin(nx)+xin(nx-1))*dxi**2 &
              - (xin(2)-4.0*xin(1)+6.0*xin(nx)-4.0*xin(nx-1)+xin(nx-2)) *dxi**4 

  xout(:) = dt * xout(:)

  RETURN
END SUBROUTINE KS_core
!--[2.2] TL ------------------------------------------------------------
SUBROUTINE TL_KS_core(x9,xin,xout)
  IMPLICIT NONE

  REAL(r_size),INTENT(IN) :: x9(1:nx)
  REAL(r_size),INTENT(IN) :: xin(1:nx)
  REAL(r_size),INTENT(OUT) :: xout(1:nx)
  INTEGER :: i

  xout(1) = - x9(1) * ( xin(2) - xin(nx) ) - xin(1) * ( x9(2) - x9(nx) ) 
  DO i=2,nx-1
    xout(i) = - x9(i) * ( xin(i+1) - xin(i-1) ) - xin(i) * ( x9(i+1) - x9(i-1) ) 
  END DO
  xout(nx) = - x9(nx) * ( xin(1) - xin(nx-1) ) - xin(nx) * ( x9(1) - x9(nx-1) ) 

  xout(:) = dt * xout(:)

  RETURN
END SUBROUTINE TL_KS_core
!--[2.3] AD ------------------------------------------------------------
SUBROUTINE AD_KS_core(x9,xin,xout)
  IMPLICIT NONE

  REAL(r_size),INTENT(IN) :: x9(1:nx)
  REAL(r_size),INTENT(OUT) :: xin(1:nx)
  REAL(r_size),INTENT(INOUT) :: xout(1:nx)
  INTEGER :: i

  xin = 0.0d0

  xout(:) = dt * xout(:)

  xin(1)    = xin(1)    - x9(nx) * xout(nx)
  xin(nx-1) = xin(nx-1) + x9(nx) * xout(nx)
  xin(nx)   = xin(nx)   - (x9(1)-x9(nx-1)) * xout(nx)
  DO i=nx-1,2,-1
    xin(i+1) = xin(i+1) - x9(i) * xout(i)
    xin(i-1) = xin(i-1) + x9(i) * xout(i)
    xin(i) = xin(i) - (x9(i+1)-x9(i-1))* xout(i)
  END DO
  xin(2)  = xin(2)  - x9(1) * xout(1)
  xin(nx) = xin(nx) + x9(1) * xout(1)
  xin(1)  = xin(1)  - (x9(2)-x9(nx)) * xout(1)

  RETURN
END SUBROUTINE AD_KS_core

END MODULE KSmodel
