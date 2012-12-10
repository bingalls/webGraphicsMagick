#!/bin/sh
#ImageMagick script to generate Apple favicons
#Requires ImageMagick & shell script, such as Cygwin
#http://www.graphicsmagick.org/convert.html See below about GraphicsMagick
#Copyright 2012 Bruce Ingalls LGPL License http://www.gnu.org/licenses/lgpl.html

#HTML5 recommends a list of icons
#https://en.wikipedia.org/wiki/Favicon#HTML5_recommendation_for_icons_in_multiple_sizes
#But Apple currently ignores this spec:
#http://developer.apple.com/library/ios/Documentation/AppleApplications/Reference/SafariWebContent/ConfiguringWebApplications/ConfiguringWebApplications.html

#No <link /> tags needed, when using naming convention in DOCUMENT_ROOT
#ToDo: write as portable Incantation, when that language matures...

#User Editable Options
  GM=''   #Use original ImageMagick
  #When `gm convert -list format | grep -i ICO` supports writeable ico, enable GM
  #GM=gm  #Use GraphicsMagick fork, instead
  PRECOMPOSED=''
  #PRECOMPOSED='-precomposed'  #Enable, to stop Safari from adding effects.
#End User Editable Options

if [ $# -ne 1 ]; then
  echo "Usage: `basename $0` image"
  echo "Generates Apple icon files in current directory, to copy into WEB_ROOT"
  exit 0;
fi

#Original web standard, but Microsoft Vista+ now recommends png?
#https://en.wikipedia.org/wiki/ICO_(file_format)
$GM convert -geometry 16x16 $1 favicon.ico

#Current standard Apple sizes
for DIM in 57x57 72x72 114x114; do
  $GM convert -geometry $DIM $1 apple-touch-icon-$DIM$PRECOMPOSED.png
done
