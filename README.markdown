WRC - Web Remote Control
========================

About
-----

Web Remote Control is a proof of concept daemon, made to start desktop application from a web browser

My own usage of it, is to start video on a RPI, from my phone

Features
--------

 - Browse filesystem
 - Possible preview of image file / text document while browsing the file system
 - Display image / video
 - Web Keyboard <- write to stdin of application - good to seek in video file
 - Process control: kill stop cont,.. the process we started

Requirement
-----------

 - [altered lem](https://github.com/ra-kalai/lem/)
 - [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)

cmd line program started
 - [file](http://www.gnu.org/software/coreutils/coreutils.html) (coreutils)
 - [mpv](http://mpv.io/)
 - [feh](https://feh.finalrewind.org/)
 - [convert](https://www.imagemagick.org/) (imagemagick)


Getting Started
---------------

Check out the sources

    $ git clone git://github.com/ra-kalai/wrc.git
    $ cd wrc

then do

		$ SERVE_DIR=$HOME lem wrc.lua 

or if started by ssh by the right user..

		$ DISPLAY=:0 SERVE_DIR=$HOME lem wrc.lua 

Your HOME directory should then be exposed at http://your-ip:8080/

Preview
-------

![preview](https://user-images.githubusercontent.com/10823818/34558714-723e5170-f13f-11e7-9b87-6b33080ea4de.png)


License
-------

  Three clause BSD license


Contact
-------

Please send bug reports, patches and feature requests to me <ra@apathie.net>.
