#!/usr/bin/env python3
"""Tests for new-project.sh as a person uses it: typed into a real terminal.

The script behaves differently on a terminal (it collects pasted lines and
offers to open an agent), so these cases drive it through a pseudo-terminal.
Fake `claude` / `codex` programs stand in for the real agents and record how
they were started. Everything runs in a throwaway HOME.

Usage: python3 tests/terminal.py
"""
import os
import pty
import select
import shutil
import signal
import stat
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIRM = "Create this project workspace?"
results = []


def check(label, condition, detail=""):
    results.append(bool(condition))
    print(("PASS  " if condition else "FAIL  ") + label + ("" if condition else f"  [{detail}]"))


class Session:
    """One run of new-project.sh on a pseudo-terminal."""

    def __init__(self, base, agents, argv=("scripts/new-project.sh",), home=None):
        self.base = base
        self.home = home or os.path.join(base, "home")
        self.bindir = os.path.join(base, "bin")
        self.log = os.path.join(base, "launch.log")
        os.makedirs(self.home, exist_ok=True)
        os.makedirs(self.bindir)
        for name in agents:
            path = os.path.join(self.bindir, name)
            with open(path, "w") as handle:
                handle.write('#!/bin/bash\nprintf "%s\\n%s\\n%s\\n" "' + name + '" "$PWD" "$1" > "$FAKE_LOG"\n')
            os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)
        self.output = ""
        self.exit_code = None
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.environ["HOME"] = self.home
            os.environ["FAKE_LOG"] = self.log
            # System directories plus the fake agents only, so a real claude or
            # codex installed on this machine is never found or started.
            os.environ["PATH"] = self.bindir + ":/usr/bin:/bin"
            os.chdir(ROOT)
            os.execv("/bin/bash", ["/bin/bash", *argv])

    def _read(self, timeout):
        ready, _, _ = select.select([self.fd], [], [], timeout)
        if not ready:
            return True
        try:
            data = os.read(self.fd, 4096)
        except OSError:
            return False
        if not data:
            return False
        self.output += data.decode(errors="replace")
        return True

    def expect(self, text, timeout=10):
        """Wait until `text` appears in the output that has not been matched yet."""
        start = getattr(self, "_mark", 0)
        deadline = time.time() + timeout
        while time.time() < deadline:
            position = self.output.find(text, start)
            if position != -1:
                self._mark = position + len(text)
                return True
            if not self._read(0.1):
                break
        position = self.output.find(text, start)
        if position != -1:
            self._mark = position + len(text)
            return True
        return False

    def send(self, text):
        try:
            os.write(self.fd, text.encode())
        except OSError:
            pass  # the script already exited; the checks that follow report it

    def finish(self, timeout=10):
        """Wait for the script to exit and return its exit code (None if it hung)."""
        deadline = time.time() + timeout
        while time.time() < deadline:
            done, status = os.waitpid(self.pid, os.WNOHANG)
            if done:
                self.exit_code = os.WEXITSTATUS(status) if os.WIFEXITED(status) else -1
                while self._read(0.05):
                    pass
                return self.exit_code
            self._read(0.1)
        os.kill(self.pid, signal.SIGKILL)
        os.waitpid(self.pid, 0)
        return None

    def brief_body(self, slug):
        path = os.path.join(self.home, "Development", slug, "PROJECT_BRIEF.md")
        if not os.path.exists(path):
            return None
        text = open(path, encoding="utf-8").read()
        return text.split("## Product description\n\n")[1].split("\n\n## Everything else")[0]

    def launched(self):
        if not os.path.exists(self.log):
            return None
        name, cwd, prompt = open(self.log).read().split("\n")[:3]
        return name, os.path.realpath(cwd), prompt

    def workspace(self, slug):
        return os.path.realpath(os.path.join(self.home, "Development", slug))


def start(agents=(), argv=("scripts/new-project.sh",), home=None):
    """Start a run. Pass `home` to reuse the HOME of an earlier run."""
    return Session(tempfile.mkdtemp(prefix="factory-test-"), agents, argv, home)


def enter_project(session, name="Demo App", brief="A small demo app.\n"):
    session.expect("Project name:")
    session.send(name + "\n")
    session.expect("> ")
    session.send(brief)
    return session.expect(CONFIRM)


def cleanup(session):
    shutil.rmtree(session.base, ignore_errors=True)


# ---- entering the brief ----------------------------------------------------

s = start()
reached = enter_project(s, brief="A chat app where people make friends.\n")
check("one ENTER submits the brief", reached, s.output[-200:])
s.send("y\n")
check("single line: exits 0", s.finish() == 0, s.exit_code)
check("single line: brief saved", s.brief_body("demo-app") == "A chat app where people make friends.", s.brief_body("demo-app"))
cleanup(s)

s = start()
reached = enter_project(s, brief="Line one.\nLine two.\n\nParagraph two.\n")
check("pasted lines do not answer the confirmation", reached, s.output[-200:])
s.send("y\n")
check("multi-line paste: exits 0", s.finish() == 0, s.exit_code)
check("multi-line paste: all lines kept", s.brief_body("demo-app") == "Line one.\nLine two.\n\nParagraph two.", s.brief_body("demo-app"))
cleanup(s)

s = start()
enter_project(s, brief="Dost banane ki app \x1b\x1b دوست\n")
s.send("y\n")
s.finish()
check("ESC removed, non-English text kept", s.brief_body("demo-app") == "Dost banane ki app  دوست", repr(s.brief_body("demo-app")))
cleanup(s)

s = start()
s.expect("Project name:")
s.send("Demo App\n")
s.expect("> ")
s.send("\n")
check("empty brief: exits 1", s.finish() == 1, s.exit_code)
check("empty brief: nothing created", s.brief_body("demo-app") is None)
cleanup(s)

s = start(["claude"])
enter_project(s)
s.send("n\n")
check("answer n: exits 0", s.finish() == 0, s.exit_code)
check("answer n: nothing created", s.brief_body("demo-app") is None)
check("answer n: no agent question", " now? " not in s.output and "now? (Y/n)" not in s.output)
cleanup(s)

# ---- opening the agent -----------------------------------------------------

s = start(["claude"])
enter_project(s)
s.send("y\n")
asked = s.expect("Open the project in Claude Code now? (Y/n):")
check("Claude only: asks to open Claude Code", asked, s.output[-200:])
s.send("\n")
s.finish()
launch = s.launched()
check("Claude only + ENTER: Claude started", launch is not None and launch[0] == "claude", launch)
check("Claude only + ENTER: started in the new folder", launch is not None and launch[1] == s.workspace("demo-app"), launch)
check("Claude only + ENTER: first message names the skill", launch is not None and "expo-project-factory" in launch[2], launch)
cleanup(s)

s = start(["claude"])
enter_project(s)
s.send("y\n")
s.expect("Open the project in Claude Code now? (Y/n):")
s.send("n\n")
check("Claude only + n: exits 0", s.finish() == 0, s.exit_code)
check("Claude only + n: nothing started", s.launched() is None)
check("Claude only + n: next steps printed", "Follow FACTORY_START_HERE.md" in s.output)
cleanup(s)

s = start(["codex"])
enter_project(s)
s.send("y\n")
asked = s.expect("Open the project in Codex now? (Y/n):")
check("Codex only: asks to open Codex", asked, s.output[-200:])
s.send("y\n")
s.finish()
launch = s.launched()
check("Codex only + y: Codex started in the new folder", launch is not None and launch[0] == "codex" and launch[1] == s.workspace("demo-app"), launch)
cleanup(s)

s = start(["claude", "codex"])
enter_project(s)
s.send("y\n")
asked = s.expect("1) Claude Code  2) Codex")
check("both installed: offers a choice", asked, s.output[-200:])
s.send("2\n")
s.finish()
launch = s.launched()
check("both + 2: Codex started", launch is not None and launch[0] == "codex", launch)
cleanup(s)

s = start(["claude", "codex"])
enter_project(s)
s.send("y\n")
s.expect("1) Claude Code  2) Codex")
s.send("\n")
check("both + ENTER: exits 0", s.finish() == 0, s.exit_code)
check("both + ENTER: nothing started", s.launched() is None)
cleanup(s)

s = start()
enter_project(s)
s.send("y\n")
check("no agent installed: exits 0", s.finish() == 0, s.exit_code)
check("no agent installed: no question", " now? " not in s.output and "now? (Y/n)" not in s.output)
check("no agent installed: next steps printed", "Follow FACTORY_START_HERE.md" in s.output)
cleanup(s)

# ---- the expo-factory command ------------------------------------------------

s = start(argv=("bin/expo-factory", "new"))
asked = s.expect("Projects folder [")
check("expo-factory new: asks once where projects go", asked, s.output[-200:])
s.send("~/My Apps\n")
reached = enter_project(s)
check("expo-factory new: continues to the brief", reached, s.output[-200:])
s.send("y\n")
check("expo-factory new: exits 0", s.finish() == 0, s.exit_code)
project = os.path.join(s.home, "My Apps", "demo-app", "PROJECT_BRIEF.md")
check("expo-factory new: project created in the chosen folder", os.path.exists(project))
saved = os.path.join(s.home, ".config", "expo-project-factory", "projects-dir")
check("expo-factory new: folder saved", os.path.exists(saved) and open(saved).read().strip() == os.path.join(s.home, "My Apps"))

# Second run in the same HOME: the question must not come back.
s2 = start(argv=("bin/expo-factory", "new"), home=s.home)
reached = enter_project(s2, name="Second App")
s2.send("y\n")
s2.finish()
check("expo-factory new: second run does not ask again", reached and "Projects folder [" not in s2.output, s2.output[:200])
check("expo-factory new: second project in the saved folder", os.path.exists(os.path.join(s2.home, "My Apps", "second-app", "PROJECT_BRIEF.md")))
cleanup(s2)
cleanup(s)

s = start(argv=("bin/expo-factory", "new"))
s.expect("Projects folder [")
s.send("\n")
enter_project(s)
s.send("y\n")
s.finish()
check("expo-factory new: ENTER keeps ~/Development", os.path.exists(os.path.join(s.home, "Development", "demo-app", "PROJECT_BRIEF.md")))
cleanup(s)

print()
print(f"{sum(results)} passed, {len(results) - sum(results)} failed")
sys.exit(0 if all(results) else 1)
