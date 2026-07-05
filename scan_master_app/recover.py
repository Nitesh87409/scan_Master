import json
import os

transcript_path = r'C:\Users\NITESH\.gemini\antigravity-ide\brain\2f161c9f-64ae-436c-8ffa-040c011a75c8\.system_generated\logs\transcript_full.jsonl'

targets = [
    'd:\\scan_master\\scan_master_app\\lib\\screens\\home_screen.dart',
    'd:\\scan_master\\scan_master_app\\lib\\screens\\folders_screen.dart',
    'd:\\scan_master\\scan_master_app\\lib\\screens\\folder_view_screen.dart',
    'd:\\scan_master\\scan_master_app\\lib\\screens\\qr_toolkit_screen.dart',
]

file_states = {t: "" for t in targets}

def apply_replace(content, start, end, target_content, replacement_content):
    lines = content.split('\n')
    start_idx = start - 1
    end_idx = end
    
    before = '\n'.join(lines[:start_idx])
    after = '\n'.join(lines[end_idx:])
    
    # We just replace the exact target_content block in the whole file or the specific range
    if target_content in content:
        return content.replace(target_content, replacement_content)
    else:
        # Fallback to lines
        return before + ('\n' if before else '') + replacement_content + ('\n' if after else '') + after

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
        except:
            continue
            
        if 'tool_calls' in data:
            for call in data['tool_calls']:
                name = call.get('name')
                args = call.get('args', {})
                target_file = args.get('TargetFile', '')
                
                # Normalize path separators
                if not target_file: continue
                target_file = target_file.replace('/', '\\')
                
                if target_file.lower() in [t.lower() for t in targets]:
                    target = next(t for t in targets if t.lower() == target_file.lower())
                    if name == 'write_to_file':
                        file_states[target] = args.get('CodeContent', '')
                    elif name == 'replace_file_content':
                        file_states[target] = apply_replace(
                            file_states[target], 
                            args.get('StartLine'), 
                            args.get('EndLine'), 
                            args.get('TargetContent'), 
                            args.get('ReplacementContent')
                        )
                    elif name == 'multi_replace_file_content':
                        chunks = args.get('ReplacementChunks', [])
                        # Apply chunks from bottom to top to avoid line number shifts
                        chunks = sorted(chunks, key=lambda x: x.get('StartLine', 0), reverse=True)
                        for chunk in chunks:
                            file_states[target] = apply_replace(
                                file_states[target],
                                chunk.get('StartLine'),
                                chunk.get('EndLine'),
                                chunk.get('TargetContent'),
                                chunk.get('ReplacementContent')
                            )

for target, content in file_states.items():
    if content:
        # Also replace the 2 seconds with 5 seconds here
        content = content.replace('duration: const Duration(seconds: 2)', 'duration: const Duration(seconds: 5)')
        with open(target, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Recovered {target}")
