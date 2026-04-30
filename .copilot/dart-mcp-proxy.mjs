import { spawn } from 'node:child_process';

const child = spawn('dart', ['mcp-server'], {
  stdio: ['pipe', 'pipe', 'pipe'],
});

process.stdin.on('data', (chunk) => {
  child.stdin.write(chunk);
});
process.stdin.on('end', () => {
  child.stdin.end();
});
child.stderr.on('data', (chunk) => {
  process.stderr.write(chunk);
});

let stdoutBuffer = Buffer.alloc(0);
child.stdout.on('data', (chunk) => {
  stdoutBuffer = Buffer.concat([stdoutBuffer, chunk]);
  stdoutBuffer = flushFrames(stdoutBuffer);
});
child.stdout.on('end', () => {
  if (stdoutBuffer.length > 0) {
    process.stdout.write(stdoutBuffer);
    stdoutBuffer = Buffer.alloc(0);
  }
  process.stdout.end();
});

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code ?? 0);
});

function flushFrames(buffer) {
  let next = buffer;

  while (true) {
    const headerEnd = next.indexOf('\r\n\r\n');
    if (headerEnd === -1) {
      return next;
    }

    const headerBytes = next.subarray(0, headerEnd);
    const headerText = headerBytes.toString('utf8');
    const headers = parseHeaders(headerText);
    const contentLength = Number(headers['content-length']);
    if (!Number.isFinite(contentLength)) {
      process.stdout.write(next);
      return Buffer.alloc(0);
    }

    const frameLength = headerEnd + 4 + contentLength;
    if (next.length < frameLength) {
      return next;
    }

    const bodyBytes = next.subarray(headerEnd + 4, frameLength);
    const bodyText = bodyBytes.toString('utf8');
    processFrame(headers, bodyText);
    next = next.subarray(frameLength);
  }
}

function parseHeaders(headerText) {
  const headers = {};
  for (const line of headerText.split('\r\n')) {
    const separatorIndex = line.indexOf(':');
    if (separatorIndex === -1) {
      continue;
    }
    const key = line.slice(0, separatorIndex).trim().toLowerCase();
    const value = line.slice(separatorIndex + 1).trim();
    headers[key] = value;
  }
  return headers;
}

function processFrame(headers, bodyText) {
  let payload = bodyText;

  try {
    const message = JSON.parse(bodyText);
    const patchedMessage = patchMessage(message);
    payload = JSON.stringify(patchedMessage);
  } catch {
    payload = bodyText;
  }

  const nextHeaders = { ...headers, 'content-length': String(Buffer.byteLength(payload)) };
  const headerLines = Object.entries(nextHeaders).map(([key, value]) => `${formatHeaderName(key)}: ${value}`);
  process.stdout.write(`${headerLines.join('\r\n')}\r\n\r\n${payload}`);
}

function formatHeaderName(key) {
  return key
    .split('-')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join('-');
}

function patchMessage(message) {
  if (!message || typeof message !== 'object') {
    return message;
  }

  const tools = message?.result?.tools;
  if (Array.isArray(tools)) {
    return {
      ...message,
      result: {
        ...message.result,
        tools: tools.map((tool) =>
          tool && typeof tool === 'object' && tool.inputSchema
            ? { ...tool, inputSchema: patchSchema(tool.inputSchema) }
            : tool,
        ),
      },
    };
  }

  return message;
}

function patchSchema(schema) {
  if (!schema || typeof schema !== 'object') {
    return schema;
  }

  if (Array.isArray(schema)) {
    return schema.map((item) => patchSchema(item));
  }

  const next = { ...schema };
  if (next.type === 'object' && next.properties === undefined) {
    next.properties = {};
  }

  if (next.properties && typeof next.properties === 'object' && !Array.isArray(next.properties)) {
    next.properties = Object.fromEntries(
      Object.entries(next.properties).map(([key, value]) => [key, patchSchema(value)]),
    );
  }

  if (next.items !== undefined) {
    next.items = patchSchema(next.items);
  }

  for (const key of ['anyOf', 'allOf', 'oneOf', 'prefixItems']) {
    if (Array.isArray(next[key])) {
      next[key] = next[key].map((item) => patchSchema(item));
    }
  }

  for (const key of ['$defs', 'definitions', 'patternProperties']) {
    if (next[key] && typeof next[key] === 'object' && !Array.isArray(next[key])) {
      next[key] = Object.fromEntries(
        Object.entries(next[key]).map(([childKey, value]) => [childKey, patchSchema(value)]),
      );
    }
  }

  if (next.additionalProperties && typeof next.additionalProperties === 'object') {
    next.additionalProperties = patchSchema(next.additionalProperties);
  }

  if (next.not && typeof next.not === 'object') {
    next.not = patchSchema(next.not);
  }

  return next;
}
