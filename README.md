# CertPinning

Simple cert pinning example.

See ViewController for usage.


Three classes to support things:

## URLSessionPinningDelegate
URLSessionDelegate implementation.  Pins on the hashed signature.  The hashs are pulled from MobileCoreConfig.


## MobileCoreConfig
Stores all the hashes to pin to.

## SafeNetwork
Light wrapper around calling dataTask.  I wrap this to make it a bit simplier to call and to enfore using the session I define for all network calls.
