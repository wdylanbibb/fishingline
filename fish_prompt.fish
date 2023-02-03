function __fishingline_left --argument-names last_status
  set -l cwd (prompt_pwd)

  set -l host (hostname -s)
  set -l who (whoami)

  if test $fish_key_bindings = fish_vi_key_bindings
    or test "$fish_key_bindings" = "fish_hybrid_key_bindings"
    set_color brblack
    printf "["
    switch $fish_bind_mode
      case default
        set_color --bold red
        printf "\e[2 qN"
      case insert
        set_color --bold green
        printf "\e[6 qI"
      case visual
        set_color --bold yellow
        printf "\e[2 qV"
      case replace_one
        set_color --bold magenta
        printf "\e[4 qR"
    end
    set_color normal
    set_color brblack
    printf "] "
  end

  if test $last_status -ne 0
    set_color --bold magenta
    printf "!"
    set_color normal

    set_color brblack
    printf " "
  end

  set_color --bold brred
  printf "$who"
  set_color normal

  set_color brblack
  printf " @ "

  set_color --bold yellow
  printf "$host"
  set_color normal

  set_color brblack
  printf ": "

  set_color --bold blue
  printf "$cwd"
  set_color normal

  set_color brblack
  printf " "

  # set_color --bold green
  # printf "$(string trim $(fish_git_prompt))"
  set_color normal
end

function __fishingline_git_status
  argparse 'n/count' 'j/joint-char=' 's/staged-char=?' 'c/changed-char=?' 'u/untracked-char=?' 'b/behind-char=?' 'a/ahead-char=?' 'd/diverged-char=?' 't/stashed-char=?' 'x/conflicts-char=?' -- $argv; or return
  set -f git_status (git --no-optional-locks status --porcelain -b 2> /dev/null)

  set -f GIT_STATUS_STAGED 0
  set -f GIT_STATUS_CHANGED 0
  set -f GIT_STATUS_UNTRACKED 0
  set -f GIT_STATUS_BEHIND 0
  set -f GIT_STATUS_AHEAD 0
  set -f GIT_STATUS_DIVERGED 0
  set -f GIT_STATUS_STASHED 0
  set -f GIT_STATUS_CONFLICTS 0

  # Ahead, behind, and diverged information
  set -l INDEX 0
  # set -f tracking_type "asdf"
  for line in (string match -rag '^## [^ ]+ \[(.*)\]' $git_status | string match -rag '(ahead|behind|diverged) ([0-9]+)?')
    set INDEX (math $INDEX+1)
    if test (math $INDEX % 2) -eq 1
      set -f tracking_type $line
    else
      switch $tracking_type
        case ahead
          set GIT_STATUS_AHEAD $line
        case behind
          set GIT_STATUS_BEHIND $line
        case diverged
          set GIT_STATUS_DIVERGED $line
      end
    end
  end

  for line in $git_status
    if string match -rq '^U[ADU]|^[AD]U|^AA|^DD' $line
      set GIT_STATUS_CONFLICTS (math $GIT_STATUS_CONFLICTS + 1)
    else if string match -rq '^\?\?' $line
      set GIT_STATUS_UNTRACKED (math $GIT_STATUS_UNTRACKED + 1)
    else if string match -rq '^[MTADRC] ' $line
      set GIT_STATUS_STAGED (math $GIT_STATUS_STAGED + 1)
    else if string match -rq '^[MTARC][MTD]' $line
      set GIT_STATUS_STAGED (math $GIT_STATUS_STAGED + 1)
      set GIT_STATUS_CHANGED (math $GIT_STATUS_CHANGED + 1)
    else if string match -rq '^ [MTADRC]' $line
      set GIT_STATUS_CHANGED (math $GIT_STATUS_CHANGED + 1)
    end
  end

  set -f git_status_info ''

  if test $GIT_STATUS_AHEAD -ne 0
    set -fa git_status_info (printf "%s%s" (if set -q _flag_count; echo $GIT_STATUS_AHEAD; end) (if set -q _flag_a; echo $_flag_a; else; echo '↑'; end))
  end
  if test $GIT_STATUS_BEHIND -ne 0
    # set -fa git_status_info (printf "%s↓" (if test (count $_flag_count) -ne 0; echo $GIT_STATUS_BEHIND; end))
    set -fa git_status_info (printf "%s%s" (if set -q _flag_count; echo $GIT_STATUS_BEHIND; end) (if set -q _flag_b; echo $_flag_b; else; echo '↓'; end))
  end
  if test $GIT_STATUS_DIVERGED -ne 0
    # set -fa git_status_info (printf "%s↕" (if test (count $_flag_count) -ne 0; echo $GIT_STATUS_DIVERGED; end))
    set -fa git_status_info (printf "%s%s" (if set -q _flag_count; echo $GIT_STATUS_DIVERGED; end) (if set -q _flag_d; echo $_flag_d; else; echo '↕'; end))
  end
  if test $GIT_STATUS_STAGED -ne 0
    # set -fa git_status_info (printf "%s+" (if test (count $_flag_count) -ne 0; echo $GIT_STATUS_STAGED; end))
    set -fa git_status_info (printf "%s%s" (if set -q _flag_count; echo $GIT_STATUS_STAGED; end) (if set -q _flag_s; echo $_flag_s; else; echo '+'; end))
  end
  if test $GIT_STATUS_CHANGED -ne 0
    # set -fa git_status_info (printf "%s!" (if test (count $_flag_count) -ne 0; echo $GIT_STATUS_CHANGED; end))
    set -fa git_status_info (printf "%s%s" (if set -q _flag_count; echo $GIT_STATUS_CHANGED; end) (if set -q _flag_c; echo $_flag_c; else; echo '!'; end))
  end
  if test $GIT_STATUS_UNTRACKED -ne 0
    # set -fa git_status_info (printf "%s?" (if test (count $_flag_count) -ne 0; echo $GIT_STATUS_UNTRACKED; end))
    set -fa git_status_info (printf "%s%s" (if set -q _flag_count; echo $GIT_STATUS_UNTRACKED; end) (if set -q _flag_u; echo $_flag_u; else; echo '?'; end))
  end
  if test $GIT_STATUS_CONFLICTS -ne 0
    # set -fa git_status_info (printf "%s✘" (if test (count $_flag_count) -ne 0; echo $GIT_STATUS_CONFLICTS; end))
    set -fa git_status_info (printf "%s%s" (if set -q _flag_count; echo $GIT_STATUS_CONFLICTS; end) (if set -q _flag_x; echo $_flag_x; else; echo '✘'; end))
  end

  set -f git_status_str ''

  for line in $git_status_info
    if test -n $git_status_str
      set -f git_status_str "$git_status_str$_flag_j"
    end
    set -f git_status_str "$git_status_str$line"
  end

  printf $git_status_str
end

function __fishingline_right --argument-names last_status
  set -l git_branch (git --no-optional-locks symbolic-ref --short HEAD 2> /dev/null)

  set_color --bold cyan
  printf $git_branch
  set_color normal

  set -l git_status (__fishingline_git_status)
 
  if test -n "$git_status"
    set_color brblack
    printf " ["
    set_color --bold magenta

    __fishingline_git_status

    set_color normal
    set_color brblack
    printf "]"
  end
  set_color normal
end

function __fishingline_remove_formatting -d "Removes escape codes in a string to just keep the plain text"
  # matches ANSI escape codes and backslashes that are behind certain special characters, and removes them to only keep the plain text.
  # https://www.regexr.com/7796l
  string escape -n (echo -es "\e[0;3p" "$argv[1]") | string replace -ra '((?:\\\\e\\\\(?:.*?[mqp]|\\(B))+)|(\\\\(?=[\\s\\~\\#\\$\\%\\&\\*\\(\\)\\[\\]\\{\\}\\\\\\|\\;\\\'\\"\\<\\>\\?]))' ''
end

function __fishingline_replace_text -d "Replaces text in a string while maintaining escape codes"
  set -l INDEX 0
  # Remove all background colors from input string (\e[0;3p (NULL character) is added to the beginning of the string to guarentee an escape code at the beginninf)
  # https://www.regexr.com/779c9
  # TODO Create regex that allows for plain text at the beginning of input
  set -l string (string escape -n (echo -es "\e[0;3p" $argv[1]) | string replace -ra '\\\\e\\\\\\[(4[0-9]|10[0-7])m' '')
  # Loops through the input string put through a regex that matches escape codes and plain text, and replace any plain text with the 2nd argument
  for line in (string match -rag '((?:\\\\e\\\\(?:.*?[mqp]|\\(B))+)|(.+?(?=\\\\e|$))' $string)
    if test (math $INDEX % 2) -eq 0
      echo -n "$line"
    else
      # Unescape string before replacing to keep newlines or tabs
      echo -n "$(echo $line | string unescape | string replace -ra '[^\\\\]' $argv[2])"
    end
    set INDEX (math $INDEX + 1)
  end | string unescape
end


function __fishingline_separator_line --argument-names left_text right_text line_length
  printf "%s%s%s\n" (__fishingline_replace_text $left_text _) (set_color brblack; string repeat -n $line_length "_") (__fishingline_replace_text $right_text _)
end

function __fishingline_info_line --argument-names left_text right_text line_length
  printf "%s%s%s\n" $left_text (string repeat -n $line_length " ") $right_text
end

function fish_prompt
  set -f last_status $status

  # Transient is true
  if test "$TRANSIENT" = "1"
    set_color normal
    echo -en '$ '
  else
    set -f left (__fishingline_left "$last_status")

    functions -q "fishingline_left"
    if test $status -eq 0
      set -f left (fishingline_left "$last_status")
    end

    set -f right (__fishingline_right "$last_status")

    functions -q "fishingline_right"
    if test $status -eq 0
      set -f right (fishingline_right "$last_status")
    end
    
    set -f left_prompt_length (string length $(__fishingline_remove_formatting $left))
    set -f right_prompt_length (string length $(__fishingline_remove_formatting $right))
    set -f line_length (math $COLUMNS - 1 - $left_prompt_length - $right_prompt_length)

    functions -q "fishingline_separator_line"
    if test $status -eq 0
      fishingline_separator_line "$left" "$right" $line_length
    else
      __fishingline_separator_line "$left" "$right" $line_length
    end

    functions -q "fishingline_info_line"
    if test $status -eq 0
      fishingline_info_line "$left" "$right" $line_length
    else
      __fishingline_info_line "$left" "$right" $line_length
    end

    set_color normal
    printf "\$ "
  end
end
