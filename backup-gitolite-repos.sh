#!/bin/bash

# (c) Roman Ovchinnikov <coolthecold@gmail.com> 
# Licensed by GPL

#this script should pack git repos into bundle file

#idea inspiration and --all --remote trick from http://stackoverflow.com/questions/2129214/backup-a-local-git-repository/2176998#2176998

#restoration:
#git clone --mirror backup_file new_empty_dir/.git"

#in params:
#<gitolite repositories path> <destination dir>


PROGNAME=$(basename $0)
REPOSDIR_DEFAULT="/var/lib/gitolite/repositories"

function print_usage(){
    echo "this script may accept next params:"
    echo "-R - path to gitolite (or other) directory containing all repositories. Default value:${REPOSDIR_DEFAULT} ."
    echo "-D - destination directory where backups should be exported, one file per repo. No default value."
    echo ""
    echo "example:"
    echo "$PROGNAME -D /mnt/backup/gitrepos"
}
print_help() {
    echo ""
    echo "this script will create backup for git repo(s) via bundle file"
    echo "intended to be used with central gitolite repos storage and assumes all git repos are in separate subdirs inside main" 
    echo "like /mainpath/repo1.git /mainpath/repo2.git and so on"
    echo ""
    print_usage
    echo ""
}

if [ -z $1 ];then
    print_usage;
    exit 1
fi

# parsing arguments

while getopts ":hR:D:" Option; do
  case $Option in
    h)
      print_help
      exit 0
      ;;
    R)
      REPOSDIR="${OPTARG}"
      ;;
    D)
      DSTDIR="${OPTARG}"
      ;;
    *)
      print_help
      exit 0
      ;;
  esac
done
shift $(($OPTIND - 1))

REPOSDIR=${REPOSDIR:-${REPOSDIR_DEFAULT}}
#DSTDIR="${REPOSERVER}:mycompany/${PRJNAME}.git"
DATEFMT=$(LC_ALL=C date +%F_%k-%M-%S)

#echo "repos dir $REPOSDIR"
#echo "dst dir: $DSTDIR"

if [[ -z "$DSTDIR" ]];then
    usage;
    exit 1
fi

if [[ ! -d "${DSTDIR}" ]];then
    echo "Directory ${DSTDIR} doesn't exist or cannot be accessed";
    exit 1
fi

if [[ ! -d "${REPOSDIR}" ]];then
    echo "Directory ${REPOSDIR} doesn't exist or cannot be accessed";
    exit 1
fi

#iterating over dir list
errc=0
for i in "${REPOSDIR}"/*.git;do
    #echo $i
    rname=(${i//.git/}); #cutting off ".git" suffix
    rname=$(basename "$rname")
    #echo $rname
    if [[ ! -d "${DSTDIR}/${rname}" ]];then
        #creating repo-name based dir to put backups into it
        echo "creating dir ${DSTDIR}/${rname}"
        mkdir "${DSTDIR}/${rname}"  
    fi
    CMD="cd $i && git bundle create ${DSTDIR}/${rname}/${rname}.${DATEFMT}.gitbundle --all --remotes"
    sh -c "$CMD" 2>/dev/null 1>/dev/null
    rcode=$?
    if [ $rcode -ne 0 ];then
        errc=$((errc + 1))
    fi
done
if [[ $errc -ne 0 ]];then
    echo "$errc repos backup failed"
fi
