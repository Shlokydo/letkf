import tensorflow as tf
import numpy as np
from netCDF4 import Dataset
import time
import math
import os
import sys
import pickle

import helperfuntions as helpfunc
import network_arch as net

pickle_name = '' #Enter the location of the parameter_list pickle file name
parameter_list = helpfunc.read_pickle(pickle_name)

def get_model():
  
  print('\nGetting the Tensorflow model\n')

  if os.path.exists(parameter_list['model_loc']):
    print('\nLoading saved model.\n')
    j_string = helpfunc.read_json(parameter_list['model_loc'])
    model = tf.keras.models.model_from_json(j_string)
  else:
    print('\nModel json file does not exist. Exiting...')
    sys.exit()

  checkpoint = tf.train.Checkpoint(model = model)
  checkpoint.restore(tf.train.latest_checkpoint(parameter_list['checkpoint_dir']))

  return model

def prediction(*args):
  
  model = args[0]
  new_forecast = np.zeros(args[1].shape[1])
  forecast_data = helpfunc.locality_creator(args[1], parameter_list['locality'], parameter_list['x_local'])

  for i in range(forecast_data.shape[1]):
    forecast = np.expand_dims(forecast_data[:,i,:], axis = 1)
    new_forecast[i] = np.squeeze(model(forecast))
  
  return np.squeeze(new_forecast)