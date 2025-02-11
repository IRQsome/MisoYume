set -e # Enable error reporting
rm misoyume_lower.binary || true
../spin2cpp/build/flexspin -2 -E -H 360448 -O1,extrasmall,inline-single,experimental,aggressive-mem --charset=shiftjis -DFF_FS_TINY=1 -DFF_FS_NORTC=1 misoyume_upper.spin2
../spin2cpp/build/flexspin -2 -l --compress misoyume_lower.spin2