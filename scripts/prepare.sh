set -e

mkdir "$JOB_DIR/tmp"

if [ -n "$CONTINUE_JOB_NUMBER" ]; then
    cp -r "$DATA_ROOT/jobs/$CONTINUE_JOB_NUMBER/keep" "$JOB_DIR/keep"
else
    mkdir "$JOB_DIR/keep"
fi

job_groups_dir="$JOB_DIR/groups"
mkdir -p "$job_groups_dir"
for group in $USER_GROUPS; do
    data_group_dir="$DATA_ROOT/groups/$group"
    if [ -d "$data_group_dir" ]; then
        job_data_group_dir="$job_groups_dir/$group"
        mkdir -p "$job_data_group_dir"
        bindfs -n -r "$data_group_dir" "$job_data_group_dir"
    fi
done

job_src_dir="$JOB_DIR/src"

if [ -n "$ORIGIN" ]; then
    mkdir -p "$DATA_ROOT/cache"
    cache_entry=`echo -n $ORIGIN | md5sum | cut -f1 -d" "`
    cache_repo="$DATA_ROOT/cache/$cache_entry"

    if [ -d "$cache_repo" ]; then
        git -C "$cache_repo" fetch --all >/dev/null
        touch "$cache_repo"
    else
        git clone $ORIGIN "$cache_repo" >/dev/null
    fi

    git -C "$cache_repo" archive --format=tar --prefix=src/ $HASH | (cd "$JOB_DIR" && tar xf -)
    if [ -n "$DIFF" ]; then
        cd "$job_src_dir"
        echo "$DIFF" | patch -p0
    fi
elif [ -n "$ARCHIVE" ]; then
    tar -xzf "$ARCHIVE" -C "$job_src_dir"
    rm "$ARCHIVE"
fi

install_script="${JOB_DIR}/src/.install"

if [ -f "$install_script" ]; then
    bash $install_script > "${JOB_DIR}/preparation.log" 2>&1
    echo $? > "${JOB_DIR}/exit-status_preparation"
fi
