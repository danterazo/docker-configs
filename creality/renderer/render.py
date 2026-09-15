#!/usr/bin/env python3
import json
import os
import secrets
import shutil
import subprocess
import threading
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(os.environ.get("TIMELAPSE_ROOT", "/data"))
FRAMES: Path = ROOT / "frames"
RENDERED = ROOT / "rendered"
STATE = ROOT / "state"
FAILED = ROOT / "failed"
JOBS = STATE / "jobs"
LOCKS = STATE / "locks"

TOKEN = os.environ["TIMELAPSE_WEBHOOK_TOKEN"]
FPS = os.environ.get("TIMELAPSE_FPS", "30")
CRF = os.environ.get("TIMELAPSE_CRF", "20")
PRESET = os.environ.get("TIMELAPSE_PRESET", "medium")
MAX_WIDTH = os.environ.get("TIMELAPSE_MAX_WIDTH", "1920")
STABILITY_SECONDS = int(os.environ.get("TIMELAPSE_STABILITY_SECONDS", "20"))

for path in (FRAMES, RENDERED, JOBS, LOCKS, FAILED):
    path.mkdir(parents=True, exist_ok=True)

job_lock = threading.Lock()


def now():
    return datetime.now(timezone.utc).isoformat()


def write_json(path, value):
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(value, indent=2) + "\n")
    temp.replace(path)


def frame_files():
    return sorted(
        p for p in FRAMES.glob("frame*.jpg")
        if p.is_file()
    )


def stable_frames():
    first = frame_files()
    if not first:
        return []

    first_state = [(p.name, p.stat().st_size, p.stat().st_mtime_ns) for p in first]
    time.sleep(STABILITY_SECONDS)

    second = frame_files()
    second_state = [(p.name, p.stat().st_size, p.stat().st_mtime_ns) for p in second]

    return second if first_state == second_state else []


def render_job(job_id):
    job_file = JOBS / f"{job_id}.json"
    lock_file = LOCKS / f"{job_id}.lock"

    with job_lock:
        if lock_file.exists():
            return
        lock_file.write_text(now() + "\n")

    try:
        job = json.loads(job_file.read_text())
        job["status"] = "waiting_for_stable_frames"
        job["updated_at"] = now()
        write_json(job_file, job)

        frames = stable_frames()
        if not frames:
            job["status"] = "failed"
            job["error"] = "No frames found or frame directory still changing"
            job["updated_at"] = now()
            write_json(job_file, job)
            return

        snapshot_dir = FAILED / f"{job_id}.frames"
        snapshot_dir.mkdir(parents=True, exist_ok=False)

        for src in frames:
            shutil.copy2(src, snapshot_dir / src.name)

        job["frame_count"] = len(frames)
        job["snapshot_dir"] = str(snapshot_dir)
        job["status"] = "rendering"
        job["updated_at"] = now()
        write_json(job_file, job)

        temporary = RENDERED / f".{job_id}.partial.mp4"
        final = RENDERED / f"{job_id}.mp4"

        command = [
            "ffmpeg", "-hide_banner", "-nostdin", "-y",
            "-framerate", FPS,
            "-start_number", "1",
            "-i", str(snapshot_dir / "frame%06d.jpg"),
            "-vf", f"scale='min({MAX_WIDTH},iw)':-2:flags=lanczos,format=yuv420p",
            "-c:v", "libx264",
            "-preset", PRESET,
            "-crf", CRF,
            "-movflags", "+faststart",
            str(temporary),
        ]

        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )

        (STATE / "logs" / f"{job_id}.ffmpeg.log").parent.mkdir(
            parents=True, exist_ok=True
        )
        (STATE / "logs" / f"{job_id}.ffmpeg.log").write_text(result.stdout)

        if result.returncode != 0 or not temporary.exists() or temporary.stat().st_size == 0:
            job["status"] = "failed"
            job["error"] = f"ffmpeg exit code {result.returncode}"
            job["updated_at"] = now()
            write_json(job_file, job)
            temporary.unlink(missing_ok=True)
            return

        temporary.replace(final)

        job["status"] = "rendered"
        job["output_file"] = str(final)
        job["updated_at"] = now()
        write_json(job_file, job)

    except Exception as exc:
        if job_file.exists():
            job = json.loads(job_file.read_text())
            job["status"] = "failed"
            job["error"] = repr(exc)
            job["updated_at"] = now()
            write_json(job_file, job)
    finally:
        lock_file.unlink(missing_ok=True)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def send_json(self, status, body):
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path == "/healthz":
            self.send_json(200, {"status": "healthy"})
            return
        self.send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/v1/jobs":
            self.send_json(404, {"error": "not found"})
            return

        expected = f"Bearer {TOKEN}"
        if not secrets.compare_digest(self.headers.get("Authorization", ""), expected):
            self.send_json(401, {"error": "unauthorized"})
            return

        length = int(self.headers.get("Content-Length", "0"))
        try:
            incoming = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self.send_json(400, {"error": "invalid JSON"})
            return

        printer = "".join(
            c if c.isalnum() or c in "-_" else "_"
            for c in str(incoming.get("printer", "k1c"))
        )
        job_id = f"{printer}-{datetime.now().strftime('%Y%m%dT%H%M%S')}"
        job_file = JOBS / f"{job_id}.json"

        job = {
            "job_id": job_id,
            "printer": printer,
            "event": incoming.get("event", "print_end"),
            "requested_at": now(),
            "updated_at": now(),
            "status": "queued",
            "frame_count": None,
        }

        write_json(job_file, job)
        threading.Thread(target=render_job, args=(job_id,), daemon=True).start()
        self.send_json(202, {"job_id": job_id, "status": "queued"})


ThreadingHTTPServer(("0.0.0.0", 8095), Handler).serve_forever()
