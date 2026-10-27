#!/bin/bash
# Builds a headless macOS copy of GameModel for bot calibration. Usage: prep.sh <worktree>
set -e
SIM=$(cd "$(dirname "$0")" && pwd)
python3 - "$1/SproutAndSmiles/GameModel.swift" "$SIM/GameModelSim.swift" <<'PY'
import re,sys
s=open(sys.argv[1]).read()
s=s.replace('import UIKit\n','')
s=s.replace('UserDefaults.standard','SimDefaults.standard')
s=re.sub(r'try\? await Task\.sleep\([^)]*\)\)?','await Task.yield()',s)
s=s.replace('private(set) ','').replace('private func','func').replace('private var','var').replace('private struct','struct').replace('private static','static')
s=s.replace('static let levels: [Level]','static var levels: [Level]').replace('    let moves: Int\n','    var moves: Int\n',1)
open(sys.argv[2],'w').write(s)
PY
cd "$SIM" && swiftc -O -D DEBUG -parse-as-library -o bot GameModelSim.swift Shims.swift Bot.swift 2>&1 | grep -E "error" | head -30
