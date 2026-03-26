declare-option -docstring %{
    The location to look for mindmap notes.
} str mindmap_dir

declare-option -docstring %{
    A shell command which will be executed to generate a new note's file name
    prefix. The default is "date +%%s".
} str mindmap_newnote_namer

declare-option -docstring %{
    File extension for new notes.
} str mindmap_newnote_extension

declare-option -hidden str mindmap_perlscript_path %sh{
    printf "${kak_source%/*}/mindmap.perl"
}

define-command mindmap-detect -params 0 -docstring %{
    Checks if the current file open in the buffer is in a MindMap notes
    directory and sets %opt{mindmap_dir} to the directory it is contained in.
} %{ evaluate-commands %sh{
    mindmap_dir_marker_filename=".kakmindmap"
    if [ -e "$PWD/$mindmap_dir_marker_filename" ]; then
        printf "set-option global mindmap_dir \"$PWD\""
    else
        printf "fail \"$PWD is not a MindMap directory\""
    fi
}}

define-command mindmap-new-note -params ..1 -docstring %{
    mindmap-note-new [file name]: Create a new note under %opt{mindmap_dir}.
    Optionally, specify a file name (without the file extension) to override
    %opt{mindmap_newnote_namer}.
} %{ evaluate-commands %sh{
    ext="$kak_opt_mindmap_newnote_extension"
    namer="$kak_opt_mindmap_newnote_namer"
    base_dir="$kak_opt_mindmap_dir"

    if [ -n "$1" ]; then
        new_note_name="$1$ext"
    else
    	new_note_name="$(eval $namer)$ext"
    fi
    new_note_path="$base_dir/$new_note_name"

    if [ -z "$base_dir" ]; then
        printf %s "fail '%opt{mindmap_dir} not set (not in a mindmap directory)'"
    elif ! [ -d "$base_dir" ]; then
        printf "fail \"$base_dir doesn't exist\""
    elif [ -e "$new_note_path" ]; then
        printf "fail '$new_note_path already exists'"
    else
        printf "edit '$new_note_path'"
    fi
}}

define-command mindmap-list -params 0 -docstring %{
    Open a list of your notes at %opt{mindmap_dir}
} %{ evaluate-commands -save-regs 'm' %{

  try %{ delete-buffer *mindmap-list* }

  evaluate-commands %sh{
    fifo="$(mktemp -u)"
    mkfifo "$fifo"

    perl_script="$kak_opt_mindmap_perlscript_path"
    # I'll be honest, I don't yet understand why the fifo file requires these redirects
    (env perl "$perl_script" "$kak_opt_mindmap_dir" > "$fifo") < /dev/null > /dev/null 2>&1 &
    printf "set-register m '%s'" "$fifo"
  }

  edit -fifo %reg{m} -readonly *mindmap-list*

  nop %sh{ rm "$kak_reg_m" }
  set-register 'm'
}}

set-option global mindmap_dir %sh{printf "$KAK_MINDMAP_DIR"}
set-option global mindmap_newnote_namer 'date +%s'
set-option global mindmap_newnote_extension '.adoc'

# I still don't know if using the global scope in mindmap-dir-detect could be
# bad practice, but the kakrc gets sourced before any window is even up, so
# I couldn't even use the window scope.
hook global BufOpenFile .*\.a(scii)?doc mindmap-detect
hook global BufNewFile .*\.a(scii)?doc mindmap-detect
