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

declare-option -hidden -docstring %{
    command that supplies a valid directory path schema for new notes
} str mindmap_new_note_dir_cmd 'date "+%Y/%b/%d"'

declare-option -hidden -docstring %{
    command that supplies a valid filename schema for new notes
} str mindmap_new_note_filename_cmd 'date "+%I_%M_%S.adoc"'

define-command -docstring %{
    sets %opt{mindmap_dir} if the current buffer is of a file within a mindmap
    directory and also echoes the detected directory
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
        printf "fail \"$kak_buffile\" is not within a mindmap directory"
}}

hook global BufOpenFile .*\.a(scii)?doc mindmap-detect
hook global BufNewFile .*\.a(scii)?doc mindmap-detect

define-command -docstring %{
    creates a new note
} mindmap-new-note %{ evaluate-commands %sh{
    new_note_dir="$(eval $kak_opt_mindmap_new_note_dir_cmd)"
    new_note_filename="$(eval $kak_opt_mindmap_new_note_filename_cmd)"

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
    mkdir -p "$kak_opt_mindmap_dir/$(eval $kak_opt_mindmap_new_note_dir_cmd)"
}}

define-command mindmap-list -docstring %{
    creates a buffer that lists all the notes under the current mindmap notes
    directory
} mindmap-list %{ evaluate-commands -save-regs 'f' %{

    try %{ delete-buffer *mindmap-list* }

    evaluate-commands %sh{
        fifo="$(mktemp -u)"
        mkfifo "$fifo"

        perl_script="$kak_opt_mindmap_scripts_path/list.perl"
        (env perl "$perl_script" "$kak_opt_mindmap_dir" > "$fifo") < /dev/null > /dev/null 2>&1 &
        printf "set-register f '%s'" "$fifo"
    }

    edit -fifo %reg{f} -readonly *mindmap-list*
    nop %sh{ rm "$kak_reg_f" }
    set-register 'f'

    map buffer normal <ret> ':mindmap-open<ret>'
}}

define-command -hidden -docstring %{
    opens selected file entries in a *mindmap-list* buffer
    buffer
} mindmap-open %{
    evaluate-commands %{
        execute-keys 'xs^(?S).*/<ret>'
        evaluate-commands %sh{
            perl_script="$kak_opt_mindmap_scripts_path/open.perl"
            export kak_opt_mindmap_dir
            eval set -- "$kak_quoted_selections"
            while [ $# -gt 0 ]; do
                printf "$1\n"
                shift
            done | env perl "$perl_script"
        }
}}
