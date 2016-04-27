#!/usr/bin/env bash

cd "$(dirname "$0")"/../..

gimp -i --batch-interpreter=python-fu-eval -b - << EOF
import gimpfu, glob, os

flagfile = "extras/gfx/flags/flag-60x40.xcf"
template = pdb.gimp_file_load(flagfile, flagfile)

whitelist = ["%s.tga" % a for a in "$*".split(' ') if a]

for srcfile in glob.glob("extras/gfx/flags/src/*.tga"):
    name = srcfile.split('/')[-1]
    
    if whitelist and name not in whitelist:
        continue
    
    print "Processing: ", name
    
    flag = template.duplicate()
    flaglayer = pdb.gimp_file_load_layer(flag, srcfile)
    flag.add_layer(flaglayer, len(flag.layers) - 1)
    
    if name.startswith("29-"):
        flag.layers[0].visible = False
        flag.layers[2].visible = False
        flag.layers[5].visible = False
        flag.layers[3].opacity = 30.0
        flag.layers[4].opacity = 15.0
    
    name = "ui.pk3dir/gfx/flagicons/" + name
    result = pdb.gimp_image_merge_visible_layers(flag, 1)
    pdb.gimp_file_save(flag, result, name, name)
    pdb.gimp_image_delete(flag)

pdb.gimp_image_delete(template)
pdb.gimp_quit(1)
EOF

echo "Generating animation code..."

cat << EOF > qcsrc/common/flag_anim.qc && echo

//
// AUTOGENERATED by makeflags.sh, do not modify
//

#define flag_anim_linear(frames,rate,offs) mod(floor((time) * (rate) + (offs)), frames)
#define flag_anim_sine(frames,rate,offs) (frames - 1) * (sin(time * rate + offs) * 0.5 + 0.5)

float FlagIcon_Animate(string cn) {
    switch(cn) {
$(cat "extras/gfx/flags/animinfo" | sed '/^$/d' | while read line; do
    flag="$(echo "$line" | sed -e 's/: .*//')"
    code="$(echo "$line" | sed -e 's/.*: //')"
    echo "        case \"$flag\":    return $code;"
done)
    }
    
    return -1;
}

#undef flag_anim_linear
#undef flag_anim_sine

EOF

