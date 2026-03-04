#!/usr/bin/env ruby
# Corrige mobile_scanner-Swift.h qui ne contient que la branche x86_64,
# en ajoutant une branche arm64 pour le simulateur Apple Silicon.
# Ne fait jamais échouer le build (exit 0 dans tous les cas).
begin
  build_dir = ENV['BUILD_DIR'].to_s
  exit 0 if build_dir.empty?
  header = File.expand_path('mobile_scanner/mobile_scanner.framework/Headers/mobile_scanner-Swift.h', build_dir)
  exit 0 unless File.file?(header)
  content = File.read(header)
  exit 0 if content.include?('defined(__arm64__)')
  x86_marker = '#elif defined(__x86_64__) && __x86_64__'
  idx = content.index(x86_marker)
  exit 0 unless idx
  block_start = idx + x86_marker.length
  else_idx = content.index("\n#else\n#error unsupported Swift architecture", block_start) ||
             content.index("\n#else\n#error unsupported", block_start) ||
             content.index("\n#else\n#error", block_start)
  exit 0 unless else_idx
  block = content[block_start...else_idx]
  arm64_block = "\n#elif defined(__arm64__) && __arm64__\n" + block
  content.insert(block_start, arm64_block)
  File.write(header, content)
rescue => e
  # Ne pas faire échouer le build
  warn "patch_mobile_scanner_swift_header: #{e.message}" if ENV['DEBUG']
end
exit 0
