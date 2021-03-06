#!/bin/bash

if [ -z "$TIMES_DIR" ]; then
    TIMES_DIR=/home/ncameron/times
fi
if [ -z "$SCRIPTS_DIR" ]; then
    SCRIPTS_DIR=/home/ncameron/times-scripts
fi

echo TIMES_DIR=$TIMES_DIR
echo SCRIPTS_DIR=$SCRIPTS_DIR

START=$(pwd)
export CARGO_RUSTC_OPTS="-Ztime-passes -Zinput-stats"
export PATH=$RUSTC_DIR/bin:$PATH

# Check if user provided list of directories;
# else process them all.
if [ "$1" != "" ]; then
    DIRS="$@"
else
    DIRS="*"
fi    

for dir in $DIRS; do
    if [[ -d $dir ]]; then
        echo "Processing $dir"

        cd $START/$dir
        PATCHES=($(make patches))
        if [ ! "${PATCHES[*]}" ]; then
            PATCHES=('')
        fi

        echo Patches: ${PATCHES[*]}

        for i in 0 1 2 3 4 5
        do
            for PATCH in "${PATCHES[@]}"; do
                cd $RUST_DIR
                git show HEAD -s >$TIMES_DIR/raw/$dir$PATCH--$DATE--$i.log
                cd $START/$dir
                echo "rustc: ./$dir" >>$TIMES_DIR/raw/$dir$PATCH--$DATE--$i.log
                make all$PATCH >>$TIMES_DIR/raw/$dir$PATCH--$DATE--$i.log
                echo "done" >>$TIMES_DIR/raw/$dir$PATCH--$DATE--$i.log
            done
            make touch >/dev/null
        done

        make clean >/dev/null

        cd $TIMES_DIR
        for PATCH in "${PATCHES[@]}"; do
            python $SCRIPTS_DIR/process.py "$dir$PATCH" "$DATE" 6
        done

        for i in 0 1 2 3 4 5
        do
            for PATCH in "${PATCHES[@]}"; do
                git add "raw/$dir$PATCH--$DATE--$i.log"
                git add "raw/orbit-$dir$PATCH--$DATE--$i.log"
                git add "processed/$dir$PATCH--$DATE--$i.json"
            done
        done

        cd $START
    fi
done
