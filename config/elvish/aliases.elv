use store
use path
use os
use file

# user modules
use zvm
use rgf
use sh

edit:add-var zvm~ $zvm:zvm~
edit:add-var rgf~ $rgf:rgf~
edit:add-var display-power-options~ $sh:display_power_options~

set edit:insert:binding[Alt-l] = { edit:clear }

fn el { exec elvish }
edit:add-var el~ $el~

fn ls {|@options_and_path|
  e:ls --color=always --hyperlink=always --classify $@options_and_path
}
edit:add-var ls~ $ls~

fn l {|@path|
  var @gitignore = (if (os:exists .gitignore) { cat .gitignore } else { echo })
  ls --almost-all --format=long --human-readable --inode --ignore-backups ^
  --ignore=.git --ignore=$@gitignore $@path
}
edit:add-var l~ $l~

fn Ls {|@files|
  sudo ls --almost-all --format=long --human-readable --inode $@files
}
edit:add-var Ls~ $Ls~

set edit:command-abbr["lh"] = "ls --hyperlink"
set edit:command-abbr["lr"] = "ls --recursive"
set edit:abbr["less"] = "less -R"

fn md {|@path| mkdir --parents --verbose $@path }
edit:add-var md~ $md~

fn Md {|@path| sudo mkdir --parents --verbose $@path }
edit:add-var md~ $md~

fn mc {|path| md $path ; cd $path }
edit:add-var mc~ $mc~

fn rd {|path| rmdir --parents --verbose $path}
edit:add-var rd~ $rd~

fn rm {|@path| e:rm --interactive=once --verbose --recursive $@path }
edit:add-var rm~ $rm~

fn Rm {|@path| sudo rm --interactive=once --verbose --recursive $@path }
edit:add-var Rm~ $Rm~

fn full-path {|path|
  path:abs (os:eval-symlinks $path)
}

fn is-full-path {|path|
  try {
    os:exists (full-path $path)
  } catch err {
    put $false
  }
}

fn ln {|@sources destination|
  for path $sources {
    if (not (is-full-path $path)) {
      fail "`"$path"` is not an absolute path"
    }
  }
  e:ln --interactive --relative --symbolic --verbose $@sources $destination
}
edit:add-var ln~ $ln~

fn hln {|@source destination|
  e:ln --interactive --verbose $@source $destination
}
edit:add-var hln~ $hln~

fn Hln {|@source destination|
  sudo ln --interactive --verbose $@source $destination
}
edit:add-var Hln~ $Hln~

fn Ln {|@source destination|
  sudo ln --interactive --relative --symbolic --verbose $@source $destination
}
edit:add-var Ln~ $Ln~

fn cp {|@source destination|
  e:cp --interactive --dereference --recursive --verbose --reflink=auto ^
  --sparse=auto --archive $@source $destination
}
edit:add-var cp~ $cp~

fn Cp {|@source destination|
  sudo cp --interactive --dereference --recursive --verbose --reflink=auto ^
  --sparse=auto $@source $destination
}
edit:add-var Cp~ $Cp~

fn mv {|@source destination|
  e:mv --interactive --update --verbose $@source $destination
}
edit:add-var mv~ $mv~

fn Mv {|@source destination|
  sudo mv --interactive --update --verbose $@source $destination
}
edit:add-var Mv~ $Mv~

fn lb {
  lsblk -oPATH,MOUNTPOINTS,LABEL,FSTYPE,SIZE,FSAVAIL,FSUSED,PARTUUID,MAJ:MIN
}
edit:add-var lb~ $lb~

fn du {|@file| e:du -h -d 1 $@file }
edit:add-var du~ $du~

fn tarx {|archive @files| bsdtar -xvf $archive $@files }
edit:add-var tarx~ $tarx~

fn tarv {|archive| bsdtar -tvf $archive }
edit:add-var tarv~ $tarv~

fn tarzip {|archive @source|
  bsdtar --auto-compress --option --option="zip:compression=deflate" ^
  -cvf  $archive $@source
}
edit:add-var tarzip~ $tarzip~

fn targzip {|archive @source|
  bsdtar --auto-compress --option="gzip:compression-level=9" -cvf  $archive ^
  $@source
}
edit:add-var targzip~ $targzip~

fn tarzst {|archive @source|
  bsdtar --auto-compress --option="zstd:compression-level=22,zstd:threads=0" ^
  -cvf  $archive $@source
}
edit:add-var tarzst~ $tarzst~

fn tarxz {|archive @source|
  bsdtar --auto-compress --option="xz:compression-level=9,xz:threads=0" ^
  -cvf $archive $@source
}
edit:add-var tarxz~ $tarxz~

fn cat {|@options| e:bat --style=numbers,changes $@options }
edit:add-var cat~ $cat~

fn diff {|file reference|
  e:diff --report-identical-files --side-by-side --suppress-common-lines ^
  --expand-tabs --suppress-blank-empty --minimal --speed-large-files ^
  --color=always $file $reference
}
edit:add-var diff~ $diff~

fn grep {|regex @options|
    # Check if the current processes stdin is a terminal or pipe
    if (file:is-tty 0) {
       # Input is from a Terminal (>)
      if (has-external rg) {
        e:rg  --engine=auto --mmap --no-unicode --smart-case $regex $@options
      } elif (and (has-external git) ?(e:git rev-parse --is-inside-work-tree stdout>$os:dev-null stderr>&stdout)) {
        env LC_ALL=C git grep --perl-regexp --line-number --column --break ^
        --heading --ignore-case -e $regex $@options
      } elif (has-external git) {
        env LC_ALL=C git grep --perl-regexp --no-index --line-number --column ^
        --break --heading --ignore-case -e $regex $@options
      } else {
        var @gitignore = (if (os:exists .gitignore) { cat .gitignore } else { echo ' ' })
        echo "'"$@gitignore"'"
        env LC_ALL=C grep --perl-regexp --color=always --line-number ^
        --binary-files=without-match --devices=skip --exclude='.*' ^
        --exclude-dir='.[a-zA-Z0-9]*' --exclude-dir='*cache*' ^
        --exclude-dir={zig-out zig-pkg node_modules build dist target vendor __pycache__} ^
        --exclude={$@gitignore} --exclude-dir={$@gitignore} --recursive --ignore-case ^
        --regexp $regex $@options
      }
    } else {
      # Input is a Pipe (|) or a Redirected File (<)
      if (has-external rg) {
        e:rg  --engine=auto --no-unicode --smart-case $regex $@options
      } else {
        env LC_ALL=C grep --perl-regexp --color=always --ignore-case ^
        --regexp $regex $@options
      }
    }
}
edit:add-var grep~ $grep~

# implement underline for grep
# https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
# https://github.com/kovidgoyal/kitty/blob/master/kittens/hyperlinked_grep/main.go
# https://sw.kovidgoyal.net/kitty/kittens/hints/
# fn mg {|@args|
#   kitten hyperlinked_grep --smart-case $@args
# }
# edit:add-var mg~ $mg~

fn sed {|regex file| e:sed --regexp-extended --in-place=.bak ^
        --expression=$regex $file }
edit:add-var sed~ $sed~

fn icat {|file| kitten icat $file }
edit:add-var icat~ $icat~

fn sort-inplace {|file|
  order < $file | compact | to-lines stdout> $E:PREFIX/tmp/sort
  e:mv $E:PREFIX/tmp/sort (path:abs $file)
}
edit:add-var sort-inplace~ $sort-inplace~

fn history-export {
  edit:command-history | peach {|hist| put $hist[cmd]} | order | compact | to-lines
}
edit:add-var history-export~ $history-export~

fn store-hist {
  history-export stdout> $E:PREFIX/tmp/history
  # https://stackoverflow.com/questions/29244351/how-to-sort-a-file-in-place#29244408
  sort-inplace $E:ELVRC/history
}

fn history-diff {
  store-hist
  # https://www.oreilly.com/library/view/bash-cookbook/0596526784/ch17s16.html
  # comm -23 /tmp/history  $E:ELVRC/history
  # NOTE: comm works only with the external sort command
  # Show lines in /tmp/history(current history) which aren't in elvish/history(old history)
  e:grep -Fxvf $E:ELVRC/history $E:PREFIX/tmp/history
}
edit:add-var hd~ $history-diff~

fn history-import {
  store-hist
  # update current history with updated elvish/history
  if ?(e:grep -Fxvf $E:PREFIX/tmp/history $E:ELVRC/history stdout> $E:PREFIX/tmp/diffhistory) {
     cat $E:PREFIX/tmp/diffhistory | peach {|hist| store:add-cmd $hist}
  } else {
    echo "Current history is up to date"
  }
}
edit:add-var history-import~ $history-import~

fn hu { edit:history:fast-forward }
edit:add-var hu~ $hu~

fn ee { $E:EDITOR $E:ELVRC/env.elv }
edit:add-var ee~ $ee~

fn eh { $E:EDITOR $E:ELVRC/history }
edit:add-var eh~ $eh~

fn ea { $E:EDITOR $E:ELVRC/aliases.elv }
edit:add-var ea~ $ea~

fn rc { $E:EDITOR $E:ELVRC/rc.elv }
edit:add-var rc~ $rc~

fn er { $E:EDITOR $E:DOTFILES/config/river/init.zig }
edit:add-var er~ $er~

fn update-mirrors {
  sudo reflector "@"$E:DOTFILES/etc/xdg/reflector/reflector.conf ^
  stdout>$os:dev-null stderr>$os:dev-null
 }
edit:add-var update-mirrors~ $update-mirrors~

fn pacman {|@args|
    try {
      e:pacman $@args stderr>$os:dev-null
    } catch err {
      if (has-external yay) {
          var is_ok = ?(yay $@args)
          if (not (put $is_ok)) {
            fail $is_ok
          }
        } else {
          fail $err
        }
    }
}
edit:add-var pacman~ $pacman~

#pacman aliases
set edit:command-abbr['pmi'] = 'pacman -S'
set edit:command-abbr['pmp'] = 'pacman -Rcunsv'
set edit:command-abbr['pmii'] = 'pacman -Qii'
set edit:command-abbr['pmsi'] = 'pacman -Sii'

fn pml { pacman -Qe }
edit:add-var pml~ $pml~

fn pmu { pacman -Syu }
edit:add-var pmu~ $pmu~

fn pmuf { pacman -Fy }
edit:add-var pmuf~ $pmuf~

fn pmlr { pacman -Qmq }
edit:add-var pmlr~ $pmlr~

fn pmlf {|package|
  try {
    pacman -Ql $package stderr>$os:dev-null
  } catch err {
    try {
      pacman -Fl $package
    } catch err {
      var reason = $err[reason]
      echo (styled $reason[cmd-name] red)" exited with "(styled $reason[exit-status] red)": could not list files for the package "(styled $package blue)
    }
  }
}
edit:add-var pmlf~ $pmlf~

fn pmb {|file|
  if (has-external $file) {
    set file = (which $file)
  }
  if (and (path:is-abs $file) (os:exists &follow-symlink=$true $file)) {
    try {
      pacman -Qo $file
    } catch err {
      var reason = $err[reason]
      echo (styled $reason[cmd-name] red)" exited with "(styled $reason[exit-status] red)": could not find the package which owns "(styled $file blue)
    }
  } else {
    fail "requires the full path to the file you want to find the package it belongs to"
  }
}
edit:add-var pmb~ $pmb~

# https://github.com/elves/elvish/issues/1775
fn pmc { pacman -Rsn (pacman -Qdtq) }
edit:add-var pmc~ $pmc~

fn pmcc { pacman -Sc }
edit:add-var pmcc~ $pmcc~

fn pms {|package|
  try {
     pacman -Qs $package
    } catch err {
      try {
        pacman -Fx $package
      } catch err {
        try {
          pacman -Ss $package
        } catch err {
          var reason = $err[reason]
          echo (styled $reason[cmd-name] red)" exited with "(styled $reason[exit-status] red)": package `"(styled $package blue)"` not found in default repo"
        }
      }
    }
}
edit:add-var pms~ $pms~

#Git aliases
set edit:command-abbr['ga'] = 'git add'
# https://stackoverflow.com/questions/1085162/commit-only-part-of-a-files-changes-in-git
set edit:command-abbr['gap'] = 'git add --patch'
set edit:command-abbr['gd'] = 'git diff'
set edit:command-abbr['gds'] = 'git diff --staged'
set edit:command-abbr['gc'] = 'git commit -s'
# see changes you are about to commit
set edit:command-abbr['gcv'] = 'git commit --verbose'
set edit:command-abbr['gt'] = 'git tag -s'
set edit:command-abbr['glf'] = 'git log --follow -p'
set edit:command-abbr['gg'] = 'git grep --recurse-submodules -I'
set edit:command-abbr['gmv'] = 'git mv'
set edit:command-abbr['grm'] = 'git rm -r'
set edit:command-abbr['gsh'] = 'git show'
set edit:command-abbr['glt'] = "git log --stat -1"
set edit:command-abbr['gsml'] = "git log --submodule -p"
set edit:command-abbr['gsmi'] = "git submodule update --init --recursive"
set edit:command-abbr['gsmu'] = "git submodule update --remote --rebase"

fn gl {|@commit_hash|
  if (eq $commit_hash []) {
    git log --graph --oneline --decorate
  } else {
   git show $@commit_hash
   # git diff $commit_hash[0]'~' $commit_hash[0]
  }
}
edit:add-var gl~ $gl~

fn glp {
  git log -p
}
edit:add-var glp~ $glp~

fn gs {
  git status -s
}
edit:add-var gs~ $gs~

fn gst {
  git status
}
edit:add-var gst~ $gst~

fn gp {
  git push
}
edit:add-var gp~ $gp~

fn gpu {
  git pull
}
edit:add-var gpu~ $gpu~

fn gcl {|@repo|
  # https://stackoverflow.com/questions/17714159/how-do-i-undo-a-single-branch-clone/60846265#60846265
  # https://stackoverflow.com/questions/11552437/git-pull-remote-branch-cannot-find-remote-ref/67200162#67200162
  git clone --filter=tree:0 $@repo
}
edit:add-var gcl~ $gcl~

fn git-repack {
  # reduce size of .git
  # https://stackoverflow.com/a/5613380/12007740
  git repack -a -d -f --depth=250 --window=250
}

fn fzt {|@path|
  $E:DOTFILES/fzf/fzt.sh $@path
}
edit:add-var fzt~ $fzt~

fn Hx {|@files| sudo --preserve-env $E:EDITOR $@files }
edit:add-var Hx~ $Hx~

fn bunx {|@options| e:bunx --bun $@options }
edit:add-var bunx~ $bunx~

fn bun {|@options| e:bun --bun $@options }
edit:add-var bun~ $bun~
fn encrypt {|in out|
  openssl enc -aes-256-cbc -pbkdf2 -iter 310000 -md sha256 -salt -in $in -out $out
}
edit:add-var encrypt~ $encrypt~

fn decrypt {|in out|
  openssl enc -aes-256-cbc -pbkdf2 -iter 310000 -md sha256 -salt -d -in $in -out $out
}
edit:add-var decrypt~ $decrypt~

set edit:command-abbr['zbr'] = 'zig build -Doptimize=ReleaseFast'
set edit:command-abbr['zb'] = 'zig build'

fn zr {|@exe_options|
    if (has-external zig) {
         zig build run -- $@exe_options
     } else {
        echo 'install zig on your system'
     }
 }
edit:add-var zr~ $zr~

fn z++ {|@args|
  if (has-external zig) {
     zig c++ -std=c++2c -fexperimental-library $@args
  } else {
     fail "install zig language compiler on your system"
  }
}
edit:add-var z++~ $"z++~"

fn zcc {|@args|
  if (has-external zig) {
     zig cc -std=c2y $@args
  } else {
     fail "install zig language compiler on your system"
  }
}
edit:add-var zcc~ $zcc~

fn a2l {|@argv|
  addr2line --functions --inlines --pretty-print --demangle --exe $argv[0] --addresses $argv[1..]
 }
edit:add-var a2l~ $a2l~

fn objdump {|exe| e:objdump -dSrwC -Mintel $exe }
edit:add-var objdump~ $objdump~
