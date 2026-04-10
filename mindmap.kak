declare-option str mindmap_dir

declare-option -hidden str mindmap_scripts_path %sh{
    printf "${kak_source%/*}/scripts"
}

declare-option -docstring %{
    A shell command which will be executed to generate a new note's file name
    prefix. The default is "date +%s".
} str mindmap_newnote_namer

define-command -hidden mindmap-detect -params 0 %{
    evaluate-commands %sh{
        mindmap_dir_marker_filename=".kakmindmap"
        current_buf_dir="${kak_buffile%/*}"
        if [ -e "$current_buf_dir/$mindmap_dir_marker_filename" ]; then
            printf "set-option global mindmap_dir \"$current_buf_dir\""
        else
            printf "fail \"$current_buf_dir is not a MindMap directory\""
        fi
}}

define-command mindmap-new-note -params ..1 -docstring %{
    mindmap-note-new [file name]: Create a new note under %opt{mindmap_dir}.
    Optionally, specify a file ID to override %opt{mindmap_newnote_namer}.
} %{ evaluate-commands %sh{
    namer="$kak_opt_mindmap_newnote_namer"
    base_dir="$kak_opt_mindmap_dir"

    if [ -n "$1" ]; then
        new_note_name="$1.adoc"
    else
    	new_note_name="$(eval $namer).adoc"
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
} %{ evaluate-commands -save-regs 'f' %{

    try %{ delete-buffer *mindmap-list* }

    evaluate-commands %sh{
        fifo="$(mktemp -u)"
        mkfifo "$fifo"

        perl_script="$kak_opt_mindmap_scripts_path/list.perl"
        # I'll be honest, I don't yet understand why the fifo file requires
        # these redirects
        (env perl "$perl_script" "$kak_opt_mindmap_dir" > "$fifo") < /dev/null > /dev/null 2>&1 &
        printf "set-register f '%s'" "$fifo"
    }

    edit -fifo %reg{f} -readonly *mindmap-list*
    nop %sh{ rm "$kak_reg_f" }
    set-register 'f'

    map buffer normal <ret> ':mindmap-open<ret>'
}}

define-command -hidden mindmap-open %{
    evaluate-commands %{

        # The regex "^(?S).*/" should match each file ID up to the first
        # occurring slash in the "mindmap-list"; which should never occur in a
        # filename anyway.
        execute-keys 'xs^(?S).*/<ret>'
        evaluate-commands %sh{
            perl_script="$kak_opt_mindmap_scripts_path/open.perl"
            eval set -- "$kak_quoted_selections"
            while [ $# -gt 0 ]; do
                printf "$1\n"
                shift
            done | env perl "$perl_script"
        }
}}

set-option global mindmap_dir %sh{printf "$KAK_MINDMAP_DIR"}
set-option global mindmap_newnote_namer 'date +%s'

# I still don't know if using the global scope in mindmap-dir-detect could be
# bad practice, but the kakrc gets sourced before any window is even up, so
# I couldn't even use the window scope.
hook global BufOpenFile .*\.a(scii)?doc mindmap-detect
hook global BufNewFile .*\.a(scii)?doc mindmap-detect
