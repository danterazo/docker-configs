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
from typing import Any

ROOT: Path = Path(os.environ.get("TIMELAPSE_ROOT", default="/data"))
FRAMES: Path = ROOT / "frames"
RENDERED: Path = ROOT / "rendered"
STATE: Path = ROOT / "state"
FAILED: Path = ROOT / "failed"
JOBS: Path = STATE / "jobs"
LOCKS: Path = STATE / "locks"

TOKEN: str = os.environ["TIMELAPSE_WEBHOOK_TOKEN"]
FPS: str = os.environ.get(key="TIMELAPSE_FPS", default="30")
CRF: str = os.environ.get(key="TIMELAPSE_CRF", default="20")
PRESET: str = os.environ.get(key="TIMELAPSE_PRESET", default="medium")
MAX_WIDTH: str = os.environ.get(key="TIMELAPSE_MAX_WIDTH", default="1920")
STABILITY_SECONDS: int = int(os.environ.get(key="TIMELAPSE_STABILITY_SECONDS", default="20"))

for path in (FRAMES, RENDERED, JOBS, LOCKS, FAILED):
    path.mkdir(parents=True, exist_ok=True)

job_lock: threading.Lock = threading.Lock()


def now() -> str:
    return datetime.now(tz=timezone.utc).isoformat()


def write_json(path: Path, value: dict[str, Any]) -> None:
    temp: Path = path.with_suffix(suffix=path.suffix + ".tmp")
    temp.write_text(data=json.dumps(obj=value, indent=2) + "\n")
    temp.replace(target=path)


def frame_files() -> list[Path]:
    return sorted(p for p in FRAMES.glob(pattern="frame*.jpg") if p.is_file())


def stable_frames() -> list[Path]:
    first: list[Path] = frame_files()
    if not first:
        return []

    first_state: list[tuple[str, int, int]] = [(p.name, p.stat().st_size, p.stat().st_mtime_ns) for p in first]
    time.sleep(STABILITY_SECONDS)

    second: list[Path] = frame_files()
    second_state: list[tuple[str, int, int]] = [(p.name, p.stat().st_size, p.stat().st_mtime_ns) for p in second]

    return second if first_state == second_state else []


def render_job(job_id: str) -> None:
    job_file: Path = JOBS / f"{job_id}.json"
    lock_file: Path = LOCKS / f"{job_id}.lock"

    with job_lock:
        if lock_file.exists():
            return
        lock_file.write_text(data=now() + "\n")

    try:
        job: dict[str, Any] = json.loads(job_file.read_text())
        if not isinstance(job, dict):
            raise TypeError("job file is not a JSON object")
        job["status"] = "waiting_for_stable_frames"
        job["updated_at"] = now()
        write_json(path=job_file, value=job)

        frames: list[Path] = stable_frames()
        if not frames:
            job["status"] = "failed"
            job["error"] = "No frames found or frame directory still changing"
            job["updated_at"] = now()
            write_json(path=job_file, value=job)
            return

        snapshot_dir: Path = FAILED / f"{job_id}.frames"
        snapshot_dir.mkdir(parents=True, exist_ok=False)

        for src in frames:
            shutil.copy2(src=src, dst=snapshot_dir / src.name)

        job["frame_count"] = len(frames)
        job["snapshot_dir"] = str(snapshot_dir)
        job["status"] = "rendering"
        job["updated_at"] = now()
        write_json(path=job_file, value=job)

        temporary: Path = RENDERED / f".{job_id}.partial.mp4"
        final: Path = RENDERED / f"{job_id}.mp4"

        command: list[str] = [
            "ffmpeg",
            "-hide_banner",
            "-nostdin",
            "-y",
            "-framerate",
            FPS,
            "-start_number",
            "1",
            "-i",
            str(object=snapshot_dir / "frame%06d.jpg"),
            "-vf",
            f"scale='min({MAX_WIDTH},iw)':-2:flags=lanczos,format=yuv420p",
            "-c:v",
            "libx264",
            "-preset",
            PRESET,
            "-crf",
            CRF,
            "-movflags",
            "+faststart",
            str(object=temporary),
        ]

        result: subprocess.CompletedProcess[str] = subprocess.run(
            args=command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )

        ffmpeg_log: Path = STATE / "logs" / f"{job_id}.ffmpeg.log"
        ffmpeg_log.parent.mkdir(parents=True, exist_ok=True)
        ffmpeg_log.write_text(data=result.stdout)

        if result.returncode != 0 or not temporary.exists() or temporary.stat().st_size == 0:
            job["status"] = "failed"
            job["error"] = f"ffmpeg exit code {result.returncode}"
            job["updated_at"] = now()
            write_json(path=job_file, value=job)
            temporary.unlink(missing_ok=True)
            return

        temporary.replace(target=final)

        job["status"] = "rendered"
        job["output_file"] = str(object=final)
        job["updated_at"] = now()
        write_json(path=job_file, value=job)

    except (OSError, TypeError, ValueError) as exc:
        if job_file.exists():
            job = json.loads(job_file.read_text())
            job["status"] = "failed"
            job["error"] = repr(exc)
            job["updated_at"] = now()
            write_json(path=job_file, value=job)
    finally:
        lock_file.unlink(missing_ok=True)


class Handler(BaseHTTPRequestHandler):
    def send_json(self, status: int, body: dict[str, Any]) -> None:
        payload: bytes = json.dumps(obj=body).encode(encoding="utf-8")
        self.send_response(code=status)
        self.send_header(keyword="Content-Type", value="application/json")
        self.send_header(keyword="Content-Length", value=str(object=len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self) -> None:
        if self.path == "/healthz":
            self.send_json(status=200, body={"status": "healthy"})
            return
        self.send_json(status=404, body={"error": "not found"})

    def do_POST(self) -> None:
        if self.path != "/v1/jobs":
            self.send_json(status=404, body={"error": "not found"})
            return

        expected: str = f"Bearer {TOKEN}"
        if not secrets.compare_digest(self.headers.get(name="Authorization", failobj=""), expected):
            self.send_json(status=401, body={"error": "unauthorized"})
            return

        length: int = int(self.headers.get(name="Content-Length", failobj="0"))
        try:
            incoming: Any = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self.send_json(status=400, body={"error": "invalid JSON"})
            return

        if not isinstance(incoming, dict):
            self.send_json(status=400, body={"error": "JSON body must be an object"})
            return

        printer: str = "".join(c if c.isalnum() or c in "-_" else "_" for c in str(object=incoming.get("printer", "k1c")))
        job_id: str = f"{printer}-{datetime.now(tz=timezone.utc).strftime(format='%Y%m%dT%H%M%S')}"
        job_file: Path = JOBS / f"{job_id}.json"

        job: dict[str, Any] = {
            "job_id": job_id,
            "printer": printer,
            "event": incoming.get("event", "print_end"),
            "requested_at": now(),
            "updated_at": now(),
            "status": "queued",
            "frame_count": None,
        }

        write_json(path=job_file, value=job)
        threading.Thread(target=render_job, args=(job_id,), daemon=True).start()
        self.send_json(status=202, body={"job_id": job_id, "status": "queued"})


ThreadingHTTPServer(server_address=("0.0.0.0", 8095), RequestHandlerClass=Handler).serve_forever()
