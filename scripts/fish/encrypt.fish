#!/bin/fish

set algorithm_list (openssl list -cipher-algorithms | sed 's/ => .*//' | string lower)
set digest_list (openssl list -digest-algorithms | sed 's/ => .*//' | string lower)

set algorithm aes256
set options -pbkdf2 -a
set encrypt_options -e

function _check_algorithm --no-scope-shadowing
  set -l _algorithm (string lower $_flag_value)
  if not contains "$_algorithm" $algorithm_list
    echo "$_argparse_cmd: Unknown algorithm: $_flag_value"
    exit 1
  end
end

function _check_digest --no-scope-shadowing
  set -l _digest (string lower $_flag_value)
  if not contains "$_digest" $digest_list
    echo "$_argparse_cmd: Unknown digest: $_flag_value"
    exit 1
  end
end

argparse -n 'encrypt' -N1 -X2 'a/algorithm=!_check_algorithm' 'd/digest=!_check_digest' 'b/no-salt' -- $argv; or exit 1
test -n "$_flag_algorithm"; and set algorithm $_flag_algorithm
set -p options "-$algorithm"
test -n "$_flag_digest"; and set -a options -md $_flag_digest
test -n "$_flag_no_salt"; and set -a options -nosalt

set outfile $argv[-1]
test (count $argv) -gt 1; and set infile $argv[1]

function _password_prompt
  set_color green
  echo -n 'password'
  set_color normal
  echo '> '
end

#read -s -p '_password_prompt' password
#set encrypt_options -k "$password"
set encrypt_options -k (read -s -p '_password_prompt')

#echo $options
#echo $encrypt_options
#exit

touch $outfile
chmod +x $outfile
echo "#!/bin/env -S openssl enc $options -d -in" > $outfile

if set -q infile
  set -a encrypt_options -in "$infile"
  openssl enc $options $encrypt_options >> $outfile
else
  fish --private -c "while read line; echo \$line; end | openssl enc $options $encrypt_options >> $outfile"
end
