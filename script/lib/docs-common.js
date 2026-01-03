/**
 * Common utilities for documentation generation
 * @module docs-common
 */

const fs = require('fs');
const path = require('path');

/**
 * Read and parse JSON/YAML files
 * @param {string} filePath - Path to the file
 * @returns {object} Parsed content
 */
function readTemplate(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  if (filePath.endsWith('.json')) {
    return JSON.parse(content);
  }
  // For YAML, return raw content (implement YAML parsing if needed)
  return content;
}

/**
 * Parse TypeScript/JavaScript metadata files
 * @param {string} filePath - Path to the metadata file
 * @returns {object} Extracted metadata
 */
function loadMetadata(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const metadata = {};

  // Extract name from displayName or name property
  const nameMatch = content.match(/(?:displayName|name):\s*['"]([^'"]+)['"]/);
  if (nameMatch) {
    metadata.name = nameMatch[1];
  }

  // Extract description
  const descMatch = content.match(/description:\s*['"]([^'"]+)['"]/);
  if (descMatch) {
    metadata.description = descMatch[1];
  }

  return metadata;
}

/**
 * Count and categorize items based on type
 * @param {Array} items - Array of items to categorize
 * @param {function} typeExtractor - Function to extract type from item
 * @returns {object} Count by type
 */
function extractTypes(items, typeExtractor) {
  const counts = {};
  for (const item of items) {
    const type = typeExtractor(item);
    counts[type] = (counts[type] || 0) + 1;
  }
  return counts;
}

/**
 * Write markdown content to file, creating directories if needed
 * @param {string} content - Markdown content
 * @param {string} filePath - Output file path
 */
function writeMarkdownFile(content, filePath) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(filePath, content, 'utf8');
}

/**
 * Generate markdown table from data
 * @param {Array} headers - Table headers
 * @param {Array<Array>} rows - Table rows
 * @returns {string} Markdown table string
 */
function generateMarkdownTable(headers, rows) {
  const headerRow = `| ${headers.join(' | ')} |`;
  const separator = `| ${headers.map(() => '---').join(' | ')} |`;
  const dataRows = rows.map((row) => `| ${row.join(' | ')} |`).join('\n');
  return `${headerRow}\n${separator}\n${dataRows}`;
}

/**
 * Generate timestamp string
 * @returns {string} ISO timestamp
 */
function generateTimestamp() {
  return new Date().toISOString();
}

module.exports = {
  readTemplate,
  loadMetadata,
  extractTypes,
  writeMarkdownFile,
  generateMarkdownTable,
  generateTimestamp,
};
