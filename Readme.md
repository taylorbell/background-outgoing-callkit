# How it works

The app is extremely basic, intended only to show that a recording can be started in the background by starting an outgoing call via CallKit in response to a Remote Control event.

The app will become the Now Playing app automatically on launch by playing a bundled audio file via an AVAudioPlayer configured with a volume of 0.

Recording will record to a file in the documents directory. Each subsequent recording will overwrite this file.

Playback will play the aforementioned file, if it exists.

# Using the app

The app has no UI and is controlled entirely through Remote Control events:

+ Next/Previous: Toggles the audio control mode between Playback and Recording.
+ Play: Starts a recording when in the Recording audio control mode or starts playback of the most recent recording when in the Playback audio control mode.
+ Stop: Stops the active recording or playback.

The Now Playing Info Center will indicate the current media state as well as the audio control mode the app is currently configured for.