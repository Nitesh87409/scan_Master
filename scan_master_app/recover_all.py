import os
import json
import glob

brain_dir = r'C:\Users\NITESH\.gemini\antigravity-ide\brain'
targets = [
    'd:\\scan_master\\scan_master_app\\lib\\screens\\home_screen.dart',
    'd:\\scan_master\\scan_master_app\\lib\\screens\\folders_screen.dart',
    'd:\\scan_master\\scan_master_app\\lib\\screens\\folder_view_screen.dart',
    'd:\\scan_master\\scan_master_app\\lib\\screens\\qr_toolkit_screen.dart',
]

file_states = {t: "" for t in targets}
last_seen = {t: "" for t in targets}

def apply_replace(content, start, end, target_content, replacement_content):
    if not content: return ""
    lines = content.split('\n')
    start_idx = start - 1
    end_idx = end
    
    before = '\n'.join(lines[:start_idx])
    after = '\n'.join(lines[end_idx:])
    
    if target_content in content:
        return content.replace(target_content, replacement_content)
    else:
        return before + ('\n' if before else '') + replacement_content + ('\n' if after else '') + after

# Find all transcripts
transcripts = []
for d in os.listdir(brain_dir):
    d_path = os.path.join(brain_dir, d)
    if os.path.isdir(d_path):
        t_path = os.path.join(d_path, '.system_generated', 'logs', 'transcript_full.jsonl')
        if os.path.exists(t_path):
            transcripts.append(t_path)

# Sort transcripts by modification time (oldest to newest)
transcripts.sort(key=os.path.getmtime)

for t_path in transcripts:
    with open(t_path, 'r', encoding='utf-8', errors='ignore') as f:
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
                    
                    if not target_file: continue
                    target_file = target_file.replace('/', '\\').lower()
                    
                    for t in targets:
                        if t.lower() == target_file:
                            if name == 'write_to_file':
                                file_states[t] = args.get('CodeContent', '')
                            elif name == 'replace_file_content':
                                file_states[t] = apply_replace(
                                    file_states[t], 
                                    args.get('StartLine'), 
                                    args.get('EndLine'), 
                                    args.get('TargetContent'), 
                                    args.get('ReplacementContent')
                                )
                            elif name == 'multi_replace_file_content':
                                chunks = args.get('ReplacementChunks', [])
                                chunks = sorted(chunks, key=lambda x: x.get('StartLine', 0), reverse=True)
                                for chunk in chunks:
                                    file_states[t] = apply_replace(
                                        file_states[t],
                                        chunk.get('StartLine'),
                                        chunk.get('EndLine'),
                                        chunk.get('TargetContent'),
                                        chunk.get('ReplacementContent')
                                    )

for target, content in file_states.items():
    if content:
        # ensure duration is exactly what we want
        content = content.replace('duration: const Duration(seconds: 5)', 'duration: const Duration(seconds: 2)')
        with open(target, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Recovered fully {target}")
    else:
        print(f"Could NOT recover {target}")
