import type {ModApi} from '@commandcode/harness';
import {spawn} from 'node:child_process';

// KV-first: identity and addressing live in AGENT_STATE (mesh.instructions,
// mesh.members.<name>). The mod subscribes broad and the agent learns its name
// from KV via the bootstrap message. MESH_* env remain as overrides only.
const SUBJECTS = (process.env.MESH_SUBJECT || 'work.>,agents.leya.>')
  .split(',').map((s) => s.trim()).filter((s) => s !== '');
// Empty queue = broadcast: every agent gets its own copy. A queue group
// load-balances, so only set MESH_QUEUE to scale one role across workers.
const QUEUE = process.env.MESH_QUEUE || '';
const NATS = process.env.NATS_BIN || 'nats';
// tiger: fallback when nats is not on PATH; spawn(2) resolves PATH, ENOENT otherwise.
const NATS_FALLBACK = '/home/prm/.cache/agent-mesh/nats-0.5.0-linux-amd64/nats';
// Reboot-proof server ensure (all-AAA): fixed URL, stable data dir, dial-first.
// The mod owns the server: every session probes on start and boots it when absent,
// so a rebooted PC needs nothing but `cmd --yolo --mod .../mesh.ts`.
const HOME = process.env.HOME || '/home/prm';
const NATS_URL = process.env.NATS_URL || 'nats://127.0.0.1:4222';
const SERVER_BIN = process.env.MESH_SERVER_BIN || `${HOME}/.agents/skills/agent-mesh/nats-server`;
const DATA_DIR = process.env.MESH_DATA_DIR || `${HOME}/.agents/skills/agent-mesh/jsdata`;
const PROBE_MS = 3000;
// steer lands after the current tool batch, mid-run. follow-up only when the run would stop, so it
// is the one to use when the agent is between turns. Neither one wakes a fully idle session.
const DELIVER: 'steer' | 'follow-up' =
  process.env.MESH_DELIVER === 'follow-up' || process.env.MESH_DELIVER === 'steer'
    ? process.env.MESH_DELIVER
    : 'steer';

// `nats sub` default output is:
//   [#1] Received on "agents.build"
//   <payload>
// Cap payloads at 4096 chars (append '…[truncated]' when cut) so one huge
// message can't blow up the transcript / context window.
const MAX_PAYLOAD = 4096;
const HEADER = /^\[#\d+\]\s+Received on "([^"]+)"$/;
// tiger: match `nats pub <subject>` inside shell_command input (command + args joined).
// The binary is often held in a shell variable (`NATS=/abs/nats; "$NATS" pub …`), which has no
// literal `nats` before the space - so accept a quoted variable token too, or OUT stays empty
// while the publish is real and the message only echoes back on IN.
const PUB_SUBJECT = /(?:nats\S*|["']?\$\{?[A-Za-z_][A-Za-z0-9_]*\}?["']?)\s+pub\s+([^\s'"]+)/;

// First-ever message: points the agent at KV instead of hardcoding anything.
const BOOTSTRAP = [
  'mesh: receiver live.',
  'First: read KV AGENT_STATE key mesh.instructions',
  '(`nats kv get AGENT_STATE mesh.instructions`), register mesh.members.<your-name>, then ack.',
  'Inbox lines arrive as [nats <subject>] — act on your receiver token and work.<W>.all, ignore the rest.',
].join(' ');

export default function (cmd: ModApi) {
  if (SUBJECTS.length === 0) {
    cmd.ui.notify('mesh: no subjects configured, not subscribing');
    return;
  }

  // Idempotent server ensure. Runs once per session, fire-and-forget, before the
  // first subscription attempt. Dial-first: if a server answers, we join it and
  // touch nothing; if not, we boot ours. Two sessions racing both fail the probe
  // and both launch — that is safe because the loser's bind on 4222 fails and it
  // falls through to the second probe, which now succeeds against the winner's
  // server. The nats-server data-dir lock is the backstop: only one server ever
  // owns jsdata. No pidfile, no flock, no refcount — a pidfile is stale after a
  // reboot, and killing by pid risks a reused pid. Never stop the server here:
  // peers may still use it (onSessionEnd kills only this session's sub).
  const ensured = {done: false};
  const ensureServer = async () => {
    if (ensured.done) return;
    ensured.done = true;
    // nats-server takes a bare host in -a; a `host:port` string there is parsed
    // as the HOST name and silently falls back to port 4222. Split instead.
    const {hostname, port} = new URL(NATS_URL);
    const probe = async (): Promise<boolean> => {
      try {
        const r = await cmd.exec({
          command: NATS,
          args: ['-s', NATS_URL, 'pub', '-q', '_mesh.probe', 'ping'],
          signal: AbortSignal.timeout(PROBE_MS),
        }).catch(() =>
          cmd.exec({
            command: NATS_FALLBACK,
            args: ['-s', NATS_URL, 'pub', '-q', '_mesh.probe', 'ping'],
            signal: AbortSignal.timeout(PROBE_MS),
          }),
        );
        return r.code === 0;
      } catch {
        return false;
      }
    };
    if (await probe()) return true;
    try {
      const {mkdirSync} = await import('node:fs');
      mkdirSync(DATA_DIR, {recursive: true});
      const {spawn: spawnDetached} = await import('node:child_process');
      // Detached: outlives this session so peers keep their server.
      const srv = spawnDetached(SERVER_BIN, ['-js', '-sd', DATA_DIR, '-a', hostname, '-p', port], {
        detached: true,
        stdio: 'ignore',
      });
      srv.unref();
      srv.on('error', () => {});
    } catch {
      // Launch failed (binary missing, or the race loser whose bind failed) —
      // fall through to the second probe, which covers the winner's server.
    }
    if (await probe()) return true;
    cmd.ui.notify(`mesh: no server at ${NATS_URL} and could not start one`);
    return false;
  };
  // Only claim "listening" when a server actually answered. Otherwise the
  // status lies and the sub retries forever against nothing.
  void ensureServer().then((up) => {
    if (!up) return;
    launch(NATS, false);
  });

  // State (bounded) vs rendering (pure) split: history/sentHistory is the mesh
  // state, renderTape() is the view. Pipe it out via the mesh_tape tool.
  // tiger: setStatus collapses to ONE line, so OUT+IN share one row here;
  // mesh_tape returns the true two-line view.
  let received = 0;
  let sent = 0;
  const HISTORY_MAX = 20;
  const SENT_MAX = 10;
  const ENTRY_MAX = 24;
  const TAPE_WIDTH = 48;
  const history: string[] = [];
  const sentHistory: string[] = [];

  let buffer = '';
  let pendingSubject: string | undefined;
  let pendingPayload = '';

  const shortEntry = (subject: string, payload: string): string => {
    const sub = subject.split('.').pop() || subject;
    const preview = payload.replace(/\s+/g, ' ').split(' ').slice(0, 4).join(' ');
    return `${sub}: ${preview.length > ENTRY_MAX ? preview.slice(0, ENTRY_MAX) + '…' : preview}`;
  };

  // Pure: state in, string out. No side effects.
  const renderTape = (done: string[], pending: string[], width: number): string => {
    if (!(width >= 20)) width = 20;
    const left = done.join(' :: ');
    const right = pending.join(' :: ');
    const core = right ? `${left} | ${right}` : `${left} |`;
    if (core.length + 8 <= width) return `MESH:[ ${core} ]`;
    const half = Math.floor((width - 12) / 2);
    const l = left.length > half ? '... ' + left.slice(-half) : left;
    const r = right.length > half ? right.slice(0, half) + ' ...' : right;
    return `MESH:[ ${l} | ${r} ]`;
  };

  const pendingEntry = (): string[] => {
    if (pendingSubject === undefined) return [];
    const sub = pendingSubject.split('.').pop() || pendingSubject;
    const preview = pendingPayload.replace(/\s+/g, ' ').trim().split(' ').slice(0, 4).join(' ');
    return [`${sub}: ${preview || '…'}`];
  };

  const renderStatus = () => {
    cmd.ui.setStatus(
      `OUT:${renderTape(sentHistory, [], TAPE_WIDTH)} IN:${renderTape(history, pendingEntry(), TAPE_WIDTH)}`,
    );
  };
  let proc: ReturnType<typeof spawn> | undefined;

  // After a header, accumulate ALL following lines until the first blank line;
  // payload is the accumulated lines joined with '\n', trimmed. Lines before
  // any header (startup banner) are ignored.
  const flush = () => {
    if (pendingSubject === undefined) return;
    const subject = pendingSubject;
    const raw = pendingPayload.trim();
    pendingSubject = undefined;
    pendingPayload = '';
    if (raw === '') return;
    let payload = raw;
    if (payload.length > MAX_PAYLOAD) payload = payload.slice(0, MAX_PAYLOAD) + '…[truncated]';
    received += 1;
    history.push(shortEntry(subject, payload));
    if (history.length > HISTORY_MAX) history.shift();
    cmd.queueMessage({
      content: `[nats ${subject}] ${payload}`,
      deliverAs: DELIVER,
    });
    renderStatus();
  };

  const onData = (chunk: Buffer) => {
    buffer += chunk.toString();
    const lines = buffer.split('\n');
    buffer = lines.pop() ?? '';

    for (const line of lines) {
      const header = HEADER.exec(line.trim());
      if (header) {
        flush(); // a new header ends the previous message
        pendingSubject = header[1];
        pendingPayload = '';
        continue;
      }
      if (pendingSubject === undefined) continue; // banner
      if (line.trim() === '') {
        flush();
        continue;
      }
      pendingPayload += (pendingPayload ? '\n' : '') + line;
    }
  };

  const launch = (bin: string, retried: boolean) => {
    const p = spawn(bin, ['sub', ...SUBJECTS, ...(QUEUE ? ['--queue=' + QUEUE] : [])], {
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    proc = p;
    p.stdout?.on('data', onData);
    p.on('error', (err: Error) => {
      if (!retried && (err as NodeJS.ErrnoException).code === 'ENOENT' && bin !== NATS_FALLBACK) {
        cmd.ui.notify('mesh: nats not on PATH, using fallback');
        launch(NATS_FALLBACK, true);
        return;
      }
      cmd.ui.notify(`mesh: nats sub failed - ${err.message}`);
    });
    p.on('exit', (code: number | null) => {
      cmd.ui.notify(`mesh: nats sub exited (${code})`);
    });
  };
  // ensureServer calls launch after the probe/boot; the direct call below is
  // removed by it. Keep one entry point only.

  // pipeable view: model-callable tool, same tape strings as the footer.
  cmd.addTool({
    schema: {
      name: 'mesh_tape',
      description: 'Render the mesh message tapes: OUT = sent, IN = received left of | with in-flight right.',
      input_schema: {type: 'object', properties: {}, required: []},
    },
    run: async () => {
      const text =
        `OUT:${renderTape(sentHistory, [], TAPE_WIDTH)}\n` +
        `IN:${renderTape(history, pendingEntry(), TAPE_WIDTH)}`;
      return {ok: true, content: [{type: 'text', text}]};
    },
  });

  cmd.hooks({
    onSessionStart: () => {
      cmd.queueMessage({content: BOOTSTRAP, deliverAs: 'follow-up'});
    },
    onSessionEnd: () => {
      proc?.kill();
      cmd.ui.setStatus(null);
    },
    // AAA choice A: ground truth of what I sent = afterToolCall on shell nats pub.
    afterToolCall: async ({toolName, input}) => {
      if (toolName !== 'shell_command') return undefined;
      const cmdStr =
        typeof (input as {command?: unknown}).command === 'string'
          ? (input as {command: string}).command
          : '';
      const args = Array.isArray((input as {args?: unknown}).args)
        ? (input as {args: unknown[]}).args.map(String).join(' ')
        : '';
      const full = `${cmdStr} ${args}`;
      const m = PUB_SUBJECT.exec(full);
      if (!m) return undefined;
      const subject = m[1];
      const rest = full.slice(m.index + m[0].length).trim().replace(/^['"]/, '');
      const previewWords = rest.split(/\s+/).slice(0, 4).join(' ');
      const preview = previewWords ? previewWords.slice(0, ENTRY_MAX) : '…';
      const sub = subject.split('.').pop() || subject;
      sent += 1;
      sentHistory.push(`${sub}: ${preview}`);
      if (sentHistory.length > SENT_MAX) sentHistory.shift();
      renderStatus();
      return undefined;
    },
  });

  cmd.ui.setStatus('mesh: listening');
}
