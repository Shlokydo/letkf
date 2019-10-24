program ndarray01
  use forpy_mod
  implicit none

  integer, parameter :: NROWS = 2
  integer, parameter :: NCOLS = 3
  integer :: ierror, ii, jj
  
  real :: matrix(NROWS, NCOLS)
  
  type(ndarray) :: arr

  ierror = forpy_initialize()

  do jj = 1, NCOLS
    do ii = 1, NROWS
      matrix(ii, jj) = real(ii) * jj
    enddo
  enddo

  ! creates a numpy array with the same content as 'matrix'
  ierror = ndarray_create_ones(arr, [NROWS, NCOLS], dtype="int32")
  
  ierror = print_py(arr)

  call arr%destroy
  call forpy_finalize

end program
