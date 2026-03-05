/**
 * Web API polyfills for Jest
 *
 * This file is loaded before test files via setupFiles (not setupFilesAfterEnv)
 * so that Web globals are available when jest.mock() hoists are evaluated.
 *
 * We create minimal mocks that are sufficient for Next.js API route tests.
 */

// Headers mock
class MockHeaders {
  constructor(init) {
    this._headers = new Map();
    if (init) {
      if (init instanceof MockHeaders) {
        init._headers.forEach((value, key) => this._headers.set(key, value));
      } else if (Array.isArray(init)) {
        init.forEach(([key, value]) => this._headers.set(key.toLowerCase(), value));
      } else if (typeof init === 'object') {
        Object.entries(init).forEach(([key, value]) => this._headers.set(key.toLowerCase(), value));
      }
    }
  }
  get(name) {
    return this._headers.get(name.toLowerCase()) || null;
  }
  set(name, value) {
    this._headers.set(name.toLowerCase(), value);
  }
  has(name) {
    return this._headers.has(name.toLowerCase());
  }
  delete(name) {
    this._headers.delete(name.toLowerCase());
  }
  forEach(callback) {
    this._headers.forEach((value, key) => callback(value, key, this));
  }
  entries() {
    return this._headers.entries();
  }
  keys() {
    return this._headers.keys();
  }
  values() {
    return this._headers.values();
  }
  [Symbol.iterator]() {
    return this._headers.entries();
  }
}

// Response mock
class MockResponse {
  constructor(body, init = {}) {
    this._body = body;
    this.status = init.status || 200;
    this.statusText = init.statusText || '';
    this.ok = this.status >= 200 && this.status < 300;
    this.headers = new MockHeaders(init.headers);
    this.body = null;
    this.bodyUsed = false;
  }
  async json() {
    this.bodyUsed = true;
    if (typeof this._body === 'string') {
      return JSON.parse(this._body);
    }
    return this._body;
  }
  async text() {
    this.bodyUsed = true;
    if (typeof this._body === 'string') {
      return this._body;
    }
    return JSON.stringify(this._body);
  }
  async arrayBuffer() {
    this.bodyUsed = true;
    const text = await this.text();
    return new TextEncoder().encode(text).buffer;
  }
  async blob() {
    this.bodyUsed = true;
    return new Blob([await this.text()]);
  }
  clone() {
    return new MockResponse(this._body, {
      status: this.status,
      statusText: this.statusText,
      headers: this.headers,
    });
  }
  static json(data, init = {}) {
    return new MockResponse(JSON.stringify(data), {
      ...init,
      headers: {
        'content-type': 'application/json',
        ...(init.headers || {}),
      },
    });
  }
  static redirect(url, status = 302) {
    return new MockResponse(null, {
      status,
      headers: { Location: url },
    });
  }
}

// Request mock
class MockRequest {
  constructor(input, init = {}) {
    if (typeof input === 'string') {
      this.url = input;
    } else if (input instanceof MockRequest) {
      this.url = input.url;
      init = { ...input, ...init };
    } else {
      this.url = input.url || '';
    }
    this.method = (init.method || 'GET').toUpperCase();
    this.headers = new MockHeaders(init.headers);
    this._body = init.body;
    this.body = null;
    this.bodyUsed = false;
    this.cache = init.cache || 'default';
    this.credentials = init.credentials || 'same-origin';
    this.mode = init.mode || 'cors';
    this.redirect = init.redirect || 'follow';
    this.referrer = init.referrer || 'about:client';
  }
  async json() {
    this.bodyUsed = true;
    if (typeof this._body === 'string') {
      return JSON.parse(this._body);
    }
    return this._body;
  }
  async text() {
    this.bodyUsed = true;
    if (typeof this._body === 'string') {
      return this._body;
    }
    return JSON.stringify(this._body);
  }
  async arrayBuffer() {
    this.bodyUsed = true;
    const text = await this.text();
    return new TextEncoder().encode(text).buffer;
  }
  clone() {
    return new MockRequest(this.url, {
      method: this.method,
      headers: this.headers,
      body: this._body,
    });
  }
}

// FormData mock
class MockFormData {
  constructor() {
    this._data = new Map();
  }
  append(name, value) {
    if (!this._data.has(name)) {
      this._data.set(name, []);
    }
    this._data.get(name).push(value);
  }
  delete(name) {
    this._data.delete(name);
  }
  get(name) {
    const values = this._data.get(name);
    return values ? values[0] : null;
  }
  getAll(name) {
    return this._data.get(name) || [];
  }
  has(name) {
    return this._data.has(name);
  }
  set(name, value) {
    this._data.set(name, [value]);
  }
  entries() {
    const entries = [];
    this._data.forEach((values, key) => {
      values.forEach((value) => entries.push([key, value]));
    });
    return entries[Symbol.iterator]();
  }
  keys() {
    return this._data.keys();
  }
  values() {
    const values = [];
    this._data.forEach((vals) => values.push(...vals));
    return values[Symbol.iterator]();
  }
  forEach(callback) {
    this._data.forEach((values, key) => {
      values.forEach((value) => callback(value, key, this));
    });
  }
}

// Set Web globals
global.Request = MockRequest;
global.Response = MockResponse;
global.Headers = MockHeaders;
global.FormData = MockFormData;

// Ensure URL and URLSearchParams are available (Node.js provides these)
if (typeof global.URL === 'undefined') {
  global.URL = URL;
}
if (typeof global.URLSearchParams === 'undefined') {
  global.URLSearchParams = URLSearchParams;
}

// Ensure TextEncoder and TextDecoder are available
if (typeof global.TextEncoder === 'undefined') {
  const { TextEncoder, TextDecoder } = require('util');
  global.TextEncoder = TextEncoder;
  global.TextDecoder = TextDecoder;
}
