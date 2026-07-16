import re
import glob

# Search in lib/screens/**/*.dart
files = glob.glob('lib/screens/**/*.dart', recursive=True)

# Regex to match ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...), ...))
def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # If file doesn't contain ScaffoldMessenger, skip
    if "ScaffoldMessenger.of" not in content:
        return

    # Let's import snackbar_utils.dart if not present
    # To find relative path to utils:
    depth = filepath.count('/') - 1
    rel_path = '../' * depth + 'core/utils/snackbar_utils.dart'
    import_stmt = f"import '{rel_path}';"
    
    # We will do standard regex or simple string find/replace if possible.
    # Because Dart code can be multiline, let's use a robust regex that balances parentheses,
    # or just use a python script that does character-by-character parsing to find the extent of showSnackBar call.

    out_content = ""
    idx = 0
    modified = False

    while idx < len(content):
        found = content.find("ScaffoldMessenger.of(context).showSnackBar(", idx)
        if found == -1:
            out_content += content[idx:]
            break
        
        # Add up to found
        out_content += content[idx:found]
        
        # We need to find the matching ')' for 'showSnackBar('
        open_parens = 1
        curr = found + len("ScaffoldMessenger.of(context).showSnackBar(")
        start_snack = curr
        
        while open_parens > 0 and curr < len(content):
            if content[curr] == '(':
                open_parens += 1
            elif content[curr] == ')':
                open_parens -= 1
            curr += 1
        
        # content[start_snack:curr-1] is the inside of showSnackBar, which is usually "SnackBar(...)"
        # We also need to consume any trailing semicolon and whitespace
        end_call = curr
        if curr < len(content) and content[curr] == ';':
            end_call += 1
            
        snack_args = content[start_snack:curr-1].strip()
        
        # Now we parse the SnackBar(...) content.
        # It typically looks like:
        # SnackBar(
        #   content: Text('...'),
        #   backgroundColor: AppTheme.successGreen,
        #   ...
        # )
        
        # Let's extract the "content: " part
        content_match = re.search(r'content:\s*(Text\([^)]+\)|const Text\([^)]+\)|Text\([\s\S]*?\)),', snack_args)
        if not content_match:
            # Fallback if there is no trailing comma
            content_match = re.search(r'content:\s*(Text\([^)]+\)|const Text\([^)]+\)|Text\([\s\S]*?\))\s*}?\s*\)$', snack_args)
            if not content_match:
                # Try more general
                content_match = re.search(r'content:\s*(.*?)(?:,|$)', snack_args, flags=re.DOTALL)
                
        text_widget = ""
        if content_match:
            text_widget = content_match.group(1).strip()
            
            # If text_widget is Text('...'), we extract the string inside Text(...)
            # But what if it's Text(yeniArizaId != null ? '...' : '...')?
            # SnackBarUtils.showTopSnackBar expects a String message. So we can just extract whatever is inside Text(...)
            # Or we can modify SnackBarUtils to accept a String, or we can just pass the string expression.
            # Let's just extract what's inside Text( ... )
            inner_text_match = re.search(r'^const Text\((.*)\)$|^Text\((.*)\)$', text_widget, flags=re.DOTALL)
            if inner_text_match:
                message = inner_text_match.group(1) or inner_text_match.group(2)
            else:
                message = text_widget # fallback, might fail compile if it's not a string
        else:
            message = "'İşlem tamamlandı'"
            
        is_error = "false"
        if "errorRed" in snack_args or "accentPink" in snack_args:
            is_error = "true"
            
        replacement = f"SnackBarUtils.showTopSnackBar(context, {message.strip()}, isError: {is_error});"
        
        out_content += replacement
        idx = end_call
        modified = True
        
    if modified:
        # Ensure import is present
        if "snackbar_utils.dart" not in out_content:
            # add import after the last import
            last_import = out_content.rfind("import ")
            if last_import != -1:
                end_import = out_content.find("\n", last_import)
                out_content = out_content[:end_import+1] + import_stmt + "\n" + out_content[end_import+1:]
            else:
                out_content = import_stmt + "\n" + out_content
                
        with open(filepath, 'w') as f:
            f.write(out_content)
        print(f"Updated {filepath}")

for f in files:
    replace_in_file(f)
