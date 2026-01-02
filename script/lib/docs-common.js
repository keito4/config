/**
 * Documentation Generation Utilities
 *
 * Reusable utilities for parsing code metadata and generating Markdown documentation.
 * Based on pattern from keito4-org/n8n_custom_node
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

/**
 * Read and parse template files (JSON/YAML)
 * @param {string} file - File path to read
 * @returns {Object} Parsed template data
 */
function readTemplate(file) {
  const content = fs.readFileSync(file, 'utf8');
  const ext = path.extname(file).toLowerCase();

  if (ext === '.json') {
    return JSON.parse(content);
  } else if (ext === '.yaml' || ext === '.yml') {
    return yaml.load(content);
  }

  throw new Error(`Unsupported file format: ${ext}`);
}

/**
 * Load and parse TypeScript metadata files
 * @param {string} metadataPath - Path to metadata file
 * @returns {Object} Parsed metadata
 */
function loadMetadata(metadataPath) {
  const content = fs.readFileSync(metadataPath, 'utf8');

  // Basic TypeScript/JavaScript parsing
  // Extract exported objects and their properties
  const metadata = {};

  // Simple regex-based extraction (can be enhanced with proper AST parsing)
  const nameMatch = content.match(/name:\s*['"]([^'"]+)['"]/);
  const descMatch = content.match(/description:\s*['"]([^'"]+)['"]/);
  const versionMatch = content.match(/version:\s*['"]?([^'",\s]+)['"]?/);

  if (nameMatch) metadata.name = nameMatch[1];
  if (descMatch) metadata.description = descMatch[1];
  if (versionMatch) metadata.version = versionMatch[1];

  return metadata;
}

/**
 * Extract and count node types from node list
 * @param {Array} nodes - Array of node objects
 * @returns {Object} Node type statistics
 */
function extractNodeTypes(nodes) {
  const types = {};

  nodes.forEach(node => {
    const type = node.type || 'unknown';
    types[type] = (types[type] || 0) + 1;
  });

  return types;
}

/**
 * Write Markdown content to file (creates directory if needed)
 * @param {string} content - Markdown content to write
 * @param {string} outputPath - Output file path
 */
function writeMarkdownFile(content, outputPath) {
  const dir = path.dirname(outputPath);

  // Create directory if it doesn't exist
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(outputPath, content, 'utf8');
}

/**
 * Categorize items based on keyword matching
 * @param {string} itemId - Item identifier
 * @param {Object} metadata - Item metadata
 * @param {Object} categoryKeywords - Category to keywords mapping
 * @returns {string} Matched category or 'Other'
 */
function categorizeItem(itemId, metadata, categoryKeywords) {
  const text = `${itemId} ${metadata.name || ''}`.toLowerCase();

  for (const [category, keywords] of Object.entries(categoryKeywords)) {
    for (const keyword of keywords) {
      if (text.includes(keyword.toLowerCase())) {
        return category;
      }
    }
  }

  return 'Other';
}

/**
 * Generate Markdown table from data
 * @param {Array<string>} headers - Table headers
 * @param {Array<Array<string>>} rows - Table rows
 * @returns {string} Markdown table
 */
function generateMarkdownTable(headers, rows) {
  const headerRow = `| ${headers.join(' | ')} |`;
  const separator = `| ${headers.map(() => '---').join(' | ')} |`;
  const dataRows = rows.map(row => `| ${row.join(' | ')} |`).join('\n');

  return `${headerRow}\n${separator}\n${dataRows}`;
}

/**
 * Get current timestamp in ISO format
 * @returns {string} ISO timestamp
 */
function getTimestamp() {
  return new Date().toISOString();
}

/**
 * Escape Markdown special characters
 * @param {string} text - Text to escape
 * @returns {string} Escaped text
 */
function escapeMarkdown(text) {
  return text
    .replace(/\\/g, '\\\\')
    .replace(/\|/g, '\\|')
    .replace(/\*/g, '\\*')
    .replace(/\_/g, '\\_')
    .replace(/\[/g, '\\[')
    .replace(/\]/g, '\\]')
    .replace(/\(/g, '\\(')
    .replace(/\)/g, '\\)');
}

module.exports = {
  readTemplate,
  loadMetadata,
  extractNodeTypes,
  writeMarkdownFile,
  categorizeItem,
  generateMarkdownTable,
  getTimestamp,
  escapeMarkdown,
};
