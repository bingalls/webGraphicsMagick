#!/bin/bash
#GraphicsMagick script for lossy compression of jpg & png
#Copies *.gif into unanimated *.png files
#GraphicsMagick seems to outperform ImageMagick
#ToDo: handle -sampling-factor and filter-type
#http://www.graphicsmagick.org/GraphicsMagick.html#details-quality
#For lossless compression, try http://www.smushit.com/ysmush.it/

#GraphicsMagick & ImageMagick only handle .jpg & .png, and limited .gif
#Copyright 2012 MergerMarket & Bruce Ingalls
#MIT license, similar to GraphicsMagick & ImageMagick:
#http://opensource.org/licenses/MIT
#http://www.graphicsmagick.org/Copyright.html

#User configuration
COMPRESS_DIR='./compressed' #Creates compressed copies in $COMPRESS_DIR.
GM='gm'                    #Use GraphicsMagick (recommended)
#GM=''                     #Use ImageMagick
RATIO='40'                 #compression ratio of main image
TRANSPARENT_RATIO='05'     #png only; compression ratio of transparent background
#End user configuration.

echo "Running this in a directory of images creates a subdir called $COMPRESS_DIR"
echo " only with images that can compress smaller, and lossy at $RATIO% image quality."

#Create dest dir for compressed copies of images
if [ ! -d $COMPRESS_DIR ];then
  mkdir $COMPRESS_DIR
else
  read -t15 -p "$COMPRESS_DIR/ already exists. 'y' to overwrite existing files: " proceed
  if [ $proceed != 'y' ];then
    echo "Exiting, to preserve existing contents in ./$COMPRESS_DIR/"
    exit 1;
  fi
fi

#Assumes images follow standard naming convention of *.gif, *.jpg, *.png
#GraphicsMagick can't compress gif files. Create unanimated png, if smaller
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
        pushd $COMPRESS_DIR
        rm -f "$file.gif"
        ln -s "$file.png" "$file.gif"
        popd
      fi
    else
      echo "Could not convert $i to png!"
    fi

    rm $COMPRESS_DIR/tmp_*
  done
fi    #*.gif exists

if [ `find . -maxdepth 1 -name "*.jpg" | head -1` ]; then    #*.jpg exists
  for i in *.jpg;do
    file=`basename $i .jpg`
    cp $i $COMPRESS_DIR/tmp_$file.jpg
    $GM convert $COMPRESS_DIR/tmp_$file.jpg -quality $RATIO $COMPRESS_DIR/tmp_lossy.jpg

    smallest=`ls -S $COMPRESS_DIR/tmp_*|tail -1`
    if [ $smallest == $COMPRESS_DIR/tmp_lossy.jpg ];then
      mv -f $smallest "$COMPRESS_DIR/$file.jpg"
    fi
    rm $COMPRESS_DIR/tmp_*
  done
fi    #*.jpg exists

if [ `find . -maxdepth 1 -name "*.png" | head -1` ]; then    #*.png exists
  for i in *.png;do
    file=`basename $i .png`
    cp $i $COMPRESS_DIR/tmp_$file.png
    #png calls syntax of transparent 0 main_image ratio; ex quality 30% 51%
    $GM convert $COMPRESS_DIR/tmp_$file.png -quality "$TRANSPARENT_RATIO0$RATIO" $COMPRESS_DIR/tmp_lossy.png

    smallest=`ls -S $COMPRESS_DIR/tmp_*|tail -1`
    if [ $smallest == $COMPRESS_DIR/tmp_lossy.png ];then
      mv -f $smallest "$COMPRESS_DIR/$file.png"
    fi

    rm $COMPRESS_DIR/tmp_*
  done
fi    #*.png exists
