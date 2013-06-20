#!/bin/bash
# This is basically the "mirror" of the install_hosts.bash script. This will remove the config
# files and will remove a host files.  "remove" will actually remove the directory 
# tree that is the MWF instance. 
# 

# get the source directory of this script to source the config.txt file first thing.  This is 
# convoluted to follow synlinks, etc

SOURCE="${BASH_SOURCE[0]}"
# resolve $SOURCE until the file is no longer a symlink
while [ -h "$SOURCE" ]; 
  do
  TARGET="$(readlink "$SOURCE")"
  if [[ $SOURCE == /* ]]; then
    if [ $DEBUG ] ; then echo "SOURCE '$SOURCE' is an absolute symlink to '$TARGET'" ; fi
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    if [ $DEBUG ] ; then echo "SOURCE '$SOURCE' is a relative symlink to '$TARGET' (relative to '$DIR')" ; fi
# if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    SOURCE="$DIR/$TARGET"
  fi
done
if [ $DEBUG ] ; then echo "SOURCE is '$SOURCE'" ; fi
RDIR="$( dirname "$SOURCE" )"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
if [ "$DIR" != "$RDIR" ]; then
  if [ $DEBUG ] ; then echo "DIR '$RDIR' resolves to '$DIR'" ; fi
fi
 if [ $DEBUG ] ; then echo "DIR is '$DIR'" ; fi

#
# configuration and replace function are in the config.txt file that is sourced below
# in addition to the error trap routine that needs to be sourced first thing
. $DIR/config.txt

unset DEBUG
#DEBUG=true

echo "Starting.."
if [ $DEBUG ] ; then echo "Debuging on..." ; fi

# walk thru the hosts in $HOSTS and process the ones marked "remove"
for host in "${!HOSTS[@]}"
do
  if [ $DEBUG ] ; then echo -n "$host is ";  fi
  if [ ${HOSTS[$host]} = "remove" ]
  then
    if [ $DEBUG ] ; then echo "REMOVE" ; fi
# 
    assoc_array_string=$(declare -p $host)
    if [ $DEBUG ] ; then echo "associative array for the host $host is defined with \"$assoc_array_string\""; fi
    eval "declare -A new_host_array="${assoc_array_string#*=}
# set up the variables for substitution and creation of the config files like
#  path=/var/www/html/mwf/ucla.prod
    for X in "${!new_host_array[@]}"
      do
        if [ $DEBUG ] ; then echo host variable = $new_host_array[$X] ; fi
        eval $X=${new_host_array[$X]}
      done
    
     for file_base in ${!config_files[@]}
       do
        if [ $DEBUG ] ; then echo "Original config string " ${config_files[$file_base]} ; fi
        file_in=$(replace ${config_files[$file_base]})
        if [ $DEBUG ] ; then echo ./templates/$file_base goes to  $(replace ${config_files[$file_base]}) ; fi
        if [ $DEBUG ] ; then echo "base = $file_base , file = $file_in" ; fi
# process template files ($TEMPLATEDIR/$file_base) and put them into the temp directory with the names $file_base.tmp
# remove the temp file before writing into it
     if [ -f $TMPDIR/${file_base}.tmp ] ; then rm $TMPDIR/${file_base}.tmp ; fi
     while read line
       do
         replace $line
# delete config files
       if [ -f $file_in ] 
         then
          if [ $DEBUG ] ; then echo "Deleting $file_in " ; fi
#     rm -f $file_in
         else
          if [ $DEBUG ] ; then echo "File $file_in , does not exist, skipping" ; fi
       fi
       done
  else
   if [ $DEBUG ] ; then echo "not removing" ; fi
  fi
done  

echo "done."

exit

echo "Better never get here"
