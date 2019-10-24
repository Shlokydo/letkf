import tensorflow as tf
import numpy as np

def print_version():
  return str(tf.__version__)

def get_model():
  model = tf.keras.Sequential()
  model.add(tf.keras.layers.Dense(32, input_dim=5))
  model.add(tf.keras.layers.Activation('relu'))
  return model

def addi(*args):
#def addi():
  model = args[0]
  pred = model(args[1])
  print(pred.numpy())
  return pred

def predict(*args):
  model = get_model()
  return model(args[0]).numpy()

#predict(np.ones(1,5))
