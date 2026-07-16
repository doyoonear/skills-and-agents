#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

path = ARGV[0]

if path.nil? || path.strip.empty?
  warn "Usage: validate-skill-frontmatter.rb path/to/SKILL.md"
  exit 2
end

unless File.file?(path)
  warn "ERROR: file not found: #{path}"
  exit 2
end

text = File.read(path)

unless text.start_with?("---\n") || text.start_with?("---\r\n")
  warn "ERROR: #{path} does not start with YAML frontmatter delimiter '---'."
  exit 1
end

parts = text.split(/^---\s*$/, 3)
if parts.length < 3 || parts[1].nil? || parts[1].strip.empty?
  warn "ERROR: #{path} does not contain a complete YAML frontmatter block."
  exit 1
end

begin
  metadata = YAML.safe_load(parts[1], permitted_classes: [], aliases: false)
rescue Psych::SyntaxError => e
  warn "ERROR: invalid YAML frontmatter in #{path}:"
  warn "  #{e.message}"
  exit 1
end

unless metadata.is_a?(Hash)
  warn "ERROR: frontmatter in #{path} must parse to a mapping/object."
  exit 1
end

name = metadata["name"]
description = metadata["description"]

if !name.is_a?(String) || name.strip.empty?
  warn "ERROR: frontmatter in #{path} must include non-empty string field 'name'."
  exit 1
end

if !description.is_a?(String) || description.strip.empty?
  warn "ERROR: frontmatter in #{path} must include non-empty string field 'description'."
  exit 1
end

puts "OK: #{path}"
puts "  name: #{name}"
puts "  description: #{description.length} chars"
