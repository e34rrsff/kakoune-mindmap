declare-option -hidden -docstring %{
    path to the `scripts` directory within the `kakoune-mindmap` directory
} str mindmap_scripts_path %sh{
    printf "${kak_source%/*}/scripts"
}

declare-option -docstring %{
    a directory path to where notes are sourced
} str mindmap_dir %sh{
    [ -d "$KAK_MINDMAP_DIR" ] && printf "$KAK_MINDMAP_DIR"
}

declare-option -docstring %{
    `date` command format string that supplies a valid directory path schema
    for new notes
} str mindmap_dir_schema_cmd 'date +%Y/%b/%d'

declare-option -docstring %{
    your preferred file format/extension for your notes
} str mindmap_new_note_fmt 'md'

### Simple commands ###

define-command -docstring %{
    sets the mindmap_dir option if the current buffer is of a file within a
    MindMap directory and also echoes out the path
} mindmap-detect %{
    evaluate-commands %sh{
        mindmap_dir_indicator_filename=".kakmindmap"
        while [ "$PWD" != "/" ]; do
            if [ -e "$PWD/$mindmap_dir_indicator_filename" ] || \
               [ "$PWD" == "$KAK_MINDMAP_DIR" ]; then
                printf "echo \"$PWD\""
                printf "\n"
                printf "set-option window mindmap_dir \"$PWD\""
                exit
            else
                cd ..
            fi
        done
        printf "fail \"$kak_buffile\" is not within a MindMap directory"
}}

hook global BufOpenFile .*\.a(scii)?doc mindmap-detect
hook global BufNewFile .*\.a(scii)?doc mindmap-detect
hook global BufOpenFile .*\.md mindmap-detect
hook global BufNewFile .*\.md mindmap-detect

define-command -docstring %{
    creates a new note
} mindmap-new-note %{ evaluate-commands %sh{
    new_note_dir="$(eval $kak_opt_mindmap_dir_schema_cmd)"
    # hardcoded note ID format
    new_note_filename="$(eval date +%s).$kak_opt_mindmap_new_note_fmt"

    if [ -e "$new_note_dir/$new_note_filename" ]; then
        printf "fail '$new_note_filename already exists'"
    else
        printf "edit $kak_opt_mindmap_dir/$new_note_dir/$new_note_filename"
        printf "\n"
        printf "hook buffer BufWritePre .* mindmap-new-note-mkdir"
    fi
}}

define-command -hidden -docstring %{
    creates the directory for a new note
} mindmap-new-note-mkdir %{ nop %sh{
    mkdir -p "$kak_opt_mindmap_dir/$(eval $kak_opt_mindmap_dir_schema_cmd)"
}}

### Commands relying on external Perl scripts ###

define-command -docstring %{
    creates a buffer that lists all the notes under the current MindMap notes
    directory
} mindmap-list %{ evaluate-commands -save-regs 'f' %{

    try %{ delete-buffer *mindmap-list* }

    evaluate-commands %sh{
        fifo_file="$(mktemp -u)"
        mkfifo "$fifo_file"

        relevant_perl_script="$kak_opt_mindmap_scripts_path/list.perl"
        (env perl "$relevant_perl_script" "$kak_opt_mindmap_dir" \
        > "$fifo_file") < /dev/null > /dev/null 2>&1 &

        printf "set-register f '%s'" "$fifo_file"
    }

    edit -fifo %reg{f} -readonly *mindmap-list*
    nop %sh{ rm "$kak_reg_f" }
    set-register 'f'

    map buffer normal <ret> ':mindmap-open<ret>'
}}

define-command -hidden -docstring %{
    opens selected file entries in a *mindmap-list* buffer
} mindmap-open %{
    evaluate-commands %{
        # relies on the ID being considered a "word" and that it is always in
        # the second column in the buffer
        execute-keys 'ghlw<ret>'
        evaluate-commands %sh{
            relevant_perl_script="$kak_opt_mindmap_scripts_path/open.perl"
            # 82 cols !!
            env perl "$relevant_perl_script" "$kak_opt_mindmap_dir" $kak_selection
        }
}}
