program interface_lorenz

  use forpy_mod
  implicit none

  integer :: ierror
  type(module_py) :: fpi
  type(object) :: r_vec, model
  type(ndarray) :: vec, r_vec_cast
  type(list) :: paths
  type(tuple) :: args

  integer, parameter :: num_variable = 40 
  real, dimension(40) :: f_inp
  real, dimension(:,:), pointer :: f_vec

  ierror = forpy_initialize()

  ierror = get_sys_path(paths)
  ierror = paths%append(".")

  ierror = import_py(fpi, "forpy_interface")

  !Get the restored model
  ierror = call_py(model, fpi, "get_model")

  !This part would go in the forecast-analysis loop
    !Assuming one dimensional input fortran array containg all the variable
    ierror = ndarray_create(vec, f_inp)
  
    !Sending the array for new_forecast
    ierror = tuple_create(args, 2)
    ierror = args%setitem(0, model)
    ierror = args%setitem(1, vec)
    ierror = call_py(r_vec, fpi, "prediction", args)
    ierror = cast(r_vec_cast, r_vec)
    !Transferring the data to fortran vector for data assimilation
    ierror = r_vec_cast%get_data(f_vec)
  
  call args%destroy
  call r_vec%destroy
  call model%destroy
  call paths%destroy
  call vec%destroy
  call r_vec_cast%destroy

  call forpy_finalize

end program interface_lorenz
