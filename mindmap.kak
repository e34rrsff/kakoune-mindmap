declare-option -docstring %{
    The location to look for mindmap notes.
} str mindmap_dir
declare-option -docstring %{
    A shell command which will be executed to generate a new note's file name
    prefix. The default is "date +%%s".
} str mindmap_newnote_namer

evaluate-commands %sh{
    mindmap_dir_marker_filename=".kakmindmap"
    # This will simply check if the editor's initial working directory is under
    # a mindmap dir on startup, better to check with a new buffer hook in the
    # future.
    while [ "$PWD" != "/" ]; do
        if [ -e "$mindmap_dir_marker_filename" ]; then
        # I'm not sure if using global scope is a good idea, but it works for
        # now.
            printf "
                set-option global mindmap_dir '${PWD}'
                set-option global mindmap_newnote_namer 'date +%%s'
            "
            break
        else
        # May want to limit how deep (or high) this can get, but it doesn't
        # cause any issues at this point.
            cd ..
        fi
    done
}

define-command mindmap-note-new -params ..1 -docstring %{
    mindmap-note-new [file name]: Create a new note under %opt{mindmap_dir}.
    Optionally, specify a file name (without the file extension) to override
    %opt{mindmap_newnote_namer}.
} %{ evaluate-commands %sh{
    ext=".adoc"
    namer="${kak_opt_mindmap_newnote_namer}"
    base_dir="${kak_opt_mindmap_dir}"

    if [ -n "$1" ]; then
        new_note_name="$1$ext"
    else
    	new_note_name="$(eval $namer)$ext"
    fi
    new_note_path="$base_dir/$new_note_name"

    if [ -z "$base_dir" ]; then
        printf %s "fail '%opt{mindmap_dir} not set (not in a mindmap directory)'"
    elif ! [ -d "$base_dir" ]; then
        printf "fail '$base_dir doesn't exist'"
    elif [ -e "$new_note_path" ]; then
        printf "fail '$new_note_path already exists'"
    else
        printf "edit '$new_note_path'"
    fi
}}
