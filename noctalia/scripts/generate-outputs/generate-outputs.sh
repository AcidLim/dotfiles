#!/usr/bin/env bash

set -e

OUTPUT="$HOME/.config/niri/noctalia/outputs.kdl"

mkdir -p "$(dirname "$OUTPUT")"

{
cat <<EOF
// ==================================================
// 由 generate-noctalia-outputs.sh 自动生成
// 请勿直接修改此文件
// 生成时间: $(date '+%F %T')
// ==================================================

EOF

niri msg outputs | awk '

function reset() {
    name=""
    current_res=""
    modes=""
    scale=""
    x=""
    y=""
    in_modes=0
}


/^Output / {

    if (name != "") {
        print_output()
    }

    reset()

    match($0, /\(([^)]*)\)/, m)
    name=m[1]

}


/Current mode:/ {

    # Current mode: 2560x1600 @ 60.000 Hz
    current_res=$3

}


/^[ ]+Available modes:/ {

    in_modes=1
    next

}


/^[ ]+Scale:/ {

    scale=$2

}


/^[ ]+Logical position:/ {

    # 格式:
    # Logical position: 0, 0

    gsub(",", "", $3)
    gsub(",", "", $4)

    x=$3
    y=$4

}


/^[ ]+[0-9]+x[0-9]+@/ && in_modes {

    mode=$1

    gsub(/[(),]/,"",mode)

    modes=modes "\n" mode

}


/^$/ {

    in_modes=0

}


function print_output() {

    if (name == "")
        return


    best=""
    best_hz=0


    split(modes,list,"\n")


    for(i in list) {

        if(list[i] == "")
            continue


        if(match(list[i], /^([0-9]+x[0-9]+)@([0-9.]+)/, m)) {

            resolution=m[1]
            hz=m[2]


            # 只匹配当前分辨率

            if(resolution == current_res && hz > best_hz) {

                best=list[i]
                best_hz=hz

            }

        }

    }


    # 如果没找到匹配分辨率
    # 回退到当前模式

    if(best == "")
        best=current_res"@"0


    if(scale == "")
        scale=1


    if(x == "")
        x=0


    if(y == "")
        y=0


    print "output \"" name "\" {"

    print "    mode \"" best "\""

    print "    scale " scale

    print "    position x=" x " y=" y

    print "    layout {"

    print "        gaps 8"

    print "    }"

    print "}"

    print ""

}


END {

    print_output()

}

'

} > "$OUTPUT"


echo "Generated:"
echo "$OUTPUT"
