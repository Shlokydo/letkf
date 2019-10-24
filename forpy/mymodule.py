# File: mymodule.py

def print_args(*args, **kwargs):
    print("Arguments: ", args[0])
    print("Keyword arguments: ", kwargs)
    
    return "Returned from mymodule.print_args"
