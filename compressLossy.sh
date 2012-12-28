#!/bin/sh
#GraphicsMagick script for lossy compression of jpg & png
#Copies *.gif into unanimated *.png files
#GraphicsMagick seems to outperform ImageMagick
#ToDo: handle -sampling-factor and filter-type
#ToDo: gif2png also updates HTML; icoutils converts favicon.ico to/from png
#ToDo: benchmark optipng vs pngcrush vs pngquant vs *magick: fewer, faster
#ToDo: Handle 2-step gif optimization, where 2nd pass compresses better
#http://www.graphicsmagick.org/GraphicsMagick.html#details-quality
#For lossless compression, try http://www.smushit.com/ysmush.it/

#GraphicsMagick & ImageMagick only handle .jpg & .png, and limited .gif
#Copyright 2013 Bruce Ingalls
#MIT license, similar to GraphicsMagick & ImageMagick:
#http://opensource.org/licenses/MIT
#http://www.graphicsmagick.org/Copyright.html

#User configuration
COMPRESS_DIR='./compressed' #Creates compressed copies in $COMPRESS_DIR.
RATIO='40'                 #compression ratio of main image
TRANSPARENT_RATIO='05'     #png only; compression ratio of transparent background

GM=`which gm` > /dev/null 2>&1  #GM blank for ImageMagick
#End user configuration.

CWD=`pwd`
if [ -z $GM ]; then
  which convert >/dev/null || (echo 'Please install GraphicsMagick or ImageMagick!'; exit)
fi

echo "Usage: Any compressible images are saved into $COMPRESS_DIR."
echo " Uncompressed images are untouched. You may edit settings in this script."

#Lossless png
which optipng >/dev/null && OPTIPNG=1
which optipng >/dev/null || (OPTIPNG=0 & echo 'Install optipng for greater compression')

which pngcrush >/dev/null && PNGCRUSH=1
which pngcrush >/dev/null || (PNGCRUSH=0 & echo 'Install pngcrush for greater compression')

#Lossy png
#Disabled: not clear, that pngquant compresses better than *magick.
#which pngquant && PNGQUANT=1
#which pngquant || (PNGQUANT=0 & echo 'Install pngquant for greater compression')

#Create dest dir for compressed copies of images
if [ ! -d $COMPRESS_DIR ];then
  mkdir $COMPRESS_DIR
else
  #read -t15 is bash for timeout of 15 seconds
  read -p "$COMPRESS_DIR/ already exists. 'y' to overwrite existing files: " proceed
  if [ "y" != $proceed ];then
    echo "Exiting, to preserve existing contents in ./$COMPRESS_DIR/"
    exit 1;
  fi
fi

#Assumes images follow standard naming convention of *.gif, *.jpg, *.png
#Does anyone use *.jpeg ?
if [ `find . -maxdepth 1 -name "*.jpg" | head -1` ]; then    #*.jpg exists
  for i in *.jpg;do
    file=`basename $i .jpg`
    cp $i $COMPRESS_DIR/tmp_$file.jpg
    $GM convert $COMPRESS_DIR/tmp_$file.jpg -quality $RATIO $COMPRESS_DIR/tmp_lossy.jpg

    smallest=`ls -S $COMPRESS_DIR/tmp_*|tail -1`
    if [ $smallest = $COMPRESS_DIR/tmp_lossy.jpg ];then
      mv -f $smallest "$COMPRESS_DIR/$file.jpg"
    fi
    rm $COMPRESS_DIR/tmp_*
  done
fi    #*.jpg exists

#GraphicsMagick can't compress gif files. Create unanimated png, if smaller
#ToDo: gif2png, if installed, also updates HTML
if [ `find . -maxdepth 1 -name "*.gif" | head -1` ]; then    #*.gif exists
  for i in *.gif;do
    file=`basename $i .gif`
    cp $i $COMPRESS_DIR/tmp_$file.gif
    $GM convert $i $COMPRESS_DIR/tmp_lossless.png
    #png calls syntax of transparent 0 main_image ratio; ex quality 30% 51%
    if [ -f $COMPRESS_DIR/tmp_lossless.png ];then
      #echo "Converting $i to png!"
      $GM convert $COMPRESS_DIR/tmp_lossless.png -quality "$TRANSPARENT_RATIO0$RATIO" $COMPRESS_DIR/tmp_lossy.png

      smallest=`ls -S $COMPRESS_DIR/tmp_*|tail -1`
      if [ `echo $smallest | egrep '.png$'` ];then
        mv -f $smallest "$COMPRESS_DIR/$file.png"
        cd $COMPRESS_DIR
        rm -f "$file.gif"
        ln -s "$file.png" "$file.gif"
        cd $CWD
      fi
    else
      echo "Could not convert $i to png!"
    fi

    rm $COMPRESS_DIR/tmp_*
  done
fi    #*.gif exists

if [ `find . -maxdepth 1 -name "*.png" | head -1` ]; then    #*.png exists
  mkdir $COMPRESS_DIR/tmp
  for i in *.png;do
    #ToDo benchmark higher -o levels, if portable. Replace lossless self, in-place
    if [ $OPTIPNG ]; then optipng -quiet -o2 $i ;fi
    #More pngcrush options to hack & benchmark. Pngcrush cannot replace self.
    if [ $PNGCRUSH ]; then pngcrush -q -l9 -m0 $i $COMPRESS_DIR/tmp/crush.png ;fi

    #png calls syntax of transparent 0 main_image ratio; ex quality 30% 51%
    $GM convert $i -quality "$TRANSPARENT_RATIO0$RATIO" $COMPRESS_DIR/tmp/magick.png

    file=`basename $i`
    smallest=`ls -1S $COMPRESS_DIR/tmp/*|tail -1`
    if [ `du -b $smallest|cut -f1` -lt `du -b $i|cut -f1` ];then
      mv -f $smallest "$COMPRESS_DIR/$file"
    fi
    #Insert a read here, to pause, and compare *magick to pngcrush, for benchmarking.
    rm $COMPRESS_DIR/tmp/*
  done
  rmdir $COMPRESS_DIR/tmp
fi    #*.png exists
