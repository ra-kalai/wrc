WRC - Web Remote Control
========================

About
-----
Web Remote Control is a proof of concept daemon, made to start desktop application from a web browser

My own usage of it, is to start video on a RPI, from my phone

Features
--------
Browse Directory
Possible preview of img file / text document
Display img / video
Web keyboard <- write to stdin of application - good to seek in video file
Process control kill stop cont,.. the process we started

Requirement
-----------

[altered lem]: https://github.com/ra-kalai/lem/
[lpeg]: http://www.inf.puc-rio.br/~roberto/lpeg/

[mpv]: http://mpv.io/ 
[feh]: https://feh.finalrewind.org/
[imagemagick]: https://www.imagemagick.org/


Getting Started
---------------
Check out the sources

    $ git clone git://github.com/ra-kalai/wrc.git
    $ cd wrc

and do

		$ SERVE_DIR=$HOME lem wrc.lua 

    or if started by ssh by the right user..
		$ DISPLAY=:0 SERVE_DIR=$HOME lem wrc.lua 

Your HOME directory should then be exposed at http://your-ip:8080/


License
-------

  Three clause BSD license


Contact
-------

Please send bug reports, patches and feature requests to me <ra@apathie.net>.
