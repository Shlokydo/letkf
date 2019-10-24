program module_load
  
  use forpy_mod
  implicit none

  integer :: ierror
  type(module_py) :: tf2
  type(object) :: ver, r_vec, model
  type(ndarray) :: vec
  type(list) :: paths
  type(tuple) :: args, args2
  character(len=:), allocatable :: f_ver
  
  integer, parameter :: NROWS = 1, NCOLS = 5
  real, dimension(:,:), pointer :: f_vec
  type(ndarray) :: r_vec_cast

  ierror = forpy_initialize()
  
  ierror = get_sys_path(paths)
  ierror = paths%append(".")

  ierror = import_py(tf2, "tf2")
  ierror = call_py(ver, tf2, "print_version")
  ierror = cast(f_ver, ver)

  write(*,*) "Tensorflow version: ", f_ver

  ierror = ndarray_create_ones(vec, [NROWS, NCOLS], dtype='float64')

  ierror = tuple_create(args, 1)
  ierror = args%setitem(0, vec)
  
  ierror = call_py(r_vec, tf2, "predict", args)
  ierror = print_py(r_vec)
 
  write(*,*) is_ndarray(r_vec)
  ierror = cast(r_vec_cast, r_vec)
  !ierror = print_py(r_vec_cast)
  ierror = r_vec_cast%get_data(f_vec) 
  write(*,*) f_vec

  ierror = call_py(model, tf2, "get_model")
  ierror = tuple_create(args2, 2)
  ierror = args2%setitem(0, model)
  ierror = args2%setitem(1, vec)
  ierror = call_py(r_vec, tf2, "addi", args2)

  call args%destroy
  call r_vec%destroy
  call vec%destroy
  call tf2%destroy
  call ver%destroy
  call paths%destroy

  call forpy_finalize

end program
