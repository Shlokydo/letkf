import numpy as np
import tensorflow as tf

#Model defination
def rnn_model(parameter_list):
    net_input = tf.keras.Input(shape=(None,
                            parameter_list['locality']),
                            name='INPUT')

    x = tf.keras.layers.LSTM(units=parameter_list['LSTM_output'],
                            activation = parameter_list['activation'],
                            recurrent_activation = parameter_list['rec_activation'],
                            kernel_regularizer = tf.keras.regularizers.l2(parameter_list['l2_regu']),
                            activity_regularizer = tf.keras.regularizers.l1(parameter_list['l1_regu']),
                            dropout = parameter_list['lstm_dropout'],
                            recurrent_dropout = parameter_list['rec_lstm_dropout'],
                            unroll = parameter_list['unroll_lstm'],
                            return_sequences=True)(net_input)

    if parameter_list['new_forecast']:

        output = tf.keras.layers.Dense(units=parameter_list['net_output'],
                                kernel_regularizer = tf.keras.regularizers.l2(parameter_list['l2_regu']),
                                activation = tf.keras.layers.ELU(1.5))(x)

    else:

        output = net_input + tf.keras.layers.Dense(units=parameter_list['net_output'],
                                kernel_regularizer = tf.keras.regularizers.l2(parameter_list['l2_regu']),
                                activation = tf.keras.layers.ELU(1.5))(x)
    
    return tf.keras.Model(net_input, output, name='RNN')
