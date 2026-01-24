#!/bin/env elvish
use os
use path
use str
use flag
use platform

fn arch {
    var arch = ""
    var os = ""
    if (eq $platform:arch "amd64") {
        set arch = "x86_64"
    } elif (eq $platform:arch "arm64") {
        set arch = "aarch64"
    } else {
        set arch = $platform:arch
    }

    if (or (eq $platform:os "linux") (eq $platform:os "android")) {
        set os = "linux"
    } else {
        set os = $platform:os
    }

    put $arch"-"$os
}

var ZIG_ROOT = $E:HOME/.local/zig
var BIN_DIR = $E:XDG_LOCAL_HOME/bin
var TMPDIR = $E:PREFIX/tmp/zvm
var ZIG_JSON_URL = https://ziglang.org/download/index.json
var ARCH = (arch)
var INDEX = $TMPDIR/index.json

fn start {
    if (not (os:is-dir $ZIG_ROOT)) {
        os:mkdir $ZIG_ROOT
        echo "Zig download directory "$ZIG_ROOT" has been created!"
    }
    if (not (os:is-dir $BIN_DIR)) {
        os:mkdir $BIN_DIR
        echo "Zig bin directory "$BIN_DIR" has been created!"
    }
    if (not (os:is-dir $TMPDIR)) {
        os:mkdir $TMPDIR
    }
}

fn extract-info {|branch|
    # check if index hasn't change in about 70 min
    var check-index~ = { find $TMPDIR -maxdepth 1 -cmin +70 -path $INDEX -type f }

    if (or (not (os:is-regular $INDEX)) (eq ?(cat $INDEX | slurp) '') (str:contains (check-index | slurp) $INDEX)) {
        try {
            curl -s $ZIG_JSON_URL stdout>$INDEX
        } catch err {
            fail "curl failed to download the zig index.json\nrm "$INDEX" and try `zvm` again\nEnsure you have a working internet connection"
        }
    }

    var index = (cat $INDEX | from-json | put (all)[$branch][$ARCH])

    var tarball = $index[tarball]
    var basename = (path:base $tarball)
    var zig_version = (str:replace '.tar.xz' '' $basename)
    var new_zig_exe_name = (if (==s $branch "master") { put zig-dev } else { put zig-$branch })
    var new_zig_exe =  $BIN_DIR/$new_zig_exe_name
    var install_dir_link = $ZIG_ROOT/$new_zig_exe_name
    put [&tarball=$tarball &basename=$basename &zig_version=$zig_version ^
         &new_zig_exe=$new_zig_exe &install_dir_link=$install_dir_link]
}

fn update-symlink {|new_zig_exe install_dir_link zig_version|
    # update directory symlink
    if (and ?(os:stat $install_dir_link) (==s (os:stat $install_dir_link)[type] symlink)) {
        os:remove $install_dir_link
        os:symlink $ZIG_ROOT/$zig_version $install_dir_link
    } else {
        os:symlink $ZIG_ROOT/$zig_version $install_dir_link
    }
    # update zig file symlink
    if (and ?(os:stat $new_zig_exe) (==s (os:stat $new_zig_exe)[type] symlink)) {
        os:remove $new_zig_exe
        os:symlink $install_dir_link/zig $new_zig_exe
    } else {
        os:symlink $install_dir_link/zig $new_zig_exe
    }
}

fn remove-old-zig {
    var latest_zig = (extract-info master)[zig_version]
    var @dev-versions = (find $ZIG_ROOT -maxdepth 1 -ctime +3 -type d -name "*-dev.*")

    var old_zig = []
    all [$@dev-versions] | peach {|dev|
        if (str:contains $dev $latest_zig) {
            break
        } else {
             set old_zig = (conj $old_zig $dev)
        }
     }

     rm -rf $@old_zig stdout>$os:dev-null
}

fn download-zig {|tarball basename new_zig_exe install_dir_link zig_version|
    remove-old-zig

    try {
        echo "Downloading repository..."
        curl --output-dir $TMPDIR --remote-name  --continue-at - $tarball
        echo "Extracting "$TMPDIR/$basename" to "$ZIG_ROOT
        bsdtar --directory $ZIG_ROOT --extract --xz --file $TMPDIR/$basename
        update-symlink $new_zig_exe $install_dir_link $zig_version
    } catch err {
        put $err
        echo (styled "Error: update failed!" red)
        os:remove-all $ZIG_ROOT/$zig_version
    }
}

fn is-latest {|install_dir_link zig_version|
    if (and (os:exists &follow-symlink=$true $install_dir_link) ^
         (==s (os:eval-symlinks $install_dir_link) $ZIG_ROOT/$zig_version)) {
        put $true
    } else {
        put $false
    }
}

fn set-default {|new_zig_exe zig_version|
    # set/update which binary is the default zig installation
    if (and ?(os:stat $new_zig_exe) (==s (os:stat $new_zig_exe)[type] symlink)) {
        if (os:exists $BIN_DIR/zig) {
            os:remove $BIN_DIR/zig
        }
        os:symlink $new_zig_exe $BIN_DIR/zig
        echo "set default zig to "(styled $zig_version green)
    } else {
        fail "install "$zig_version" before trying to set it as the default"
    }
}

fn finish {|new_zig_exe zig_version basename|
    echo "finished updating to "$zig_version
    echo "Current version is now: "(styled ($new_zig_exe version) bold green)
    os:remove-all $TMPDIR/$basename
}

fn update-zig {|branch tarball basename new_zig_exe install_dir_link zig_version|
    if (is-latest $install_dir_link $zig_version) {
        echo "The current "(styled $zig_version bold green)" is the latest version!"
    } else {
        if (==s $branch "master") {
            echo "Updating to "$zig_version
        } else {
            echo "Installing "$zig_version
        }
        download-zig $tarball $basename $new_zig_exe $install_dir_link $zig_version
        set-default $new_zig_exe $zig_version
        finish $new_zig_exe $zig_version $basename
    }
}

var usage = ^
'Usage:
zvm [-install master | 0.15.2 | 0.14.1] [-default]
'

fn main {|&install=master &set=master &default=$false|
    if $default {
        start
        var info = (extract-info $set)
        set-default $info[new_zig_exe] $info[zig_version]
    } else {
        start
        var info = (extract-info $install)
        update-zig $install $info[tarball] $info[basename] ^
            $info[new_zig_exe] $info[install_dir_link] $info[zig_version]
    }
}

fn zvm {|@args|
    flag:call $main~ [$@args] &on-parse-error={|_| print $usage; fail "zvm called with incorrect arguments"}
}
