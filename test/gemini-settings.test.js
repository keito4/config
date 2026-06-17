const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readJson(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(repoPath, relativePath), 'utf8'));
}

function hasOwn(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

describe('Gemini CLI settings', () => {
  const settings = readJson('.gemini/settings.json');

  test('should define MCP servers', () => {
    expect(settings).toHaveProperty('mcpServers');
    expect(Object.keys(settings.mcpServers).length).toBeGreaterThan(0);
  });

  test('remote MCP servers should use Gemini CLI supported keys', () => {
    for (const server of Object.values(settings.mcpServers)) {
      if (!hasOwn(server, 'url')) {
        continue;
      }

      expect(server).not.toHaveProperty('transport');
      expect(typeof server.url).toBe('string');
      expect(server.url).toMatch(/^https:\/\//);

      if (hasOwn(server, 'headers')) {
        expect(server.headers).not.toBeNull();
        expect(Array.isArray(server.headers)).toBe(false);
        expect(typeof server.headers).toBe('object');
      }

      for (const key of Object.keys(server)) {
        expect(['url', 'headers', 'timeout', 'trust'].includes(key)).toBe(true);
      }
    }
  });

  test('local MCP servers should define command and args', () => {
    for (const server of Object.values(settings.mcpServers)) {
      if (hasOwn(server, 'url')) {
        continue;
      }

      expect(typeof server.command).toBe('string');
      expect(Array.isArray(server.args)).toBe(true);

      for (const key of Object.keys(server)) {
        expect(['command', 'args', 'env', 'cwd', 'timeout', 'trust'].includes(key)).toBe(true);
      }
    }
  });
});
