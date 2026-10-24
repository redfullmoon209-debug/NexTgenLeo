"""Run Godot + test server in one process group, with an isolated database."""
import os
from pathlib import Path
import subprocess
import tempfile
import time
import urllib.request

root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as temp:
    server=subprocess.Popen(['python',str(root/'server/server.py')],env={**os.environ,'LEO_DB':str(Path(temp)/'network.sqlite3')})
    try:
        for _ in range(50):
            try:
                urllib.request.urlopen('http://127.0.0.1:8765/health',timeout=.1)
                break
            except Exception:time.sleep(.1)
        # Per-test token filename is cleaned, otherwise a previous guest references another DB.
        user_home=Path(temp)/'user'
        user_home.mkdir()
        result=subprocess.run([os.environ.get('GODOT_BIN','godot'),'--headless','--path',str(root),'--script','res://tests/network_test.gd'],env={**os.environ,'XDG_DATA_HOME':str(user_home)},capture_output=True,text=True,timeout=25)
        print(result.stdout,result.stderr)
        if result.returncode or 'ERROR:' in result.stderr or 'FAIL:' in result.stdout+result.stderr:
            raise SystemExit(1)
    finally:
        server.terminate();server.wait(timeout=10)
