#!/bin/sh
# Copyright 2013 - 2015 Bruce Ingalls
# MIT license, similar to GraphicsMagick & ImageMagick:
# http://opensource.org/licenses/MIT  http://www.graphicsmagick.org/Copyright.html

GM=`which gm` > /dev/null 2>&1  #GM blank for ImageMagick

if [ $# -gt 0 ]; then
  echo "Usage: `basename $0` [no args | -h This help]"
  echo 'Lossless & lossy compresses all *.gif, *.jpg, *.png in a directory.'
  echo 'Compares as many CLI F/OSS tools as possible, with singular goal of smallest lossless compression'
  echo 'Then, GraphicsMagick creates a "compressed" folder, with lossy copies of images'
  echo 'See also the source code, for tunable parameters. Any suggested installs follow - '

  if [ -z $GM ]; then   # convert is the ImageMagick tool
    which convert >/dev/null || (echo 'Please install GraphicsMagick or ImageMagick!'; exit)
  fi

  #Lossless gif
  which gifsicle >/dev/null || echo 'gifsicle recommended'  # fast, but limited results?

  #Lossless jpg
  which jpegoptim >/dev/null || echo 'jpegoptim recommended'
  which jpegrescan >/dev/null || echo 'jpegrescan recommended'

  #Lossless png
  which optipng >/dev/null || 'optipng recommended'
  which pngcrush >/dev/null || echo 'pngcrush recommended'
  which pngnq >/dev/null || echo 'pngnq recommended'

  #Lossy png
  #Disabled: not clear, that pngquant compresses better than *magick.
  #which pngquant || echo 'Install pngquant for greater compression'
  
  exit
fi

# USER TUNED VALUES
COMPRESS_DIR='./compressed' # Lossy compressed copies go in $COMPRESS_DIR.
RATIO='40'                 # Percent compression. I recommend a range of 40%(small) - 75%(quality)
TRANSPARENT_RATIO='05'     # png only; compression ratio of transparent background

# END USER TUNED VALUES

# graphicsmagick (faster alternative, but fewer unused features? than imagemagick)
# imagemagick

# gif2png     # Copies *.gif into unanimated *.png files
# gifsicle

# jpegoptim
# jpegrescan

# optipng
# pngcrush
# pngnq    # seems better than pngquant

# Not impressed with compression of :
# pngquant; uncomment yourself
# giflossy too lazy to install

# GraphicsMagick seems to outperform ImageMagick
# ToDo: handle -sampling-factor and filter-type
# ToDo: Handle 2-step gif optimization, where 2nd pass compresses better
# http://www.graphicsmagick.org/GraphicsMagick.html#details-quality
# See also lossless http://www.smushit.com/ysmush.it/

# GraphicsMagick & ImageMagick only handle .jpg & .png, and limited .gif

CWD=`pwd`

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

# Assumes images follow standard naming convention of *.gif, *.jpg, *.png
# Does anyone use *.jpeg ?
# Remember to wrap "$i", "$file", "$smallest" for filenames with spaces
if [ `find . -maxdepth 1 -name "*.jpg" | head -1` ]; then    # *.jpg exists
  for i in *.jpg;do
    if [ `which jpegoptim` ]; then jpegoptim "$i" ;fi    # also supports lossy flag

    file=`basename "$i"`
    if [ `which jpegrescan` ]; then 
      jpegrescan -s "$i" $COMPRESS_DIR/"$file"
      smallest=`ls -S "$file" $COMPRESS_DIR/"$file"|tail -1`
      if [ "$smallest" = $COMPRESS_DIR/"$file" ];then
        mv -f "$smallest" "$file"
      else
        rm -f $COMPRESS_DIR/"$file"
      fi
    fi
    
    cp "$i" $COMPRESS_DIR/tmp_"$file"
    $GM convert $COMPRESS_DIR/tmp_"$file" -quality $RATIO $COMPRESS_DIR/tmp_lossy.jpg

    smallest=`ls -S $COMPRESS_DIR/tmp_*|tail -1`
    if [ "$smallest" = "$COMPRESS_DIR/tmp_lossy.jpg" ];then
      mv -f "$smallest" $COMPRESS_DIR/"$file"
    fi
    rm $COMPRESS_DIR/tmp_*
  done
fi    # *.jpg exists

# GraphicsMagick can't compress gif files. Create unanimated png, if smaller
if [ `find . -maxdepth 1 -name "*.gif" | head -1` ]; then    # *.gif exists
  for i in *.gif;do
    if [ `which gifsicle` ]; then gifsicle -b -O3 "$i" ;fi    # fast, but limited results
    
    file=`basename "$i" .gif`
    cp "$i" $COMPRESS_DIR/tmp_"$file".gif
    $GM convert "$i" $COMPRESS_DIR/tmp_lossless.png
    # png calls syntax of transparent 0 main_image ratio; ex quality 30% 51%
    if [ -f "$COMPRESS_DIR/tmp_lossless.png" ];then
      #echo "Converting "$i" to png!"
      $GM convert $COMPRESS_DIR/tmp_lossless.png -quality \
        "$TRANSPARENT_RATIO0$RATIO" $COMPRESS_DIR/tmp_lossy.png

      smallest=`ls -S $COMPRESS_DIR/tmp_*|tail -1`    # compare file size
      if [ `echo "$smallest" | egrep '.png$'` ];then
        mv -f "$smallest" $COMPRESS_DIR/"$file".png
        cd $COMPRESS_DIR
        rm -f "$file".gif
        ln -s "$file".png "$file".gif
        cd $CWD
      fi
    else
      echo "Could not convert $i to png!"
    fi

    rm $COMPRESS_DIR/tmp_*
  done
fi    # *.gif exists

if [ `find . -maxdepth 1 -name "*.png" | head -1` ]; then    # *.png exists
  mkdir $COMPRESS_DIR/tmp
  for i in *.png;do
    # Optipng only replaces original, if smaller.
    if [ `which optipng` ]; then optipng -quiet -o2 "$i" ;fi
    #More pngcrush options to hack & benchmark. Pngcrush cannot replace self.
    if [ `which pngcrush` ]; then pngcrush -q "$i" $COMPRESS_DIR/tmp/crush.png ;fi
    #if [ `which pngcrush` ]; then pngcrush -q -l9 -m0 "$i" $COMPRESS_DIR/tmp/crush.png ;fi

    file=`basename "$i"`
    if [ `which pngnq` ]; then 
      pngnq -e '.png' -d $COMPRESS_DIR "$i"
      smallest=`ls -S "$file" $COMPRESS_DIR/"$file"|tail -1`
      if [ "$smallest" = $COMPRESS_DIR/"$file" ];then
        mv -f "$smallest" "$file"
      else
        rm -f $COMPRESS_DIR/"$file"
      fi
    fi

    #png calls syntax of transparent 0 main_image ratio; ex quality 30% 51%
    $GM convert "$i" -quality "$TRANSPARENT_RATIO0$RATIO" $COMPRESS_DIR/tmp/magick.png

    smallest=`ls -1S $COMPRESS_DIR/tmp/*|tail -1`

    if [ `uname` = 'Darwin' ]; then
      if [ `du -k "$smallest"|cut -f1` -lt `du -k "$i"|cut -f1` ];then    # Mac OSX does not support bytes :(
        mv -f "$smallest" $COMPRESS_DIR/"$file"
      fi
    else
      if [ `du -b "$smallest"|cut -f1` -lt `du -b "$i"|cut -f1` ];then   # Assume Linux, which can compare bytes
        mv -f "$smallest" $COMPRESS_DIR/"$file"
      fi
    fi
    #Insert a read here, to pause, and compare *magick to pngcrush, for benchmarking.
    rm $COMPRESS_DIR/tmp/*
  done
  rmdir $COMPRESS_DIR/tmp
fi    # *.png exists
