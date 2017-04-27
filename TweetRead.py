# Nos conectamos a Twitter y establecemos el puerto por el que va a escuchar
# las peticiones

import tweepy
from tweepy import OAuthHandler
from tweepy import Stream
from tweepy.streaming import StreamListener
import socket
import json

consumer_key = 'gC6H0bJgIBsEqBDLCgPiPVEfu'
consumer_secret = 'cAK2Kwx15Id7HQcrtDpPb2W3MGgBX2hjAHnYBtDQjwDJUPyz1o'
access_token = '855033074425495552-abKYs8h9GefnH2YOPgbRB6IOmvnmgxg'
access_secret = 'VR5PInAEdu3gefPIxYkQSASIz6iQeKwh2zjmD5UzEnaqK'

class TweetsListener(StreamListener):

  def __init__(self, csocket):
      self.client_socket = csocket

  def on_data(self, data):
      try:
          msg = json.loads( data )
          print( msg['text'].encode('utf-8') )
          self.client_socket.send( msg['text'].encode('utf-8'))
          return True
      except BaseException as e:
          print("Error on_data: %s" % str(e))
      return True

  def on_error(self, status):
      print(status)
      return True

def sendData(c_socket):
  auth = OAuthHandler(consumer_key, consumer_secret)
  auth.set_access_token(access_token, access_secret)

  twitter_stream = Stream(auth, TweetsListener(c_socket))
  twitter_stream.filter(track=['@DebatALRojoVivo'])

if __name__ == "__main__":
  s = socket.socket()         # Create a socket object
  host = "127.0.0.1"      # Get local machine name
  port = 8088                 # Reserve a port for your service.
  s.bind((host, port))        # Bind to the port

  print("Listening on port: %s" % str(port))

  s.listen(5)                 # Now wait for client connection.
  c, addr = s.accept()        # Establish connection with client.

  print( "Received request from: " + str( addr ) )

  sendData( c )
